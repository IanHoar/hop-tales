package com.hoptales.android.onboarding

import androidx.lifecycle.ViewModel
import com.hoptales.android.HopTalesApplication
import com.hoptales.content.Friend
import com.hoptales.onboarding.Authorization
import com.hoptales.onboarding.Onboarding
import com.hoptales.onboarding.OnboardingNext
import com.hoptales.onboarding.OnboardingState
import com.hoptales.onboarding.OnboardingStep
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Locale

class OnboardingViewModel(private val app: HopTalesApplication, hasMicrophone: Boolean) : ViewModel() {
    private val onboarding = Onboarding(
        app.profileStore.loadDraft()?.let(OnboardingState::resuming) ?: OnboardingState(),
        Locale.getDefault().country,
    )
    private val mutableState = MutableStateFlow(onboarding.state)

    val state: StateFlow<OnboardingState> = mutableState.asStateFlow()

    init {
        if (onboarding.state.step.number > OnboardingStep.LISTENING.number) {
            onboarding.authorizationResolved(authorization(hasMicrophone))
            publish()
        }
    }

    fun nameChanged(name: String) = update { nameChanged(name) }

    fun friendPicked(friend: Friend) = update { friendPicked(friend) }

    fun soundButtonsPicked(isOn: Boolean) = update { soundButtonsPicked(isOn) }

    fun backTapped() = update { backTapped() }

    fun microphoneAnswered(granted: Boolean) {
        app.listeningPreferences.hasAskedForMicrophone = true
        update { authorizationResolved(authorization(granted)) }
    }

    fun primaryTapped(): OnboardingNext {
        val next = onboarding.primaryTapped()
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
