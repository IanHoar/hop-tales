package com.hoptales.android.home

import android.provider.Settings
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.billing.FakePlusSource
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.settings.PLACEHOLDER_MILLIS
import com.hoptales.android.settings.ParentGateState
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Progress
import com.hoptales.content.Story
import com.hoptales.content.StoryStanding
import com.hoptales.content.bigStoryWaiting
import com.hoptales.content.levelStanding
import com.hoptales.content.nextLevels
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
                LockedStoryScreen(
                    StoryStanding.of(plusStory, Progress()),
                    FakePlusSource(),
                    onDone = { done += 1 },
                    gate = ParentGateState(seed = 1),
                )
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
        compose.onNodeWithText("Hop Tales Plus").assertIsDisplayed()
        compose.onNodeWithText("Close").performClick()
        compose.onNodeWithText("This story is part of Hop Tales Plus.").assertIsDisplayed()
        assertEquals(0, done)
    }

    @Test
    fun subscribingWelcomesThenOpensTheLockedStory() {
        val read = mutableListOf<Story>()
        val plus = FakePlusSource()
        compose.setContent {
            HopTalesTheme {
                LockedStoryScreen(
                    StoryStanding.of(plusStory, Progress()),
                    plus,
                    onDone = {},
                    onRead = { read += it },
                    step = LockedStep.PAYWALL,
                )
            }
        }
        compose.mainClock.advanceTimeBy(PLACEHOLDER_MILLIS)
        compose.onNodeWithText("Subscribe").performScrollTo().performClick()
        compose.waitForIdle()
        assertTrue(plus.isPlus.value)
        compose.onNodeWithText("Every story is open now. Up next: ${plusStory.title}.").assertIsDisplayed()
        compose.onNodeWithText("Read ${plusStory.title}").performClick()
        assertEquals(listOf(plusStory), read)
    }

    @Test
    fun closingTheGateGoesBackToTheCard() {
        compose.setContent {
            HopTalesTheme {
                LockedStoryScreen(StoryStanding.of(plusStory, Progress()), FakePlusSource(), onDone = {}, gate = ParentGateState(seed = 1))
            }
        }
        compose.onNodeWithText("Ask a grown-up").performClick()
        compose.onNodeWithText("Close").performClick()
        compose.onNodeWithText("This story is part of Hop Tales Plus.").assertIsDisplayed()
    }

    @Test
    fun aLockedLevelOpensTheGateNeverAStory() {
        val read = mutableListOf<Story>()
        val tapped = mutableListOf<Friend>()
        compose.setContent {
            HopTalesTheme {
                HomeScreen(
                    library = app.library,
                    progress = Progress(),
                    onStory = { read += it },
                    hour = 9,
                    isLocked = { !it.isFree },
                    nextLevels = Progress().nextLevels(app.library, isPlus = false, locksStories = true),
                    levelStanding = { Progress().levelStanding(it, app.library, isPlus = false, locksStories = true) },
                    onLockedLevel = { tapped += it },
                )
            }
        }
        compose.onNodeWithContentDescription("Level 3 with Oggy. Words like lake, kite, home. Locked, part of Hop Tales Plus")
            .assertExists()
        compose.onNodeWithContentDescription("Level 2 with Skip. Words like ship, duck, frog. Locked, part of Hop Tales Plus")
            .performScrollTo()
            .performClick()
        assertEquals(listOf(Friend.HARE), tapped)
        assertTrue(read.isEmpty())
    }

    @Test
    fun noLockedLevelsShowWithoutThem() {
        compose.setContent {
            HopTalesTheme {
                HomeScreen(library = app.library, progress = Progress(), onStory = {}, hour = 9)
            }
        }
        compose.onNodeWithText("Next levels").assertDoesNotExist()
    }

    @Test
    fun aLockedLevelGoesThroughTheGateToThePaywall() {
        var done = 0
        compose.setContent {
            HopTalesTheme { LockedLevelScreen(FakePlusSource(), onDone = { done += 1 }, gate = ParentGateState(seed = 1)) }
        }
        compose.onNodeWithText("Ask a grown-up to answer this.").assertIsDisplayed()
        compose.onNodeWithText("What is five times three?").assertIsDisplayed()
        compose.onNodeWithContentDescription("1").performClick()
        compose.onNodeWithContentDescription("5").performClick()
        compose.onNodeWithContentDescription("Check answer").performClick()
        compose.onNodeWithText("Hop Tales Plus").assertIsDisplayed()
        compose.onNodeWithText("Close").performClick()
        assertEquals(1, done)
    }

    @Test
    fun closingTheGateFromALockedLevelGoesBackHome() {
        var done = 0
        compose.setContent {
            HopTalesTheme { LockedLevelScreen(FakePlusSource(), onDone = { done += 1 }, gate = ParentGateState(seed = 1)) }
        }
        compose.onNodeWithText("Close").performClick()
        assertEquals(1, done)
    }

    @Test
    fun subscribingFromALockedLevelWelcomesThenGoesBackHome() {
        var done = 0
        val plus = FakePlusSource()
        compose.setContent {
            HopTalesTheme { LockedLevelScreen(plus, onDone = { done += 1 }, step = LockedLevelStep.PAYWALL) }
        }
        compose.mainClock.advanceTimeBy(PLACEHOLDER_MILLIS)
        compose.onNodeWithText("Subscribe").performScrollTo().performClick()
        compose.waitForIdle()
        assertTrue(plus.isPlus.value)
        compose.onNodeWithText("Welcome to Hop Tales Plus!").assertIsDisplayed()
        compose.onNodeWithText("Back to stories").performClick()
        assertEquals(1, done)
    }

    @Test
    fun plusReadersSeeTheNextFriendsBigStoryOnHome() {
        val read = mutableListOf<Story>()
        val stories = app.library.stories(1)
        val base = Progress(completedSentences = stories.associate { it.id to 99 })
        val progress = base.copy(journey = base.journey.copy(storiesRead = stories.map { it.id }.toSet()))
        val big = app.library.bigStory(2)!!
        compose.setContent {
            HopTalesTheme {
                HomeScreen(
                    library = app.library,
                    progress = progress,
                    onStory = { read += it },
                    hour = 9,
                    nextLevels = progress.nextLevels(app.library, isPlus = true, locksStories = true),
                    levelStanding = { progress.levelStanding(it, app.library, isPlus = true, locksStories = true) },
                    bigStoryWaiting = progress.bigStoryWaiting(app.library, isPlus = true, locksStories = true),
                )
            }
        }
        compose.onNodeWithContentDescription("Level 3 with Oggy. Words like lake, kite, home. Read your stories to get there")
            .assertExists()
        compose.onNodeWithContentDescription("Level 2 with Skip. Skip's big story is ready").performScrollTo().performClick()
        compose.onNodeWithContentDescription("A new friend. Meet Skip", substring = true).performScrollTo().performClick()
        compose.onNodeWithContentDescription("Skip is waiting with a big story").performScrollTo().performClick()
        assertEquals(listOf(big, big, big), read)
    }
}
