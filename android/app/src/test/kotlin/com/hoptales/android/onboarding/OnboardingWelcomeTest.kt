package com.hoptales.android.onboarding

import com.hoptales.android.HopTalesApplication
import com.hoptales.android.billing.FakePlusSource
import com.hoptales.content.ProfileDraft
import com.hoptales.onboarding.OnboardingNext
import com.hoptales.onboarding.OnboardingStep
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class OnboardingWelcomeTest {
    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication

    @Before
    fun startAfresh() = app.profileStore.erase()

    @After
    fun forget() = app.profileStore.erase()

    private fun model() = OnboardingViewModel(app, hasMicrophone = false, plus = FakePlusSource())

    @Test
    fun aFirstRunOpensOnTheWelcome() {
        assertTrue(model().state.value.isWelcoming)
    }

    @Test
    fun gettingStartedSavesADraftAtTheFirstStep() {
        app.backupChoice.isOn = true
        val model = model()
        assertEquals(OnboardingNext.Advanced, model.primaryTapped())
        assertFalse(model.state.value.isWelcoming)
        assertEquals(OnboardingStep.BACKUP.number, app.profileStore.loadDraft()?.step)
        assertTrue(app.backupChoice.isOn)
    }

    @Test
    fun resumingSkipsTheWelcome() {
        app.profileStore.saveDraft(ProfileDraft(childName = "Maya", step = OnboardingStep.NAME.number))
        val state = model().state.value
        assertFalse(state.isWelcoming)
        assertEquals(OnboardingStep.NAME, state.step)
    }
}
