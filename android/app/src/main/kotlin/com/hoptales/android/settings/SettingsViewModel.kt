package com.hoptales.android.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.speech.VoiceOption
import com.hoptales.content.Basket
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.PlusStatus
import com.hoptales.content.Profile
import com.hoptales.speech.Strictness
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Locale

data class SettingsState(
    val childName: String = "",
    val profile: Profile = Profile(),
    val strictness: Strictness = Strictness.GENTLE,
    val soundOn: Boolean = true,
    val backupOn: Boolean = false,
    val backupWasOn: Boolean = false,
    val voices: List<VoiceOption> = emptyList(),
    val journey: Journey = Journey(),
    val speechLogOn: Boolean = false,
    val speechLogLines: Int = 0,
    val plusStatus: PlusStatus = PlusStatus.Free,
    val foundNothingToRestore: Boolean = false,
) {
    val readingFriends: List<Friend> get() = Friend.entries.filter { it in journey.met || it in Friend.starters }

    val voiceName: String get() = voices.firstOrNull { it.id == profile.voiceID }?.name ?: "Automatic"
}

class SettingsViewModel(private val app: HopTalesApplication) : ViewModel() {
    private val mutableState = MutableStateFlow(
        (app.profileStore.load() ?: Profile()).let { profile ->
            SettingsState(
                childName = profile.childName,
                profile = profile,
                strictness = app.listeningPreferences.strictness,
                soundOn = app.soundPreference.isOn,
                backupOn = app.backupChoice.isOn,
                backupWasOn = app.backupChoice.wasEverOn,
                journey = app.progressStore.load().journey,
                speechLogOn = app.speechLog.isOn,
                speechLogLines = app.speechLog.entries.size,
                plusStatus = app.plus.status.value,
            )
        },
    )

    val state: StateFlow<SettingsState> = mutableState.asStateFlow()

    init {
        viewModelScope.launch {
            val voices = app.speaker.voices()
            mutableState.update { it.copy(voices = voices) }
        }
        viewModelScope.launch {
            app.plus.status.collect { status -> mutableState.update { it.copy(plusStatus = status) } }
        }
    }

    fun restore() {
        mutableState.update { it.copy(foundNothingToRestore = false) }
        viewModelScope.launch {
            val found = app.plus.restore()
            mutableState.update { it.copy(foundNothingToRestore = !found) }
        }
    }

    fun nameChanged(name: String) = mutableState.update { it.copy(childName = Profile.trimmedName(name)) }

    fun nameSubmitted() = save()

    fun friendPicked(friend: Friend) {
        app.progressStore.update { it.copy(journey = it.journey.grownUpMovedTo(friend)) }
        mutableState.update { it.copy(journey = app.progressStore.load().journey) }
    }

    fun accentPicked(accent: Profile.Accent) = changeProfile { copy(accent = accent) }

    fun themePicked(theme: Profile.Theme) = changeProfile { copy(theme = theme) }

    fun soundButtonsToggled(isOn: Boolean) = changeProfile { copy(soundButtons = isOn) }

    fun voicePicked(id: String?) {
        changeProfile { copy(voiceID = id) }
        hearVoice()
    }

    fun hearVoice() {
        val profile = state.value.profile
        viewModelScope.launch { app.speaker.speak(SAMPLE, Locale.forLanguageTag(profile.accent.tag), profile.voiceID) }
    }

    fun strictnessPicked(strictness: Strictness) {
        app.listeningPreferences.strictness = strictness
        mutableState.update { it.copy(strictness = strictness) }
    }

    fun soundToggled(isOn: Boolean) {
        app.soundPreference.isOn = isOn
        mutableState.update { it.copy(soundOn = isOn) }
    }

    fun backupToggled(isOn: Boolean) {
        app.backupChoice.isOn = isOn
        mutableState.update { it.copy(backupOn = isOn, backupWasOn = app.backupChoice.wasEverOn) }
    }

    fun speechLogToggled(isOn: Boolean) {
        app.speechLog.isOn = isOn
        refreshSpeechLog()
    }

    fun speechLogCleared() {
        app.speechLog.clear()
        refreshSpeechLog()
    }

    private fun refreshSpeechLog() =
        mutableState.update { it.copy(speechLogOn = app.speechLog.isOn, speechLogLines = app.speechLog.entries.size) }

    fun done() = save()

    fun resetOnboarding() = app.profileStore.erase()

    fun resetJourney() {
        app.progressStore.update { it.copy(journey = Journey.starting(state.value.profile.startingFriend), baskets = emptyMap()) }
        mutableState.update { it.copy(journey = app.progressStore.load().journey) }
    }

    fun unlockEverything() {
        app.progressStore.update { progress ->
            val baskets = Friend.entries.associateWith { friend ->
                (progress.baskets[friend] ?: Basket()).copy(filled = app.wardrobe.items(friend).size)
            }
            progress.copy(journey = Journey.everything, baskets = baskets)
        }
        mutableState.update { it.copy(journey = app.progressStore.load().journey) }
    }

    private fun changeProfile(change: Profile.() -> Profile) {
        mutableState.update { it.copy(profile = it.profile.change()) }
        save()
    }

    private fun save() {
        val state = state.value
        val profile = state.profile.copy(childName = state.childName.trim())
        mutableState.update { it.copy(profile = profile) }
        app.profileStore.save(profile)
    }

    companion object {
        const val SAMPLE = "Let's read together!"
    }
}
