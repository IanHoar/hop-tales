package com.hoptales.onboarding

import com.hoptales.content.Friend
import com.hoptales.content.Profile
import com.hoptales.content.ProfileDraft
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OnboardingTest {
    @Test
    fun theGrownUpWalksThroughEveryStep() {
        val onboarding = Onboarding(region = "GB")

        assertEquals(OnboardingNext.Stay, onboarding.primaryTapped())
        onboarding.nameChanged("Maya")
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertEquals(OnboardingStep.LISTENING, onboarding.state.step)
        assertEquals("Allow microphone", onboarding.state.primaryTitle)
        assertEquals(OnboardingNext.RequestMicrophone, onboarding.primaryTapped())
        onboarding.authorizationResolved(Authorization.AUTHORIZED)
        assertEquals("Continue", onboarding.state.primaryTitle)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertEquals(OnboardingStep.FRIEND, onboarding.state.step)
        assertEquals(OnboardingNext.Stay, onboarding.primaryTapped())
        onboarding.friendPicked(Friend.FROG)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertEquals(OnboardingStep.SOUND_BUTTONS, onboarding.state.step)
        onboarding.soundButtonsPicked(true)
        assertEquals("Start reading", onboarding.state.primaryTitle)

        val finished = onboarding.primaryTapped()
        assertEquals(
            OnboardingNext.Finished(Profile("Maya", Friend.FROG, Profile.Accent.BRITISH, soundButtons = true)),
            finished,
        )
    }

    @Test
    fun eachStepWaitsForAnAnswer() {
        var state = OnboardingState()
        assertFalse(state.canContinue(OnboardingStep.NAME))
        state = state.copy(childName = "   ")
        assertFalse(state.canContinue(OnboardingStep.NAME))
        state = state.copy(childName = "Maya")
        assertTrue(state.canContinue(OnboardingStep.NAME))
        assertFalse(state.canContinue(OnboardingStep.LISTENING))
        assertFalse(state.canContinue(OnboardingStep.FRIEND))
        assertFalse(state.canContinue(OnboardingStep.SOUND_BUTTONS))
    }

    @Test
    fun listeningCanBeRefusedWithoutBlockingSetUp() {
        val onboarding = Onboarding(OnboardingState(step = OnboardingStep.LISTENING, childName = "Maya"))
        assertEquals(OnboardingNext.RequestMicrophone, onboarding.primaryTapped())
        onboarding.authorizationResolved(Authorization.DENIED)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertEquals(OnboardingStep.FRIEND, onboarding.state.step)
    }

    @Test
    fun aDeviceThatCannotRecogniseSpeechCarriesOn() {
        val onboarding = Onboarding(OnboardingState(step = OnboardingStep.LISTENING, childName = "Maya"))
        onboarding.authorizationResolved(Authorization.UNSUPPORTED)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
    }

    @Test
    fun backReturnsToThePreviousQuestion() {
        val onboarding = Onboarding(OnboardingState(step = OnboardingStep.FRIEND))
        assertTrue(onboarding.backTapped())
        assertEquals(OnboardingStep.LISTENING, onboarding.state.step)
        assertTrue(onboarding.backTapped())
        assertEquals(OnboardingStep.NAME, onboarding.state.step)
        assertTrue(onboarding.state.isFirstStep)
        assertFalse(onboarding.backTapped())
        assertEquals(OnboardingStep.NAME, onboarding.state.step)
    }

    @Test
    fun aLongNameIsCutShort() {
        val onboarding = Onboarding()
        onboarding.nameChanged("Maximilian-Alexander-Bartholomew")
        assertEquals(24, onboarding.state.childName.length)
    }

    @Test
    fun theNameIsTrimmedAndTheAccentFollowsTheRegion() {
        val state = OnboardingState(childName = "  Maya ", startingFriend = Friend.HARE, soundButtons = false)
        assertEquals(Profile("Maya", Friend.HARE, Profile.Accent.AMERICAN), state.profile("US"))
        assertEquals(Profile.Accent.CANADIAN, state.profile(null).accent)
        assertEquals(Profile.Accent.BRITISH, state.copy(accent = Profile.Accent.BRITISH).profile("US").accent)
    }

    @Test
    fun everyAnswerIsKeptAsADraft() {
        val onboarding = Onboarding()
        onboarding.nameChanged("Maya")
        assertEquals(ProfileDraft(childName = "Maya", step = 1), onboarding.state.draft)
    }

    @Test
    fun reopeningTheAppResumesAtTheLastStep() {
        val draft = ProfileDraft(childName = "Maya", startingFriend = Friend.FROG, step = OnboardingStep.FRIEND.number)
        val state = OnboardingState.resuming(draft)
        assertEquals(OnboardingStep.FRIEND, state.step)
        assertEquals("Maya", state.childName)
        assertEquals(Friend.FROG, state.startingFriend)
        assertEquals(3, state.stepNumber)
        assertEquals(4, state.stepCount)
    }

    @Test
    fun aDraftFromAnUnknownStepStartsAgainAtTheName() {
        assertEquals(OnboardingStep.NAME, OnboardingState.resuming(ProfileDraft(childName = "Maya", step = 9)).step)
    }

    @Test
    fun aFullyAnsweredDraftIsComplete() {
        val draft = ProfileDraft(
            childName = "Maya",
            startingFriend = Friend.HARE,
            accent = Profile.Accent.AMERICAN,
            soundButtons = true,
            step = OnboardingStep.SOUND_BUTTONS.number,
        )
        val state = OnboardingState.resuming(draft)
        assertTrue(state.isComplete)
        assertEquals(Profile("Maya", Friend.HARE, Profile.Accent.AMERICAN, soundButtons = true), state.profile("GB"))
        assertFalse(OnboardingState.resuming(draft.copy(soundButtons = null)).isComplete)
        assertFalse(OnboardingState.resuming(draft.copy(step = OnboardingStep.FRIEND.number)).isComplete)
    }
}
