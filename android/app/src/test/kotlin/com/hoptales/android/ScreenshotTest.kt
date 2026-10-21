package com.hoptales.android

import android.Manifest
import android.provider.Settings
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import com.github.takahirom.roborazzi.ExperimentalRoborazziApi
import com.github.takahirom.roborazzi.RoborazziOptions
import com.github.takahirom.roborazzi.captureRoboImage
import com.github.takahirom.roborazzi.captureScreenRoboImage
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.onboarding.OnboardingActions
import com.hoptales.android.onboarding.OnboardingContent
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.android.settings.SettingsActions
import com.hoptales.android.settings.SettingsContent
import com.hoptales.android.settings.SettingsState
import com.hoptales.content.Friend
import com.hoptales.content.Profile
import com.hoptales.content.Progress
import com.hoptales.content.Story
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
class ScreenshotTest {
    @get:Rule
    val compose = createComposeRule()

    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication
    private val story get() = app.library.stories(Friend.HARE.level).first()

    @Before
    fun freezeMotion() {
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
        shadowOf(app).grantPermissions(Manifest.permission.RECORD_AUDIO)
    }

    @Test fun homeLight() = home(dark = false)

    @Test fun homeDark() = home(dark = true)

    @Test fun readingLight() = reading(dark = false)

    @Test fun readingDark() = reading(dark = true)

    @Test fun propLight() = moment("prop", "golden-hour", sentence = 3, word = 2, dark = false)

    @Test fun propDark() = moment("prop", "golden-hour", sentence = 3, word = 2, dark = true)

    @Test fun companionLight() = moment("companion", "meadow-walk", sentence = 3, word = 4, dark = false)

    @Test fun companionDark() = moment("companion", "meadow-walk", sentence = 3, word = 4, dark = true)

    @Test fun thoughtLight() = moment("thought", "big-nap", sentence = 2, word = 0, dark = false)

    @Test fun thoughtDark() = moment("thought", "big-nap", sentence = 2, word = 0, dark = true)

    @Test fun soundButtonsMeadowWalk() = moment("sound-buttons-meadow-walk", "meadow-walk", sentence = 0, word = 1, soundButtons = true)

    @Test fun soundButtonsGoldenHour() = moment("sound-buttons-golden-hour", "golden-hour", sentence = 3, word = 1, soundButtons = true)

    @Test fun soundButtonsOffGoldenHour() = moment("sound-buttons-off-golden-hour", "golden-hour", sentence = 3, word = 1)

    @Test fun soundButtonsStormOnTheHill() =
        moment("sound-buttons-storm-on-the-hill", "storm-on-the-hill", sentence = 3, word = 2, soundButtons = true)

    @Test fun storyFinishedLight() = storyFinished(dark = false)

    @Test fun storyFinishedDark() = storyFinished(dark = true)

    @Test fun stopReadingLight() = stopReading(dark = false)

    @Test fun stopReadingDark() = stopReading(dark = true)

    @Test fun askToListenLight() = askToListen(dark = false)

    @Test fun askToListenDark() = askToListen(dark = true)

    @Test fun listeningUnavailableLight() = listeningUnavailable(dark = false)

    @Test fun listeningUnavailableDark() = listeningUnavailable(dark = true)

    @Test fun onboardingNameLight() = onboarding(OnboardingStep.NAME, dark = false)

    @Test fun onboardingNameDark() = onboarding(OnboardingStep.NAME, dark = true)

    @Test fun onboardingListeningLight() = onboarding(OnboardingStep.LISTENING, dark = false)

    @Test fun onboardingListeningDark() = onboarding(OnboardingStep.LISTENING, dark = true)

    @Test fun onboardingFriendLight() = onboarding(OnboardingStep.FRIEND, dark = false)

    @Test fun onboardingFriendDark() = onboarding(OnboardingStep.FRIEND, dark = true)

    @Test fun onboardingSoundButtonsLight() = onboarding(OnboardingStep.SOUND_BUTTONS, dark = false)

    @Test fun onboardingSoundButtonsDark() = onboarding(OnboardingStep.SOUND_BUTTONS, dark = true)

    @Test
    @Config(qualifiers = "w412dp-h1700dp-xhdpi")
    fun settingsLight() = settings(dark = false)

    @Test
    @Config(qualifiers = "w412dp-h1700dp-xhdpi")
    fun settingsDark() = settings(dark = true)

    private fun onboarding(step: OnboardingStep, dark: Boolean) {
        val state = OnboardingState(
            step = step,
            childName = "Maya",
            startingFriend = Friend.HARE.takeIf { step >= OnboardingStep.FRIEND },
            soundButtons = true.takeIf { step >= OnboardingStep.SOUND_BUTTONS },
        )
        compose.setContent {
            HopTalesTheme(dark = dark) { OnboardingContent(state, OnboardingActions()) }
        }
        compose.onRoot().captureRoboImage(path("onboarding-${step.name.lowercase().replace('_', '-')}", dark), options)
    }

    private fun settings(dark: Boolean) {
        val profile = Profile("Maya", Friend.HARE, Profile.Accent.CANADIAN, soundButtons = true)
        compose.setContent {
            HopTalesTheme(dark = dark) { SettingsContent(SettingsState(childName = "Maya", profile = profile), SettingsActions()) }
        }
        compose.onRoot().captureRoboImage(path("settings", dark), options)
    }

    private fun home(dark: Boolean) {
        val progress = Progress(stars = 12, completedSentences = mapOf(story.id to story.sentences.size))
        compose.setContent {
            HopTalesTheme(dark = dark) {
                HomeScreen(library = app.library, progress = progress, onStory = {}, childName = "Maya", hour = 9)
            }
        }
        compose.onRoot().captureRoboImage(path("home", dark), options)
    }

    private fun reading(dark: Boolean) {
        showReading(dark)
        compose.onRoot().captureRoboImage(path("reading", dark), options)
    }

    private fun moment(name: String, id: String, sentence: Int, word: Int, dark: Boolean = false, soundButtons: Boolean = false) {
        val story = app.library[id]!!
        if (soundButtons) app.profileStore.save(Profile("Maya", soundButtons = true))
        showReading(dark, story)
        val words = story.sentences.take(sentence).sumOf { it.words.size } + word
        repeat(words) {
            compose.onNodeWithText("Hear “", substring = true).performClick()
            compose.waitForIdle()
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    private fun storyFinished(dark: Boolean) {
        showReading(dark)
        val hear = compose.onNodeWithText("Hear “", substring = true)
        while (hear.exists()) {
            hear.performClick()
            compose.waitForIdle()
        }
        compose.onRoot().captureRoboImage(path("story-finished", dark), options)
    }

    @OptIn(ExperimentalRoborazziApi::class)
    private fun stopReading(dark: Boolean) {
        showReading(dark)
        compose.onNodeWithContentDescription("Back to stories").performClick()
        compose.waitForIdle()
        captureScreenRoboImage(path("stop-reading", dark), options)
    }

    private fun askToListen(dark: Boolean) {
        shadowOf(app).denyPermissions(Manifest.permission.RECORD_AUDIO)
        showReading(dark)
        compose.onRoot().captureRoboImage(path("ask-to-listen", dark), options)
    }

    private fun listeningUnavailable(dark: Boolean) {
        shadowOf(app).denyPermissions(Manifest.permission.RECORD_AUDIO)
        app.listeningPreferences.hasAskedForMicrophone = true
        showReading(dark)
        compose.onRoot().captureRoboImage(path("listening-unavailable", dark), options)
    }

    private fun showReading(dark: Boolean, story: Story = this.story) {
        compose.setContent {
            HopTalesTheme(dark = dark) { ReadingScreen(story = story, onDone = {}) }
        }
        compose.waitForIdle()
    }

    private fun SemanticsNodeInteraction.exists(): Boolean = runCatching { fetchSemanticsNode() }.isSuccess

    private fun path(name: String, dark: Boolean) = "src/test/screenshots/$name-${if (dark) "dark" else "light"}.png"

    private val options = RoborazziOptions(
        compareOptions = RoborazziOptions.CompareOptions(changeThreshold = 0.005f),
    )
}
