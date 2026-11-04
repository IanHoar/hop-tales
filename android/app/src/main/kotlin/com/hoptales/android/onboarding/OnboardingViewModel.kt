package com.hoptales.android.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.speech.SpeechModel
import com.hoptales.onboarding.Authorization
import com.hoptales.onboarding.Onboarding
import com.hoptales.onboarding.OnboardingNext
import com.hoptales.onboarding.OnboardingState
import com.hoptales.onboarding.OnboardingStep
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Locale

class OnboardingViewModel(private val app: HopTalesApplication, hasMicrophone: Boolean) : ViewModel() {
    private val onboarding = Onboarding(
        app.profileStore.loadDraft()?.let(OnboardingState::resuming) ?: OnboardingState(isWelcoming = true),
        Locale.getDefault().country,
    )
    private val mutableState = MutableStateFlow(onboarding.state)

    private val mutableSpeech = MutableStateFlow<SpeechModel?>(null)
    private val mutableSpeechProgress = MutableStateFlow<Int?>(null)
    private var speechJob: Job? = null

    val state: StateFlow<OnboardingState> = mutableState.asStateFlow()
    val speech: StateFlow<SpeechModel?> = mutableSpeech.asStateFlow()
    val speechProgress: StateFlow<Int?> = mutableSpeechProgress.asStateFlow()

    init {
        if (onboarding.state.step.number > OnboardingStep.LISTENING.number) {
            onboarding.authorizationResolved(authorization(hasMicrophone))
            publish()
            if (onboarding.state.authorization == Authorization.AUTHORIZED) checkSpeech()
        }
    }

    fun nameChanged(name: String) = update { nameChanged(name) }

    fun soundButtonsPicked(isOn: Boolean) = update { soundButtonsPicked(isOn) }

    fun backupPicked(isOn: Boolean) = update { backupPicked(isOn) }

    fun backTapped() = update { backTapped() }

    fun microphoneAnswered(granted: Boolean) {
        app.listeningPreferences.hasAskedForMicrophone = true
        update { authorizationResolved(authorization(granted)) }
        if (onboarding.state.authorization == Authorization.AUTHORIZED) checkSpeech()
    }

    fun downloadSpeech() {
        mutableSpeech.value = SpeechModel.DOWNLOADING
        mutableSpeechProgress.value = null
        speechJob?.cancel()
        speechJob = viewModelScope.launch {
            if (app.listener.downloadUntilReady(accent) { mutableSpeechProgress.value = it }) mutableSpeech.value = SpeechModel.READY
        }
    }

    private val accent: Locale get() = Locale.forLanguageTag(onboarding.state.profile(Locale.getDefault().country).accent.tag)

    private fun checkSpeech() {
        speechJob?.cancel()
        speechJob = viewModelScope.launch {
            if (app.vosk.isReady()) {
                mutableSpeech.value = SpeechModel.READY
                return@launch
            }
            val model = app.listener.model(accent)
            mutableSpeech.value = model
            if (model == SpeechModel.DOWNLOADING) downloadSpeech()
        }
    }

    fun primaryTapped(): OnboardingNext {
        val leaving = onboarding.state
        val next = onboarding.primaryTapped()
        if (!leaving.isWelcoming && leaving.step == OnboardingStep.BACKUP && next == OnboardingNext.Advanced) {
            app.backupChoice.isOn = leaving.backup == true
        }
        if (next is OnboardingNext.Finished) {
            app.profileStore.save(next.profile)
            app.progressStore.startJourney(next.profile.startingFriend)
        } else {
            publish()
        }
        return next
    }

    private fun authorization(granted: Boolean) = when {
        !granted -> Authorization.DENIED
        app.listener.isAvailable -> Authorization.AUTHORIZED
        else -> Authorization.UNSUPPORTED
    }

    private fun update(change: Onboarding.() -> Unit) {
        onboarding.change()
        publish()
    }

    private fun publish() {
        mutableState.value = onboarding.state
        app.profileStore.saveDraft(onboarding.state.draft)
    }
}
