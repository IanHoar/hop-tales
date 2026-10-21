package com.hoptales.android.reading

import android.os.SystemClock
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.speech.SpeechEvent
import com.hoptales.content.Profile
import com.hoptales.content.Story
import com.hoptales.reading.Reading
import com.hoptales.reading.ReadingState
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.Locale

sealed interface Listening {
    data object Waiting : Listening
    data object NeedsPermission : Listening
    data object Denied : Listening
    data object Unsupported : Listening
    data object Active : Listening
}

class ReadingViewModel(story: Story, private val app: HopTalesApplication) : ViewModel() {
    private val profile = app.profileStore.load() ?: Profile()
    private val locale = Locale.forLanguageTag(profile.accent.tag)
    private val reading = Reading(story, app.listeningPreferences.strictness)
    private val mutableState = MutableStateFlow(reading.state)
    private val mutableListening = MutableStateFlow<Listening>(Listening.Waiting)
    private var listenJob: Job? = null
    private var watchJob: Job? = null
    private var heardAt = SystemClock.elapsedRealtime()
    private var hasPermission = false
    private var isStarted = false

    val soundButtons: Boolean get() = profile.soundButtons
    val state: StateFlow<ReadingState> = mutableState.asStateFlow()
    val listening: StateFlow<Listening> = mutableListening.asStateFlow()

    fun start(permission: Boolean) {
        hasPermission = permission
        isStarted = true
        when {
            !permission ->
                mutableListening.value =
                    if (app.listeningPreferences.hasAskedForMicrophone) Listening.Denied else Listening.NeedsPermission

            !app.listener.isAvailable -> mutableListening.value = Listening.Unsupported

            else -> {
                mutableListening.value = Listening.Active
                app.readingAudio.activate()
                listen()
                watchSilence()
            }
        }
    }

    fun stop() {
        isStarted = false
        listenJob?.cancel()
        watchJob?.cancel()
        app.readingAudio.deactivate()
    }

    private fun listen() {
        listenJob?.cancel()
        listenJob = viewModelScope.launch {
            while (isActive && !reading.state.isFinished) {
                val biasing = reading.state.sentence?.words?.map { it.text }.orEmpty()
                app.listener.listen(biasing, locale).collect { event ->
                    when (event) {
                        is SpeechEvent.Partial -> heard(event.tokens, isFinal = false)
                        is SpeechEvent.Final -> heard(event.tokens, isFinal = true)
                        is SpeechEvent.Level -> Unit
                    }
                }
                delay(RELISTEN_AFTER_END_MILLIS)
            }
            app.readingAudio.deactivate()
        }
    }

    private fun watchSilence() {
        watchJob?.cancel()
        heardAt = SystemClock.elapsedRealtime()
        watchJob = viewModelScope.launch {
            while (isActive) {
                delay(1_000)
                val quiet = SystemClock.elapsedRealtime() - heardAt
                if (quiet >= ReadingState.OFFER_HELP_AFTER_MILLIS && !reading.state.isFinished) help()
            }
        }
    }

    private fun heard(tokens: List<String>, isFinal: Boolean) {
        heardAt = SystemClock.elapsedRealtime()
        val before = reading.state
        reading.heard(tokens, isFinal) ?: return
        publish()
        if (reading.state.sentenceIndex != before.sentenceIndex) sentenceChanged(before)
    }

    fun help() {
        val word = reading.helpRequested() ?: return
        publish()
        listenJob?.cancel()
        viewModelScope.launch {
            app.speaker.speak(word, locale, profile.voiceID)
            delay(ReadingState.SETTLE_AFTER_SPEAKING_MILLIS)
            reading.speechFinished()
            heardAt = SystemClock.elapsedRealtime()
            publish()
            if (isStarted && hasPermission && app.listener.isAvailable) listen()
        }
    }

    fun skipWord() {
        if (reading.state.currentWord == null) return
        val before = reading.state
        reading.skipWord()
        publish()
        if (reading.state.sentenceIndex != before.sentenceIndex) sentenceChanged(before)
    }

    fun backTapped(): Boolean = reading.backTapped().also { publish() }

    fun keepReading() {
        reading.keepReading()
        publish()
    }

    fun readAgain() {
        reading.readAgain()
        publish()
        if (isStarted) start(hasPermission)
    }

    private fun sentenceChanged(before: ReadingState) {
        persist()
        if (reading.state.completionCount > before.completionCount && app.soundPreference.isOn) {
            viewModelScope.launch { app.chord.play() }
        }
    }

    private fun persist() {
        app.progressStore.save(reading.recordedIn(app.progressStore.load()))
    }

    private fun publish() {
        mutableState.value = reading.state
    }

    override fun onCleared() {
        stop()
    }

    private companion object {
        const val RELISTEN_AFTER_END_MILLIS = 150L
    }
}
