package com.hoptales.onboarding

import com.hoptales.content.Friend
import com.hoptales.content.Profile
import com.hoptales.content.ProfileDraft

enum class OnboardingStep {
    BACKUP,
    NAME,
    LISTENING,
    FRIEND,
    SOUND_BUTTONS,
    ;

    val number: Int get() = ordinal + 1

    companion object {
        fun numbered(number: Int): OnboardingStep? = entries.getOrNull(number - 1)
    }
}

enum class Authorization { AUTHORIZED, DENIED, UNSUPPORTED }

data class OnboardingState(
    val step: OnboardingStep = OnboardingStep.entries.first(),
    val childName: String = "",
    val authorization: Authorization? = null,
    val startingFriend: Friend? = null,
    val accent: Profile.Accent? = null,
    val soundButtons: Boolean? = null,
    val backup: Boolean? = null,
) {
    val stepNumber: Int get() = step.number
    val stepCount: Int get() = OnboardingStep.entries.size
    val isFirstStep: Boolean get() = step == OnboardingStep.entries.first()
    val isLastStep: Boolean get() = step == OnboardingStep.entries.last()
    val needsMicrophone: Boolean get() = step == OnboardingStep.LISTENING && authorization == null

    val primaryTitle: String
        get() = when {
            needsMicrophone -> "Allow microphone"
            isLastStep -> "Start reading"
            else -> "Continue"
        }

    val primaryEnabled: Boolean get() = needsMicrophone || canContinue(step)

    val isComplete: Boolean
        get() = isLastStep && OnboardingStep.entries.filter { it != OnboardingStep.LISTENING }.all(::canContinue)

    val draft: ProfileDraft
        get() = ProfileDraft(
            childName = childName,
            startingFriend = startingFriend,
            accent = accent,
            soundButtons = soundButtons,
            backup = backup,
            step = step.number,
        )

    fun canContinue(from: OnboardingStep): Boolean = when (from) {
        OnboardingStep.BACKUP -> backup != null
        OnboardingStep.NAME -> childName.isNotBlank()
        OnboardingStep.LISTENING -> authorization != null
        OnboardingStep.FRIEND -> startingFriend != null
        OnboardingStep.SOUND_BUTTONS -> soundButtons != null
    }

    fun profile(region: String?): Profile = Profile(
        childName = childName.trim(),
        startingFriend = startingFriend ?: Friend.BUNNY,
        accent = accent ?: Profile.Accent.of(region),
        soundButtons = soundButtons ?: false,
    )

    companion object {
        fun resuming(draft: ProfileDraft) = OnboardingState(
            step = OnboardingStep.numbered(draft.step) ?: OnboardingStep.entries.first(),
            childName = draft.childName,
            startingFriend = draft.startingFriend,
            accent = draft.accent,
            soundButtons = draft.soundButtons,
            backup = draft.backup,
        )
    }
}

sealed interface OnboardingNext {
    data object Stay : OnboardingNext
    data object RequestMicrophone : OnboardingNext
    data object Advanced : OnboardingNext
    data class Finished(val profile: Profile) : OnboardingNext
}

class Onboarding(var state: OnboardingState = OnboardingState(), private val region: String? = null) {
    fun nameChanged(name: String) {
        state = state.copy(childName = Profile.trimmedName(name))
    }

    fun friendPicked(friend: Friend) {
        state = state.copy(startingFriend = friend)
    }

    fun soundButtonsPicked(isOn: Boolean) {
        state = state.copy(soundButtons = isOn)
    }

    fun backupPicked(isOn: Boolean) {
        state = state.copy(backup = isOn)
    }

    fun authorizationResolved(authorization: Authorization) {
        state = state.copy(authorization = authorization)
    }

    fun backTapped(): Boolean {
        val previous = OnboardingStep.numbered(state.step.number - 1) ?: return false
        state = state.copy(step = previous)
        return true
    }

    fun primaryTapped(): OnboardingNext {
        if (state.needsMicrophone) return OnboardingNext.RequestMicrophone
        if (!state.primaryEnabled) return OnboardingNext.Stay
        val next = OnboardingStep.numbered(state.step.number + 1) ?: return OnboardingNext.Finished(state.profile(region))
        state = state.copy(step = next)
        return OnboardingNext.Advanced
    }
}
