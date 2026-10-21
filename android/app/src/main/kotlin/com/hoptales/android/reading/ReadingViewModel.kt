package com.hoptales.android.reading

import android.os.SystemClock
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.speech.SpeechEvent
import com.hoptales.content.Friend
import com.hoptales.content.Profile
import com.hoptales.content.Story
import com.hoptales.content.newestItem
import com.hoptales.content.outfit
import com.hoptales.content.treat
import com.hoptales.content.wearing
import com.hoptales.reading.Reading
import com.hoptales.reading.ReadingState
import com.hoptales.speech.ListenEnd
import com.hoptales.speech.Relisten
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
    private val reading = app.progressStore.load().journey.let { journey ->
        Reading(
            story,
            app.listeningPreferences.strictness,
            bigWords = journey.bigWords(story, app.library),
            treat = journey.treat(story),
        )
    }
    val look: String? = app.progressStore.load().outfit(story.friend, app.wardrobe).firstOrNull()?.id
    private val mutableState = MutableStateFlow(reading.state)
    private val mutableListening = MutableStateFlow<Listening>(Listening.Waiting)
    private var listenJob: Job? = null
    private var supportJob: Job? = null
    private var listeningLocale: Locale? = null
    private var hasCheckedSupport = false
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

            else -> {
                supportJob?.cancel()
                supportJob = viewModelScope.launch {
                    if (!hasCheckedSupport) {
                        listeningLocale = app.listener.listeningLocale(locale)
                        hasCheckedSupport = true
                    }
                    if (!isStarted) return@launch
                    if (listeningLocale == null) {
                        mutableListening.value = Listening.Unsupported
                        return@launch
                    }
                    mutableListening.value = Listening.Active
                    listen()
                    watchSilence()
                }
            }
        }
    }

    fun stop() {
        isStarted = false
        supportJob?.cancel()
        listenJob?.cancel()
        watchJob?.cancel()
        app.readingAudio.deactivate()
    }

    private fun listen() {
        listenJob?.cancel()
        listenJob = viewModelScope.launch {
            while (isActive && !reading.state.isFinished) {
                val biasing = reading.state.sentence?.words?.map { it.text }.orEmpty()
                var end = ListenEnd.FINISHED
                app.listener.listen(biasing, listeningLocale ?: locale).collect { event ->
                    when (event) {
                        is SpeechEvent.Partial -> heard(event.tokens, isFinal = false)
                        is SpeechEvent.Final -> heard(event.tokens, isFinal = true)
                        is SpeechEvent.Level -> Unit
                        is SpeechEvent.Ended -> end = event.reason
                    }
                }
                delay(Relisten.after(end))
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
            if (isStarted && hasPermission && listeningLocale != null) listen()
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

    fun momentDismissed() {
        reading.momentDismissed()
        publish()
    }

    fun tryItOn(friend: Friend) {
        app.progressStore.update { progress ->
            progress.newestItem(friend, app.wardrobe)?.let { progress.wearing(it, friend, app.wardrobe) } ?: progress
        }
    }

    private fun sentenceChanged(before: ReadingState) {
        persist()
        if (reading.state.isFinished) {
            app.progressStore.update { reading.finishing(it, app.library) }
            publish()
        }
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
}
