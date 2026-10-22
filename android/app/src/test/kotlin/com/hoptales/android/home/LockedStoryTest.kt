package com.hoptales.android.home

import android.provider.Settings
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.settings.ParentGateState
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Progress
import com.hoptales.content.Story
import com.hoptales.content.StoryStanding
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
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
class LockedStoryTest {
    @get:Rule
    val compose = createComposeRule()

    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication
    private val plusStory get() = app.library.stories(Friend.HARE.level).first()

    @Before
    fun freezeMotion() {
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
    }

    @Test
    fun aLockedStoryOpensTheCardNeverTheReader() {
        val read = mutableListOf<Story>()
        val carded = mutableListOf<Story>()
        compose.setContent {
            HopTalesTheme {
                HomeScreen(
                    library = app.library,
                    progress = Progress(journey = Journey.starting(Friend.HARE)),
                    onStory = { read += it },
                    hour = 9,
                    isLocked = { !it.isFree },
                    onLockedStory = { carded += it },
                )
            }
        }
        compose.onNodeWithContentDescription("${plusStory.title}. 6 sentences. Locked, part of Hop Tales Plus")
            .performScrollTo()
            .performClick()
        assertEquals(listOf(plusStory), carded)
        assertTrue(read.isEmpty())
    }

    @Test
    fun keepReadingNeverOffersALockedStory() {
        val read = mutableListOf<Story>()
        compose.setContent {
            HopTalesTheme {
                HomeScreen(
                    library = app.library,
                    progress = Progress(completedSentences = mapOf(plusStory.id to 3), journey = Journey.starting(Friend.HARE)),
                    onStory = { read += it },
                    hour = 9,
                    isLocked = { !it.isFree },
                )
            }
        }
        compose.onNodeWithContentDescription("Start here", substring = true).performClick()
        assertEquals(1, read.single().level)
    }

    @Test
    fun theCardShowsTheStandingAndNothingWhenUnread() {
        val total = plusStory.sentences.size
        assertEquals(
            "You read 4 of $total",
            StoryStanding.of(plusStory, Progress(completedSentences = mapOf(plusStory.id to 4))).lockedLine,
        )
        assertEquals(
            "You read all $total",
            StoryStanding.of(plusStory, Progress(completedSentences = mapOf(plusStory.id to total))).lockedLine,
        )
        assertNull(StoryStanding.of(plusStory, Progress()).lockedLine)
    }

    @Test
    fun askingAGrownUpGoesThroughTheGate() {
        var done = 0
        compose.setContent {
            HopTalesTheme {
                LockedStoryScreen(StoryStanding.of(plusStory, Progress()), onDone = { done += 1 }, gate = ParentGateState(seed = 1))
            }
        }
        compose.onNodeWithText("Ask a grown-up").performClick()
        compose.onNodeWithText("What is five times three?").assertIsDisplayed()
        compose.onNodeWithContentDescription("5").performClick()
        compose.onNodeWithContentDescription("3").performClick()
        compose.onNodeWithContentDescription("Check answer").performClick()
        compose.onNodeWithText("What is four times three?").assertIsDisplayed()
        compose.onNodeWithContentDescription("1").performClick()
        compose.onNodeWithContentDescription("2").performClick()
        compose.onNodeWithContentDescription("Check answer").performClick()
        compose.onNodeWithText("Hop Tales Plus is on its way").assertIsDisplayed()
        compose.onNodeWithText("Back to stories").performClick()
        assertEquals(1, done)
    }

    @Test
    fun closingTheGateGoesBackToTheCard() {
        compose.setContent {
            HopTalesTheme {
                LockedStoryScreen(StoryStanding.of(plusStory, Progress()), onDone = {}, gate = ParentGateState(seed = 1))
            }
        }
        compose.onNodeWithText("Ask a grown-up").performClick()
        compose.onNodeWithText("Close").performClick()
        compose.onNodeWithText("This story is part of Hop Tales Plus.").assertIsDisplayed()
    }
}
