package com.hoptales.android

import android.Manifest
import android.provider.Settings
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import com.github.takahirom.roborazzi.RoborazziOptions
import com.github.takahirom.roborazzi.RoborazziTaskType
import com.github.takahirom.roborazzi.captureRoboImage
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Progress
import com.hoptales.content.Story
import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w412dp-h915dp-xxhdpi")
class StoreScreenshotTest {
    @get:Rule
    val compose = createComposeRule()

    private val output = System.getProperty("hoptales.storeScreenshots")
    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication

    @Before
    fun setUp() {
        assumeTrue("Run with -PstoreScreenshots", output != null)
        app.progressStore.save(Progress())
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
        shadowOf(app).grantPermissions(Manifest.permission.RECORD_AUDIO)
    }

    @Test fun reading() = moment("reading", "bob-bug", sentence = 3, word = 3)

    @Test fun moodNightClear() = moment("mood-night-clear", "button-big-story", sentence = 1, word = 8)

    @Test fun worldCrab() = moment("world-crab", "barnacle-shells", sentence = 0, word = 4)

    @Test fun moodDayRain() = moment("mood-day-rain", "rain-on-the-field", sentence = 1, word = 8)

    @Test
    fun newFriend() {
        show(app.library["skip-big-story"]!!) { while (hear.exists()) advance() }
        capture("new-friend")
    }

    @Test
    fun homeMidway() {
        val midway = Progress(
            stars = 56,
            completedSentences = mapOf("meadow-walk" to 6, "golden-hour" to 3),
            journey = Journey.starting(Friend.HARE),
        )
        compose.setContent {
            HopTalesTheme(dark = false) {
                HomeScreen(library = app.library, progress = midway, onStory = {}, childName = "Maya", hour = 9)
            }
        }
        capture("home-midway")
    }

    private fun moment(name: String, id: String, sentence: Int, word: Int) {
        val story = app.library[id]!!
        show(story) { repeat(story.sentences.take(sentence).sumOf { it.words.size } + word) { advance() } }
        capture(name)
    }

    private fun show(story: Story, read: () -> Unit) {
        var debug by mutableStateOf(true)
        compose.setContent {
            HopTalesTheme(dark = false) { ReadingScreen(story = story, onDone = {}, showsDebugControls = debug) }
        }
        compose.waitForIdle()
        read()
        debug = false
        compose.waitForIdle()
    }

    private val hear get() = compose.onNodeWithText("Read “", substring = true)

    private fun advance() {
        hear.performClick()
        compose.waitForIdle()
    }

    private fun capture(name: String) {
        compose.onRoot().captureRoboImage(File(output, "android-$name.png"), options)
    }

    private fun SemanticsNodeInteraction.exists(): Boolean = runCatching { fetchSemanticsNode() }.isSuccess

    private val options = RoborazziOptions(taskType = RoborazziTaskType.Record)
}
