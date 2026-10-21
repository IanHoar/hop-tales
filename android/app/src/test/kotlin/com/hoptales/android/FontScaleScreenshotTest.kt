package com.hoptales.android

import android.Manifest
import android.provider.Settings
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import com.github.takahirom.roborazzi.RoborazziOptions
import com.github.takahirom.roborazzi.captureRoboImage
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.onboarding.OnboardingActions
import com.hoptales.android.onboarding.OnboardingContent
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.android.settings.SettingsActions
import com.hoptales.android.settings.SettingsContent
import com.hoptales.android.settings.SettingsState
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Profile
import com.hoptales.content.Progress
import com.hoptales.onboarding.OnboardingState
import com.hoptales.onboarding.OnboardingStep
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w412dp-h915dp-xhdpi")
class FontScaleScreenshotTest {
    @get:Rule
    val compose = createComposeRule()

    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication

    @Before
    fun largestText() {
        RuntimeEnvironment.setFontScale(LARGEST)
        app.progressStore.save(Progress())
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
        shadowOf(app).grantPermissions(Manifest.permission.RECORD_AUDIO)
    }

    @Test
    fun home() {
        val progress = Progress(
            stars = 56,
            completedSentences = mapOf("meadow-walk" to 6, "golden-hour" to 3),
            journey = Journey.starting(Friend.HARE),
        )
        compose.setContent {
            HopTalesTheme { HomeScreen(library = app.library, progress = progress, onStory = {}, childName = "Maya", hour = 9) }
        }
        capture("home")
    }

    @Test
    fun homeLongName() {
        val progress = Progress(stars = 12, journey = Journey.starting(Friend.HARE))
        compose.setContent {
            HopTalesTheme {
                HomeScreen(library = app.library, progress = progress, onStory = {}, childName = "Maximiliana-Josephine", hour = 9)
            }
        }
        capture("home-long-name")
    }

    @Test
    fun onboardingName() {
        compose.setContent {
            HopTalesTheme { OnboardingContent(OnboardingState(step = OnboardingStep.NAME, childName = "Maya"), OnboardingActions()) }
        }
        capture("onboarding-name")
    }

    @Test
    @Config(qualifiers = "w412dp-h3300dp-xhdpi")
    fun settings() {
        val profile = Profile("Maya", Friend.HARE, Profile.Accent.CANADIAN, soundButtons = true)
        compose.setContent {
            HopTalesTheme {
                SettingsContent(
                    SettingsState(childName = "Maya", profile = profile, journey = Journey.starting(Friend.HARE)),
                    SettingsActions(),
                )
            }
        }
        capture("settings")
    }

    @Test
    fun storyFinished() {
        val story = app.library.stories(Friend.HARE.level).first()
        compose.setContent { HopTalesTheme { ReadingScreen(story = story, onDone = {}) } }
        compose.waitForIdle()
        val hear = compose.onNodeWithText("Hear “", substring = true)
        while (hear.exists()) {
            hear.performClick()
            compose.waitForIdle()
        }
        capture("story-finished")
    }

    private fun capture(name: String) {
        compose.onRoot().captureRoboImage("src/test/screenshots/font-scale/$name.png", options)
    }

    private fun SemanticsNodeInteraction.exists(): Boolean = runCatching { fetchSemanticsNode() }.isSuccess

    private val options = RoborazziOptions(compareOptions = RoborazziOptions.CompareOptions(changeThreshold = 0.005f))

    private companion object {
        const val LARGEST = 2f
    }
}
