package com.hoptales.android

import android.Manifest
import android.provider.Settings
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performSemanticsAction
import com.github.takahirom.roborazzi.ExperimentalRoborazziApi
import com.github.takahirom.roborazzi.RoborazziOptions
import com.github.takahirom.roborazzi.captureRoboImage
import com.github.takahirom.roborazzi.captureScreenRoboImage
import com.hoptales.android.billing.FakePlusSource
import com.hoptales.android.billing.PurchaseOutcome
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.BookScreen
import com.hoptales.android.home.FriendsScreen
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.home.JourneyMapScreen
import com.hoptales.android.home.LockedStoryScreen
import com.hoptales.android.home.WardrobeScreen
import com.hoptales.android.intro.IntroContent
import com.hoptales.android.onboarding.OnboardingActions
import com.hoptales.android.onboarding.OnboardingContent
import com.hoptales.android.reading.ChallengeTip
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.android.settings.ParentGate
import com.hoptales.android.settings.ParentGateState
import com.hoptales.android.settings.Paywall
import com.hoptales.android.settings.SettingsActions
import com.hoptales.android.settings.SettingsContent
import com.hoptales.android.settings.SettingsState
import com.hoptales.android.world.IntroArt
import com.hoptales.android.world.IntroTimeline
import com.hoptales.content.Basket
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Mood
import com.hoptales.content.Plus
import com.hoptales.content.PlusStatus
import com.hoptales.content.Profile
import com.hoptales.content.Progress
import com.hoptales.content.Sky
import com.hoptales.content.Story
import com.hoptales.content.StoryStanding
import com.hoptales.content.Weather
import com.hoptales.onboarding.OnboardingState
import com.hoptales.onboarding.OnboardingStep
import org.junit.Assert.assertEquals
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
abstract class ScreenshotFixture {
    @get:Rule
    val compose = createComposeRule()

    protected val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication

    protected val story get() = app.library.stories(Friend.HARE.level).first()

    @Before
    fun freezeMotion() {
        app.progressStore.save(Progress())
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
        shadowOf(app).grantPermissions(Manifest.permission.RECORD_AUDIO)
    }

    protected fun intro(name: String, time: Double) {
        val art = IntroArt.load(app.assets)
        compose.setContent {
            HopTalesTheme { IntroContent(art, time = { time }, showsTitle = true) }
        }
        compose.onRoot().captureRoboImage("src/test/screenshots/$name.png", options)
    }

    protected fun onboardingWelcome(dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) { OnboardingContent(OnboardingState(isWelcoming = true), OnboardingActions()) }
        }
        compose.onRoot().captureRoboImage(path("onboarding-welcome", dark), options)
    }

    protected fun onboarding(step: OnboardingStep, dark: Boolean) {
        val state = OnboardingState(
            step = step,
            backup = true,
            childName = "Maya",
            soundButtons = true.takeIf { step >= OnboardingStep.SOUND_BUTTONS },
        )
        compose.setContent {
            HopTalesTheme(dark = dark) { OnboardingContent(state, OnboardingActions()) }
        }
        compose.onRoot().captureRoboImage(path("onboarding-${step.name.lowercase().replace('_', '-')}", dark), options)
    }

    protected fun plusSection(name: String, status: PlusStatus, dark: Boolean) {
        val profile = Profile("Maya", Friend.HARE, Profile.Accent.CANADIAN)
        compose.setContent {
            HopTalesTheme(dark = dark) {
                SettingsContent(
                    SettingsState(
                        childName = "Maya",
                        profile = profile,
                        journey = Journey.starting(Friend.HARE),
                        plusStatus = status,
                    ),
                    SettingsActions(),
                )
            }
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    protected fun settings(dark: Boolean) {
        val profile = Profile("Maya", Friend.HARE, Profile.Accent.CANADIAN, soundButtons = true)
        compose.setContent {
            HopTalesTheme(dark = dark) {
                SettingsContent(
                    SettingsState(
                        childName = "Maya",
                        profile = profile,
                        journey = Journey.starting(Friend.HARE),
                        backupOn = true,
                        backupWasOn = true,
                        speechLogLines = 42,
                    ),
                    SettingsActions(),
                )
            }
        }
        compose.onRoot().captureRoboImage(path("settings", dark), options)
    }

    protected val midway = Progress(
        stars = 56,
        completedSentences = mapOf("meadow-walk" to 6, "golden-hour" to 3),
        journey = Journey.starting(Friend.HARE),
    )

    protected fun home(name: String, progress: Progress, dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) {
                HomeScreen(library = app.library, progress = progress, onStory = {}, childName = "Maya", hour = 9)
            }
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    protected val newQuestion = ParentGateState(seed = 1, round = 1, entry = "4")

    protected fun homeLocked(dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) {
                HomeScreen(
                    library = app.library,
                    progress = midway,
                    onStory = {},
                    childName = "Maya",
                    hour = 9,
                    isLocked = { !it.isFree },
                )
            }
        }
        compose.onRoot().captureRoboImage(path("home-locked", dark), options)
    }

    protected fun homeLockedLevels(dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) {
                HomeScreen(
                    library = app.library,
                    progress = Progress(stars = 30, completedSentences = mapOf("meadow-walk" to 6, "bob-bug" to 2)),
                    onStory = {},
                    childName = "Maya",
                    hour = 9,
                    isLocked = { !it.isFree },
                    lockedLevels = Plus.lockedLevels(Friend.BUNNY.level, app.library, isPlus = false, locksStories = true),
                )
            }
        }
        compose.onRoot().captureRoboImage(path("home-locked-levels", dark), options)
    }

    protected fun lockedCard(dark: Boolean) {
        val locked = app.library.stories(Friend.HARE.level)[1]
        val standing = StoryStanding.of(locked, Progress(completedSentences = mapOf(locked.id to 4)))
        compose.setContent {
            HopTalesTheme(dark = dark) { LockedStoryScreen(standing, FakePlusSource(), onDone = {}) }
        }
        compose.onRoot().captureRoboImage(path("locked-card", dark), options)
    }

    protected fun parentGate(name: String, gate: ParentGateState, dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) { ParentGate(onPassed = {}, onClose = {}, initial = gate) }
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    protected fun paywall(name: String, plus: FakePlusSource, dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) { Paywall(plus, onClose = {}, live = false) }
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    protected fun paywallPending(dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) { Paywall(FakePlusSource(outcome = PurchaseOutcome.PENDING), onClose = {}, live = false) }
        }
        compose.onNodeWithContentDescription("Yearly", substring = true).performClick()
        compose.onRoot().captureRoboImage(path("paywall-pending", dark), options)
    }

    protected fun basketFull(dark: Boolean) {
        app.progressStore.save(Progress(baskets = mapOf(Friend.HARE to Basket(inBasket = 3))))
        storyFinished(dark, name = "basket-full")
    }

    protected fun journeyMap(dark: Boolean) {
        val journey = Journey.starting(Friend.HARE).copy(steps = 150.0)
        compose.setContent {
            HopTalesTheme(dark = dark) { JourneyMapScreen(app.library, journey, onFriend = {}, onBigStory = {}, onDone = {}) }
        }
        compose.onRoot().captureRoboImage(path("journey-map", dark), options)
    }

    protected fun friends(dark: Boolean) {
        val progress = Progress(
            journey = Journey.starting(Friend.HARE).copy(steps = 164.0),
            baskets = mapOf(Friend.HARE to Basket(total = 64)),
        )
        compose.setContent {
            HopTalesTheme(dark = dark) { FriendsScreen(progress, app.wardrobe, onFriend = {}, onJourney = {}, onDone = {}) }
        }
        compose.onRoot().captureRoboImage(path("friends", dark), options)
    }

    protected fun wardrobe(dark: Boolean) {
        val worn = app.wardrobe.items(Friend.BUNNY)[1]
        val progress = Progress(
            journey = Journey.starting(Friend.FROG),
            baskets = mapOf(Friend.BUNNY to Basket(filled = 3)),
            outfits = mapOf(Friend.BUNNY to mapOf(worn.slot to worn.id)),
        )
        compose.setContent {
            HopTalesTheme(dark = dark) { WardrobeScreen(Friend.BUNNY, progress, app.wardrobe, onItem = {}, onJustMe = {}, onDone = {}) }
        }
        compose.onRoot().captureRoboImage(path("wardrobe", dark), options)
    }

    protected fun book(dark: Boolean) {
        val progress = Progress(
            completedSentences = mapOf("golden-hour" to 6, "skip-and-frog" to 6),
            journey = Journey.starting(Friend.HARE),
            baskets = mapOf(Friend.HARE to Basket(total = 64, golden = 3)),
        )
        compose.setContent {
            HopTalesTheme(dark = dark) { BookScreen(app.library, progress, Friend.HARE, onFriend = {}, onDone = {}) }
        }
        compose.onRoot().captureRoboImage(path("book", dark), options)
    }

    protected fun reading(dark: Boolean) {
        showReading(dark)
        compose.onRoot().captureRoboImage(path("reading", dark), options)
    }

    protected fun moment(name: String, id: String, sentence: Int, word: Int, dark: Boolean = false, soundButtons: Boolean = false) {
        val story = app.library[id]!!
        if (soundButtons) app.profileStore.save(Profile("Maya", soundButtons = true))
        midPage(name, story, story.sentences.take(sentence).sumOf { it.words.size } + word, dark)
    }

    protected fun mood(sky: Sky, weather: Weather) {
        val story = story.copy(mood = Mood(sky, weather), sentences = story.sentences.map { it.copy(sky = null, weather = null) })
        midPage("mood-${sky.name.lowercase()}-${weather.name.lowercase()}", story)
    }

    protected fun world(friend: Friend) {
        midPage("world-${friend.key}", app.library["meadow-walk"]!!.copy(level = friend.level), words = 0)
    }

    protected fun midPage(name: String, story: Story, words: Int = 3, dark: Boolean = false) {
        showReading(dark, story)
        repeat(words) {
            compose.onNodeWithText("Read “", substring = true).performClick()
            compose.waitForIdle()
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    protected fun storyFinished(dark: Boolean, name: String = "story-finished", story: Story = this.story) {
        showReading(dark, story)
        readToTheEnd()
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    protected fun readToTheEnd() {
        val rest = compose.onNodeWithText("Rest of sentence")
        while (rest.exists()) {
            rest.performClick()
            compose.waitForIdle()
        }
    }

    protected fun challengeTip(dark: Boolean) {
        val story = app.library["meadow-walk"]!!
        showReading(dark, story)
        repeat(story.sentences.take(2).sumOf { it.words.size } + 1) {
            compose.onNodeWithText("Read “", substring = true).performClick()
            compose.waitForIdle()
        }
        compose.onNodeWithContentDescription("Current word: spots", substring = true).performSemanticsAction(SemanticsActions.OnLongClick)
        compose.mainClock.advanceTimeBy(ChallengeTip.SHOW_MILLIS * 2L)
        compose.onNodeWithContentDescription("Challenge word. ", substring = true).assertExists()
        compose.onRoot().captureRoboImage(path("challenge-tip", dark), options)
    }

    protected fun triedItOn(dark: Boolean) {
        app.progressStore.save(Progress(baskets = mapOf(Friend.HARE to Basket(inBasket = 3))))
        showReading(dark)
        readToTheEnd()
        compose.onNodeWithContentDescription("A present. Double tap to open it.").performClick()
        compose.waitForIdle()
        compose.onNodeWithText("Try it on").performClick()
        compose.waitForIdle()
        compose.onRoot().captureRoboImage(path("tried-it-on", dark), options)
    }

    protected fun finishLevelOne(dark: Boolean, onDone: () -> Unit = {}) {
        val levelOne = app.library.stories(Friend.BUNNY.level)
        app.progressStore.save(Progress(completedSentences = levelOne.associate { it.id to it.sentences.size }))
        compose.setContent {
            HopTalesTheme(dark = dark) { ReadingScreen(story = levelOne.first(), onDone = onDone, locksStories = true) }
        }
        compose.waitForIdle()
        readToTheEnd()
    }

    protected fun levelOneFinished(dark: Boolean) {
        finishLevelOne(dark)
        compose.onNodeWithText("You finished Level 1!").assertExists()
        compose.onNodeWithContentDescription("Skip is waiting. Words like ship, duck, frog.").assertExists()
        compose.onNodeWithText("New friends are waiting on your stories page.").assertExists()
        compose.onNodeWithText("Back to my stories").assertExists()
        compose.onRoot().captureRoboImage(path("level-one-finished", dark), options)
    }

    protected fun newFriend(dark: Boolean) {
        storyFinished(dark, name = "new-friend", story = app.library["skip-big-story"]!!)
    }

    @OptIn(ExperimentalRoborazziApi::class)
    protected fun stopReading(dark: Boolean) {
        showReading(dark)
        compose.onNodeWithContentDescription("Back to stories").performClick()
        compose.waitForIdle()
        captureScreenRoboImage(path("stop-reading", dark), options)
    }

    protected fun askToListen(dark: Boolean) {
        shadowOf(app).denyPermissions(Manifest.permission.RECORD_AUDIO)
        showReading(dark)
        compose.onRoot().captureRoboImage(path("ask-to-listen", dark), options)
    }

    protected fun listeningUnavailable(dark: Boolean) {
        shadowOf(app).denyPermissions(Manifest.permission.RECORD_AUDIO)
        app.listeningPreferences.hasAskedForMicrophone = true
        showReading(dark)
        compose.onRoot().captureRoboImage(path("listening-unavailable", dark), options)
    }

    protected fun showReading(dark: Boolean, story: Story = this.story) {
        compose.setContent {
            HopTalesTheme(dark = dark) { ReadingScreen(story = story, onDone = {}) }
        }
        compose.waitForIdle()
    }

    protected fun SemanticsNodeInteraction.exists(): Boolean = runCatching { fetchSemanticsNode() }.isSuccess

    protected fun path(name: String, dark: Boolean) = "src/test/screenshots/$name-${if (dark) "dark" else "light"}.png"

    protected val options = RoborazziOptions(
        compareOptions = RoborazziOptions.CompareOptions(changeThreshold = 0.005f),
    )
}
