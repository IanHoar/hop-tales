package com.hoptales.android.onboarding

import android.provider.Settings
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.content.ProfileDraft
import com.hoptales.onboarding.OnboardingNext
import com.hoptales.onboarding.OnboardingStep
import org.junit.After
import org.junit.Assert.assertEquals
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
class FinishingSetUpTest {
    @get:Rule
    val compose = createComposeRule()

    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication

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

    @Test
    fun finishingSetUpSavesTheProfileWithoutOfferingPlus() {
        val model = OnboardingViewModel(app, hasMicrophone = false)
        assertTrue(model.primaryTapped() is OnboardingNext.Finished)
        assertEquals("Maya", app.profileStore.load()?.childName)
        assertEquals(false, app.profileStore.load()?.plusOffered)
    }

    @Test
    fun finishingSetUpGoesStraightToTheStories() {
        var finished = 0
        compose.setContent {
            HopTalesTheme { OnboardingScreen(key = "finishing") { finished += 1 } }
        }
        compose.onNodeWithText("Start reading").performClick()
        compose.waitForIdle()
        assertEquals(1, finished)
        compose.onNodeWithText("For grown-ups").assertDoesNotExist()
        compose.onNodeWithText("Hop Tales Plus").assertDoesNotExist()
        assertEquals(false, app.profileStore.load()?.plusOffered)
    }
}
