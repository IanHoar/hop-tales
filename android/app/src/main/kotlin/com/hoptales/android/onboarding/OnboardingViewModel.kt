package com.hoptales.android.onboarding

import androidx.lifecycle.ViewModel
import com.hoptales.android.BuildConfig
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.billing.PlusSource
import com.hoptales.content.Plus
import com.hoptales.onboarding.Authorization
import com.hoptales.onboarding.Onboarding
import com.hoptales.onboarding.OnboardingNext
import com.hoptales.onboarding.OnboardingState
import com.hoptales.onboarding.OnboardingStep
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Locale

class OnboardingViewModel(
    private val app: HopTalesApplication,
    hasMicrophone: Boolean,
    private val plus: PlusSource = app.plus,
    private val locksStories: Boolean = BuildConfig.PLUS_LOCKS_STORIES,
) : ViewModel() {
    private val onboarding = Onboarding(
        app.profileStore.loadDraft()?.let(OnboardingState::resuming) ?: OnboardingState(isWelcoming = true),
        Locale.getDefault().country,
    )
    private val mutableState = MutableStateFlow(onboarding.state)

    val state: StateFlow<OnboardingState> = mutableState.asStateFlow()

    var offersPlus = false
        private set

    init {
        if (onboarding.state.step.number > OnboardingStep.LISTENING.number) {
            onboarding.authorizationResolved(authorization(hasMicrophone))
            publish()
        }
    }

    fun nameChanged(name: String) = update { nameChanged(name) }

    fun soundButtonsPicked(isOn: Boolean) = update { soundButtonsPicked(isOn) }

    fun backupPicked(isOn: Boolean) = update { backupPicked(isOn) }

    fun backTapped() = update { backTapped() }

    fun microphoneAnswered(granted: Boolean) {
        app.listeningPreferences.hasAskedForMicrophone = true
        update { authorizationResolved(authorization(granted)) }
    }

    fun primaryTapped(): OnboardingNext {
        val leaving = onboarding.state
        val next = onboarding.primaryTapped()
        if (!leaving.isWelcoming && leaving.step == OnboardingStep.BACKUP && next == OnboardingNext.Advanced) {
            app.backupChoice.isOn = leaving.backup == true
        }
        if (next is OnboardingNext.Finished) {
            offersPlus = Plus.offersAtOnboarding(next.profile, plus.isPlus.value, locksStories)
            app.profileStore.save(next.profile.copy(plusOffered = offersPlus))
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
