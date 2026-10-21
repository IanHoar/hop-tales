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
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.content.Friend
import com.hoptales.content.Progress
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

    @Test fun storyFinishedLight() = storyFinished(dark = false)

    @Test fun storyFinishedDark() = storyFinished(dark = true)

    @Test fun stopReadingLight() = stopReading(dark = false)

    @Test fun stopReadingDark() = stopReading(dark = true)

    private fun home(dark: Boolean) {
        val progress = Progress(stars = 12, completedSentences = mapOf(story.id to story.sentences.size))
        compose.setContent {
            HopTalesTheme(dark = dark) { HomeScreen(library = app.library, progress = progress, onStory = {}) }
        }
        compose.onRoot().captureRoboImage(path("home", dark), options)
    }

    private fun reading(dark: Boolean) {
        showReading(dark)
        compose.onRoot().captureRoboImage(path("reading", dark), options)
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
        compose.onNodeWithContentDescription("Back").performClick()
        compose.waitForIdle()
        captureScreenRoboImage(path("stop-reading", dark), options)
    }

    private fun showReading(dark: Boolean) {
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
