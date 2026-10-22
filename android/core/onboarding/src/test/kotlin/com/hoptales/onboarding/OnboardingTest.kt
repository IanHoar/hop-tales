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

        assertEquals(OnboardingStep.BACKUP, onboarding.state.step)
        assertEquals(OnboardingNext.Stay, onboarding.primaryTapped())
        onboarding.backupPicked(false)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertEquals(OnboardingStep.NAME, onboarding.state.step)
        assertEquals(OnboardingNext.Stay, onboarding.primaryTapped())
        onboarding.nameChanged("Maya")
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertEquals(OnboardingStep.LISTENING, onboarding.state.step)
        assertEquals("Allow microphone", onboarding.state.primaryTitle)
        assertEquals(OnboardingNext.RequestMicrophone, onboarding.primaryTapped())
        onboarding.authorizationResolved(Authorization.AUTHORIZED)
        assertEquals("Continue", onboarding.state.primaryTitle)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertEquals(OnboardingStep.AHEAD, onboarding.state.step)
        assertEquals(4, onboarding.state.stepNumber)
        assertEquals(5, onboarding.state.stepCount)
        assertTrue(onboarding.state.primaryEnabled)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertEquals(OnboardingStep.SOUND_BUTTONS, onboarding.state.step)
        onboarding.soundButtonsPicked(true)
        assertEquals("Start reading", onboarding.state.primaryTitle)

        val finished = onboarding.primaryTapped()
        assertEquals(
            OnboardingNext.Finished(Profile("Maya", Friend.BUNNY, Profile.Accent.BRITISH, soundButtons = true)),
            finished,
        )
    }

    @Test
    fun eachStepWaitsForAnAnswer() {
        var state = OnboardingState()
        assertFalse(state.canContinue(OnboardingStep.BACKUP))
        assertTrue(state.copy(backup = false).canContinue(OnboardingStep.BACKUP))
        assertFalse(state.canContinue(OnboardingStep.NAME))
        state = state.copy(childName = "   ")
        assertFalse(state.canContinue(OnboardingStep.NAME))
        state = state.copy(childName = "Maya")
        assertTrue(state.canContinue(OnboardingStep.NAME))
        assertFalse(state.canContinue(OnboardingStep.LISTENING))
        assertTrue(state.canContinue(OnboardingStep.AHEAD))
        assertFalse(state.canContinue(OnboardingStep.SOUND_BUTTONS))
    }

    @Test
    fun listeningCanBeRefusedWithoutBlockingSetUp() {
        val onboarding = Onboarding(OnboardingState(step = OnboardingStep.LISTENING, childName = "Maya"))
        assertEquals(OnboardingNext.RequestMicrophone, onboarding.primaryTapped())
        onboarding.authorizationResolved(Authorization.DENIED)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertEquals(OnboardingStep.AHEAD, onboarding.state.step)
    }

    @Test
    fun aDeviceThatCannotRecogniseSpeechCarriesOn() {
        val onboarding = Onboarding(OnboardingState(step = OnboardingStep.LISTENING, childName = "Maya"))
        onboarding.authorizationResolved(Authorization.UNSUPPORTED)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
    }

    @Test
    fun backReturnsToThePreviousQuestion() {
        val onboarding = Onboarding(OnboardingState(step = OnboardingStep.AHEAD))
        assertTrue(onboarding.backTapped())
        assertEquals(OnboardingStep.LISTENING, onboarding.state.step)
        assertTrue(onboarding.backTapped())
        assertEquals(OnboardingStep.NAME, onboarding.state.step)
        assertTrue(onboarding.backTapped())
        assertEquals(OnboardingStep.BACKUP, onboarding.state.step)
        assertTrue(onboarding.state.isFirstStep)
        assertFalse(onboarding.backTapped())
        assertEquals(OnboardingStep.BACKUP, onboarding.state.step)
    }

    @Test
    fun everyNewReaderStartsWithTheLevelOneFriend() {
        val profile = OnboardingState(childName = "Maya", soundButtons = false).profile("GB")
        assertEquals(Friend.at(1), profile.startingFriend)
        assertEquals(Friend.BUNNY, profile.startingFriend)
    }

    @Test
    fun aLongNameIsCutShort() {
        val onboarding = Onboarding()
        onboarding.nameChanged("Maximilian-Alexander-Bartholomew")
        assertEquals(24, onboarding.state.childName.length)
    }

    @Test
    fun theNameIsTrimmedAndTheAccentFollowsTheRegion() {
        val state = OnboardingState(childName = "  Maya ", soundButtons = false)
        assertEquals(Profile("Maya", Friend.BUNNY, Profile.Accent.AMERICAN), state.profile("US"))
        assertEquals(Profile.Accent.CANADIAN, state.profile(null).accent)
        assertEquals(Profile.Accent.BRITISH, state.copy(accent = Profile.Accent.BRITISH).profile("US").accent)
    }

    @Test
    fun everyAnswerIsKeptAsADraft() {
        val onboarding = Onboarding()
        onboarding.backupPicked(true)
        assertEquals(ProfileDraft(backup = true, step = 1), onboarding.state.draft)
        onboarding.primaryTapped()
        onboarding.nameChanged("Maya")
        assertEquals(ProfileDraft(childName = "Maya", backup = true, step = 2), onboarding.state.draft)
    }

    @Test
    fun reopeningTheAppResumesAtTheLastStep() {
        val draft = ProfileDraft(childName = "Maya", startingFriend = Friend.FROG, step = OnboardingStep.AHEAD.number)
        val state = OnboardingState.resuming(draft)
        assertEquals(OnboardingStep.AHEAD, state.step)
        assertEquals("Maya", state.childName)
        assertEquals(Friend.at(1), state.profile("GB").startingFriend)
        assertEquals(4, state.stepNumber)
        assertEquals(5, state.stepCount)
    }

    @Test
    fun aDraftFromAnUnknownStepStartsAgainAtTheBeginning() {
        assertEquals(OnboardingStep.BACKUP, OnboardingState.resuming(ProfileDraft(childName = "Maya", step = 9)).step)
    }

    @Test
    fun aFullyAnsweredDraftIsComplete() {
        val draft = ProfileDraft(
            childName = "Maya",
            startingFriend = Friend.HARE,
            accent = Profile.Accent.AMERICAN,
            soundButtons = true,
            backup = false,
            step = OnboardingStep.SOUND_BUTTONS.number,
        )
        val state = OnboardingState.resuming(draft)
        assertTrue(state.isComplete)
        assertFalse(OnboardingState.resuming(draft.copy(backup = null)).isComplete)
        assertEquals(Profile("Maya", Friend.BUNNY, Profile.Accent.AMERICAN, soundButtons = true), state.profile("GB"))
        assertFalse(OnboardingState.resuming(draft.copy(soundButtons = null)).isComplete)
        assertFalse(OnboardingState.resuming(draft.copy(step = OnboardingStep.AHEAD.number)).isComplete)
    }
}
