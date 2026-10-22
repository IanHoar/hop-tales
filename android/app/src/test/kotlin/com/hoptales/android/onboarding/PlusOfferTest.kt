package com.hoptales.android.onboarding

import android.provider.Settings
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import com.hoptales.android.BuildConfig
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.billing.FakePlusSource
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.settings.ParentGateState
import com.hoptales.content.ProfileDraft
import com.hoptales.onboarding.OnboardingNext
import com.hoptales.onboarding.OnboardingStep
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w412dp-h915dp-xhdpi")
class PlusOfferTest {
    @get:Rule
    val compose = createComposeRule()

    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication
    private var done = 0

    @Before
    fun answerEveryStep() {
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
        app.profileStore.erase()
        app.profileStore.saveDraft(
            ProfileDraft(childName = "Maya", soundButtons = false, backup = false, step = OnboardingStep.SOUND_BUTTONS.number),
        )
    }

    @After
    fun forget() = app.profileStore.erase()

    private fun finish(isPlus: Boolean = false, locksStories: Boolean = true): OnboardingViewModel {
        val model = OnboardingViewModel(app, hasMicrophone = false, plus = FakePlusSource(isPlus = isPlus), locksStories = locksStories)
        assertTrue(model.primaryTapped() is OnboardingNext.Finished)
        return model
    }

    @Test
    fun theLastStepOffersPlusAndRemembersIt() {
        val model = finish()
        assertTrue(model.offersPlus)
        assertEquals(true, app.profileStore.load()?.plusOffered)
        assertEquals("Maya", app.profileStore.load()?.childName)
    }

    @Test
    fun aReaderWhoIsAlreadyPlusIsNotOffered() {
        assertFalse(finish(isPlus = true).offersPlus)
        assertEquals(false, app.profileStore.load()?.plusOffered)
    }

    @Test
    fun theReleaseSwitchSkipsTheOffer() {
        assertFalse(finish(locksStories = false).offersPlus)
        assertEquals(false, app.profileStore.load()?.plusOffered)
    }

    @Test
    fun theOfferFollowsTheReleaseSwitch() {
        val model = OnboardingViewModel(app, hasMicrophone = false, plus = FakePlusSource())
        assertTrue(model.primaryTapped() is OnboardingNext.Finished)
        assertEquals(BuildConfig.PLUS_LOCKS_STORIES, model.offersPlus)
    }

    @Test
    fun resettingOnboardingOffersPlusAgain() {
        finish()
        app.profileStore.erase()
        app.profileStore.saveDraft(
            ProfileDraft(childName = "Maya", soundButtons = false, backup = false, step = OnboardingStep.SOUND_BUTTONS.number),
        )
        assertTrue(finish().offersPlus)
    }

    private fun show(step: PlusOfferStep = PlusOfferStep.GATE, plus: FakePlusSource = FakePlusSource()) {
        compose.setContent {
            HopTalesTheme {
                PlusOfferScreen(plus, onDone = { done += 1 }, step = step, gate = ParentGateState(seed = 1), live = false)
            }
        }
    }

    @Test
    fun closingTheGateStartsOnHome() {
        show()
        compose.onNodeWithText("Close").performClick()
        assertEquals(1, done)
    }

    @Test
    fun passingTheGateOpensTheOnboardingPaywall() {
        show()
        compose.onNodeWithContentDescription("1").performScrollTo().performClick()
        compose.onNodeWithContentDescription("5").performScrollTo().performClick()
        compose.onNodeWithContentDescription("Check answer").performScrollTo().performClick()
        compose.onNodeWithText("Try Level 1 free").performScrollTo().assertIsDisplayed()
        assertEquals(0, done)
    }

    @Test
    fun tryLevelOneFreeStartsOnHome() {
        show(PlusOfferStep.PAYWALL)
        compose.onNodeWithText("Try Level 1 free").performScrollTo().performClick()
        assertEquals(1, done)
    }

    @Test
    fun closingThePaywallStartsOnHome() {
        show(PlusOfferStep.PAYWALL)
        compose.onNodeWithText("Close").performClick()
        assertEquals(1, done)
    }

    @Test
    fun buyingStartsOnHomeAsPlus() {
        val plus = FakePlusSource()
        show(PlusOfferStep.PAYWALL, plus)
        compose.onNodeWithContentDescription("Yearly", substring = true).performClick()
        compose.waitForIdle()
        assertTrue(plus.isPlus.value)
        assertEquals(1, done)
    }
}
