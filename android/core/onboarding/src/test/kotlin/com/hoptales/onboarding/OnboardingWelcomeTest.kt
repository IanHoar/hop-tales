package com.hoptales.onboarding

import com.hoptales.content.ProfileDraft
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OnboardingWelcomeTest {
    @Test
    fun theWelcomeComesBeforeTheFirstStep() {
        val onboarding = Onboarding(OnboardingState(isWelcoming = true))
        assertEquals("Get started", onboarding.state.primaryTitle)
        assertTrue(onboarding.state.primaryEnabled)
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertFalse(onboarding.state.isWelcoming)
        assertEquals(OnboardingStep.BACKUP, onboarding.state.step)
        assertEquals(1, onboarding.state.stepNumber)
        assertFalse(onboarding.state.primaryEnabled)
    }

    @Test
    fun backFromTheFirstStepReturnsToTheWelcome() {
        val onboarding = Onboarding()
        assertTrue(onboarding.backTapped())
        assertTrue(onboarding.state.isWelcoming)
        assertFalse(onboarding.backTapped())
        assertEquals(OnboardingNext.Advanced, onboarding.primaryTapped())
        assertFalse(onboarding.state.isWelcoming)
    }

    @Test
    fun resumingSkipsTheWelcome() {
        val state = OnboardingState.resuming(ProfileDraft(childName = "Maya", step = 2))
        assertFalse(state.isWelcoming)
        assertEquals(OnboardingStep.NAME, state.step)
    }

    @Test
    fun gettingStartedKeepsADraftAtTheFirstStep() {
        val onboarding = Onboarding(OnboardingState(isWelcoming = true))
        onboarding.primaryTapped()
        assertEquals(OnboardingStep.BACKUP.number, onboarding.state.draft.step)
    }
}
