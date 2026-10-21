package com.hoptales.android

import android.Manifest
import android.provider.Settings
import androidx.activity.OnBackPressedDispatcher
import androidx.activity.compose.LocalOnBackPressedDispatcherOwner
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isHeading
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.BookScreen
import com.hoptales.android.home.FriendsScreen
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.home.JourneyMapScreen
import com.hoptales.android.home.WardrobeScreen
import com.hoptales.android.intro.IntroScreen
import com.hoptales.android.onboarding.OnboardingActions
import com.hoptales.android.onboarding.OnboardingContent
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.android.settings.SettingsActions
import com.hoptales.android.settings.SettingsContent
import com.hoptales.android.settings.SettingsState
import com.hoptales.content.Basket
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Profile
import com.hoptales.content.Progress
import com.hoptales.onboarding.OnboardingState
import com.hoptales.onboarding.OnboardingStep
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
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
class AccessibilityTest {
    @get:Rule
    val compose = createComposeRule()

    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication
    private val story get() = app.library.stories(Friend.HARE.level).first()

    @Before
    fun freezeMotion() {
        app.progressStore.save(Progress())
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
        shadowOf(app).grantPermissions(Manifest.permission.RECORD_AUDIO)
    }

    @Test
    fun introIsOneHeadingThatSkips() {
        compose.setContent { HopTalesTheme { IntroScreen(art = null, reduceMotion = false, onFinished = {}) } }
        compose.onNodeWithContentDescription("Hop Tales").assert(isHeading()).assertHasClickAction()
        compose.onNodeWithText("a read-aloud adventure").assertDoesNotExist()
    }

    @Test
    fun homeLabelsItsButtons() {
        val progress = Progress(completedSentences = mapOf("meadow-walk" to 3), journey = Journey.starting(Friend.HARE))
        compose.setContent {
            HopTalesTheme { HomeScreen(library = app.library, progress = progress, onStory = {}, childName = "Maya", hour = 9) }
        }
        compose.onNode(isHeading() and hasText("Good morning, Maya!")).assertExists()
        compose.onNode(isHeading() and hasText("More stories")).assertExists()
        compose.onNodeWithContentDescription("Settings for grown-ups").assertIsButton()
        compose.onNodeWithContentDescription("Opens your journey.", substring = true).assertIsButton()
        compose.onNodeWithContentDescription("Keep reading. ", substring = true).assertIsButton()
        for (title in listOf("Friends", "Book")) compose.onNodeWithContentDescription(title).assertIsButton()
        compose.onNodeWithContentDescription("${app.library.stories(1)[1].title}. ", substring = true).assertIsButton()
    }

    @Test
    fun onboardingNamesTheFieldAndTheStep() {
        onboarding(OnboardingStep.NAME)
        compose.onNode(isHeading() and hasText("What should we call you?")).assertExists()
        val step = "Step ${OnboardingStep.NAME.number} of ${OnboardingStep.entries.size}"
        assertEquals(2, compose.onAllNodesWithContentDescription(step).fetchSemanticsNodes().size)
        compose.onNode(hasContentDescription("Name or nickname") and hasSetText()).assertExists()
    }

    @Test
    fun onboardingBackupChoicesAreButtons() {
        onboarding(OnboardingStep.BACKUP)
        compose.onNode(isHeading() and hasText("Back up to your Google account?")).assertExists()
        compose.onNodeWithText("Yes, back up").assertIsButton()
        compose.onNodeWithText("Not now").assertIsButton()
    }

    @Test
    fun onboardingFriendIsOneSelectedButton() {
        onboarding(OnboardingStep.FRIEND)
        val hare = Friend.HARE
        compose.onNodeWithContentDescription("${hare.friendName}, ${hare.stage}. Words like", substring = true)
            .assertIsButton()
            .assertIsSelected()
        compose.onNodeWithText(hare.stage).assertDoesNotExist()
        compose.onNodeWithContentDescription("Back").assertHasClickAction()
    }

    @Test
    fun friendsCardsAreButtons() {
        val progress = Progress(journey = Journey.starting(Friend.HARE))
        compose.setContent { HopTalesTheme { FriendsScreen(progress, app.wardrobe, onFriend = {}, onJourney = {}, onDone = {}) } }
        compose.onNode(isHeading() and hasText("Friends")).assertExists()
        compose.onNodeWithContentDescription("Your journey").assertHasClickAction()
        compose.onNodeWithContentDescription(
            "${Friend.HARE.friendName}, level ${Friend.HARE.level}. Reading now.",
        ).assertIsButton().assertIsSelected()
        compose.onNodeWithContentDescription("${Friend.FROG.friendName} is next. Fill the path, then read the big story.").assertIsButton()
    }

    @Test
    fun wardrobeTilesAreButtons() {
        val progress = Progress(journey = Journey.starting(Friend.HARE))
        compose.setContent {
            HopTalesTheme { WardrobeScreen(Friend.HARE, progress, app.wardrobe, onItem = {}, onJustMe = {}, onDone = {}) }
        }
        compose.onNodeWithContentDescription("Just me, nothing on").assertIsButton()
        compose.onAllNodesWithContentDescription(", locked", substring = true).onFirst().assertIsButton()
    }

    @Test
    fun journeyStopsAreLabelled() {
        compose.setContent {
            HopTalesTheme { JourneyMapScreen(app.library, Journey.starting(Friend.HARE), onFriend = {}, onBigStory = {}, onDone = {}) }
        }
        compose.onNode(isHeading() and hasText("Your journey")).assertExists()
        compose.onNodeWithContentDescription(
            "${Friend.HARE.friendName}, reading level ${Friend.HARE.level}. Reading now.",
        ).assertHasClickAction()
    }

    @Test
    fun bookGroupsTheBasket() {
        val progress = Progress(journey = Journey.starting(Friend.HARE), baskets = mapOf(Friend.HARE to Basket(total = 12)))
        compose.setContent { HopTalesTheme { BookScreen(app.library, progress, Friend.HARE, onFriend = {}, onDone = {}) } }
        compose.onNodeWithContentDescription("12 ${Friend.HARE.treat.many} found").assertExists()
        compose.onNodeWithContentDescription("${Friend.HARE.friendName}'s page").assertHasClickAction()
    }

    @Test
    fun settingsHasHeadingsAndLabels() {
        val profile = Profile("Maya", Friend.HARE, Profile.Accent.CANADIAN, soundButtons = true)
        compose.setContent {
            HopTalesTheme {
                SettingsContent(
                    SettingsState(childName = "Maya", profile = profile, journey = Journey.starting(Friend.HARE)),
                    SettingsActions(),
                )
            }
        }
        compose.onNode(isHeading() and hasText("Settings")).assertExists()
        compose.onNode(isHeading() and hasContentDescription("Help voice")).assertExists()
        compose.onNodeWithContentDescription("Hear the help voice").assertHasClickAction()
        compose.onNodeWithContentDescription("Help voice, ", substring = true).assertHasClickAction()
    }

    @Test
    fun readingAnnouncesTheWordAndOffersToSayIt() {
        showReading()
        val word = story.sentences.first().words.first().text
        compose.onNodeWithContentDescription("Current word: $word. Say it out loud.")
            .assert(SemanticsMatcher("offers Hear the word") { it.config.getOrNull(SemanticsActions.OnClick)?.label == "Hear the word" })
        compose.onNodeWithContentDescription("Back to stories").assertHasClickAction()
    }

    @Test
    fun stopCardLeadsWithItsHeading() {
        showReading()
        compose.onNodeWithContentDescription("Back to stories").performClick()
        compose.waitForIdle()
        compose.onNode(isHeading() and hasText("Stop reading?", substring = true)).assertExists()
        compose.onNodeWithText("Keep reading").assertHasClickAction()
        compose.onAllNodesWithText("Back to stories").fetchSemanticsNodes().let { assertEquals(1, it.size) }
    }

    @Test
    fun systemBackOnTheStopCardKeepsReading() {
        var done = false
        lateinit var back: OnBackPressedDispatcher
        compose.setContent {
            back = LocalOnBackPressedDispatcherOwner.current!!.onBackPressedDispatcher
            HopTalesTheme { ReadingScreen(story = story, onDone = { done = true }) }
        }
        compose.waitForIdle()
        compose.runOnUiThread { back.onBackPressed() }
        compose.waitForIdle()
        compose.onNodeWithText("Keep reading").assertExists()
        compose.runOnUiThread { back.onBackPressed() }
        compose.waitForIdle()
        compose.onNodeWithText("Keep reading").assertDoesNotExist()
        assertFalse(done)
    }

    @Test
    fun systemBackWhenListeningIsUnavailableLeadsBack() {
        shadowOf(app).denyPermissions(Manifest.permission.RECORD_AUDIO)
        app.listeningPreferences.hasAskedForMicrophone = true
        var done = false
        lateinit var back: OnBackPressedDispatcher
        compose.setContent {
            back = LocalOnBackPressedDispatcherOwner.current!!.onBackPressedDispatcher
            HopTalesTheme { ReadingScreen(story = story, onDone = { done = true }) }
        }
        compose.waitForIdle()
        compose.runOnUiThread { back.onBackPressed() }
        compose.waitForIdle()
        assertTrue(done)
        compose.onNodeWithText("Keep reading").assertDoesNotExist()
    }

    @Test
    fun debugControlsAreHiddenFromTalkBack() {
        showReading()
        compose.onNodeWithText("Rest of sentence").assert(SemanticsMatcher.keyIsDefined(SemanticsProperties.HideFromAccessibility))
    }

    @Test
    fun finishedPanelNamesTheStoryAndTheStars() {
        showReading()
        val hear = compose.onNodeWithText("Read “", substring = true)
        while (hear.exists()) {
            hear.performClick()
            compose.waitForIdle()
        }
        compose.onNodeWithContentDescription("You finished ${story.title}.").assertExists()
        compose.onNodeWithContentDescription(" stars", substring = true).assertExists()
        compose.onNodeWithText("Done").assertHasClickAction()
        compose.onNodeWithText("Read it again").assertHasClickAction()
        compose.onNodeWithContentDescription(" steps. ", substring = true).assertExists()
        compose.onNodeWithContentDescription("Current word", substring = true).assertDoesNotExist()
        compose.onNodeWithContentDescription("Reading").assertDoesNotExist()
    }

    @Test
    fun listeningUnavailableLeadsBack() {
        shadowOf(app).denyPermissions(Manifest.permission.RECORD_AUDIO)
        app.listeningPreferences.hasAskedForMicrophone = true
        showReading()
        compose.onNodeWithText("The microphone is off").assertExists()
        compose.onAllNodesWithText("Back to stories").fetchSemanticsNodes().let { assertEquals(1, it.size) }
    }

    private fun onboarding(step: OnboardingStep) {
        val state = OnboardingState(
            step = step,
            childName = "Maya",
            startingFriend = Friend.HARE.takeIf { step >= OnboardingStep.FRIEND },
        )
        compose.setContent { HopTalesTheme { OnboardingContent(state, OnboardingActions()) } }
    }

    private fun showReading() {
        compose.setContent { HopTalesTheme { ReadingScreen(story = story, onDone = {}) } }
        compose.waitForIdle()
    }

    private fun SemanticsNodeInteraction.assertIsButton(): SemanticsNodeInteraction = assertHasClickAction()
        .assert(SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Button))

    private fun hasSetText() = SemanticsMatcher.keyIsDefined(SemanticsActions.SetText)

    private fun SemanticsNodeInteraction.exists(): Boolean = runCatching { fetchSemanticsNode() }.isSuccess
}
