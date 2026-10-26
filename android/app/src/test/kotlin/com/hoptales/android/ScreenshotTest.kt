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
class ScreenshotTest {
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

    @Test fun homeFirstRunLight() = home("home-first-run", Progress(), dark = false)

    @Test fun homeFirstRunDark() = home("home-first-run", Progress(), dark = true)

    @Test fun homeMidwayLight() = home("home-midway", midway, dark = false)

    @Test fun homeMidwayDark() = home("home-midway", midway, dark = true)

    @Test fun homeLockedLight() = homeLocked(dark = false)

    @Test fun homeLockedDark() = homeLocked(dark = true)

    @Test
    @Config(qualifiers = "w412dp-h1480dp-xhdpi")
    fun homeLockedLevelsLight() = homeLockedLevels(dark = false)

    @Test
    @Config(qualifiers = "w412dp-h1480dp-xhdpi")
    fun homeLockedLevelsDark() = homeLockedLevels(dark = true)

    @Test fun lockedCardLight() = lockedCard(dark = false)

    @Test fun lockedCardDark() = lockedCard(dark = true)

    @Test fun parentGateLight() = parentGate("parent-gate", ParentGateState(seed = 1), dark = false)

    @Test fun parentGateDark() = parentGate("parent-gate", ParentGateState(seed = 1), dark = true)

    @Test fun parentGateNewQuestionLight() = parentGate("parent-gate-new-question", newQuestion, dark = false)

    @Test fun parentGateNewQuestionDark() = parentGate("parent-gate-new-question", newQuestion, dark = true)

    @Test fun paywallLight() = paywall("paywall", FakePlusSource(), dark = false)

    @Test fun paywallDark() = paywall("paywall", FakePlusSource(), dark = true)

    @Test fun paywallOnboardingLight() = paywall("paywall-onboarding", FakePlusSource(), dark = false, onboarding = true)

    @Test fun paywallOnboardingDark() = paywall("paywall-onboarding", FakePlusSource(), dark = true, onboarding = true)

    @Test fun paywallUnavailableLight() = paywall("paywall-unavailable", FakePlusSource(offers = null), dark = false)

    @Test fun paywallUnavailableDark() = paywall("paywall-unavailable", FakePlusSource(offers = null), dark = true)

    @Test fun paywallPendingLight() = paywallPending(dark = false)

    @Test fun paywallPendingDark() = paywallPending(dark = true)

    @Test fun basketFullLight() = basketFull(dark = false)

    @Test fun basketFullDark() = basketFull(dark = true)

    @Test fun journeyMapLight() = journeyMap(dark = false)

    @Test fun journeyMapDark() = journeyMap(dark = true)

    @Test fun friendsLight() = friends(dark = false)

    @Test fun friendsDark() = friends(dark = true)

    @Test fun wardrobeLight() = wardrobe(dark = false)

    @Test fun wardrobeDark() = wardrobe(dark = true)

    @Test fun bookLight() = book(dark = false)

    @Test fun bookDark() = book(dark = true)

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

    @Test fun moodDayClear() = mood(Sky.DAY, Weather.CLEAR)

    @Test fun moodGoldenClouds() = mood(Sky.GOLDEN, Weather.CLOUDS)

    @Test fun moodDayStorm() = mood(Sky.DAY, Weather.STORM)

    @Test fun moodDayRain() = mood(Sky.DAY, Weather.RAIN)

    @Test fun moodDuskClear() = mood(Sky.DUSK, Weather.CLEAR)

    @Test fun moodNightClear() = mood(Sky.NIGHT, Weather.CLEAR)

    @Test fun worldBunny() = world(Friend.BUNNY)

    @Test fun worldFrog() = world(Friend.FROG)

    @Test fun worldCrow() = world(Friend.CROW)

    @Test fun worldCat() = world(Friend.CAT)

    @Test fun worldCrab() = world(Friend.CRAB)

    @Test fun worldGrasshopper() = world(Friend.GRASSHOPPER)

    @Test fun storyFinishedLight() = storyFinished(dark = false)

    @Test fun storyFinishedDark() = storyFinished(dark = true)

    @Test fun bigWordLight() = moment("big-word", "meadow-walk", sentence = 2, word = 1, dark = false)

    @Test fun bigWordDark() = moment("big-word", "meadow-walk", sentence = 2, word = 1, dark = true)

    @Test fun challengeTipLight() = challengeTip(dark = false)

    @Test fun challengeTipDark() = challengeTip(dark = true)

    @Test fun triedItOnLight() = triedItOn(dark = false)

    @Test fun triedItOnDark() = triedItOn(dark = true)

    @Test fun levelOneFinishedLight() = levelOneFinished(dark = false)

    @Test fun levelOneFinishedDark() = levelOneFinished(dark = true)

    @Test fun newFriendLight() = newFriend(dark = false)

    @Test fun newFriendDark() = newFriend(dark = true)

    @Test fun stopReadingLight() = stopReading(dark = false)

    @Test fun stopReadingDark() = stopReading(dark = true)

    @Test fun askToListenLight() = askToListen(dark = false)

    @Test fun askToListenDark() = askToListen(dark = true)

    @Test fun listeningUnavailableLight() = listeningUnavailable(dark = false)

    @Test fun listeningUnavailableDark() = listeningUnavailable(dark = true)

    @Test fun onboardingWelcomeLight() = onboardingWelcome(dark = false)

    @Test fun onboardingWelcomeDark() = onboardingWelcome(dark = true)

    @Test fun onboardingBackupLight() = onboarding(OnboardingStep.BACKUP, dark = false)

    @Test fun onboardingBackupDark() = onboarding(OnboardingStep.BACKUP, dark = true)

    @Test fun onboardingNameLight() = onboarding(OnboardingStep.NAME, dark = false)

    @Test fun onboardingNameDark() = onboarding(OnboardingStep.NAME, dark = true)

    @Test fun onboardingListeningLight() = onboarding(OnboardingStep.LISTENING, dark = false)

    @Test fun onboardingListeningDark() = onboarding(OnboardingStep.LISTENING, dark = true)

    @Test fun onboardingAheadLight() = onboarding(OnboardingStep.AHEAD, dark = false)

    @Test fun onboardingAheadDark() = onboarding(OnboardingStep.AHEAD, dark = true)

    @Test fun onboardingSoundButtonsLight() = onboarding(OnboardingStep.SOUND_BUTTONS, dark = false)

    @Test fun onboardingSoundButtonsDark() = onboarding(OnboardingStep.SOUND_BUTTONS, dark = true)

    @Test
    @Config(qualifiers = "w412dp-h2540dp-xhdpi")
    fun settingsLight() = settings(dark = false)

    @Test
    @Config(qualifiers = "w412dp-h2540dp-xhdpi")
    fun settingsDark() = settings(dark = true)

    @Test fun plusFreeLight() = plusSection("plus-free", PlusStatus.Free, dark = false, nothingToRestore = true)

    @Test fun plusFreeDark() = plusSection("plus-free", PlusStatus.Free, dark = true, nothingToRestore = true)

    @Test fun plusRenewsLight() = plusSection("plus-renews", PlusStatus.Renews(), dark = false)

    @Test fun plusRenewsDark() = plusSection("plus-renews", PlusStatus.Renews(), dark = true)

    @Test fun plusEndsLight() = plusSection("plus-ends", PlusStatus.Ends(), dark = false)

    @Test fun plusEndsDark() = plusSection("plus-ends", PlusStatus.Ends(), dark = true)

    @Test fun plusPendingLight() = plusSection("plus-pending", PlusStatus.Pending, dark = false)

    @Test fun plusPendingDark() = plusSection("plus-pending", PlusStatus.Pending, dark = true)

    @Test
    @Config(qualifiers = "w412dp-h2540dp-notnight-xhdpi")
    fun settingsThemeDarkOnALightDevice() {
        val profile = Profile("Maya", Friend.HARE, theme = Profile.Theme.DARK)
        compose.setContent {
            HopTalesTheme(theme = profile.theme) {
                SettingsContent(
                    SettingsState(childName = "Maya", profile = profile, journey = Journey.starting(Friend.HARE)),
                    SettingsActions(),
                )
            }
        }
        compose.onRoot().captureRoboImage("src/test/screenshots/settings-theme-dark.png", options)
    }

    @Test fun introNight() = intro("intro-night", time = 0.0)

    @Test fun introSunrise() = intro("intro-sunrise", time = IntroTimeline.SUNRISE + IntroTimeline.SUNRISE_LENGTH / 2)

    @Test fun introTitle() = intro("intro-title", time = 5.2)

    private fun intro(name: String, time: Double) {
        val art = IntroArt.load(app.assets)
        compose.setContent {
            HopTalesTheme { IntroContent(art, time = { time }, showsTitle = true) }
        }
        compose.onRoot().captureRoboImage("src/test/screenshots/$name.png", options)
    }

    private fun onboardingWelcome(dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) { OnboardingContent(OnboardingState(isWelcoming = true), OnboardingActions()) }
        }
        compose.onRoot().captureRoboImage(path("onboarding-welcome", dark), options)
    }

    private fun onboarding(step: OnboardingStep, dark: Boolean) {
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

    private fun plusSection(name: String, status: PlusStatus, dark: Boolean, nothingToRestore: Boolean = false) {
        val profile = Profile("Maya", Friend.HARE, Profile.Accent.CANADIAN)
        compose.setContent {
            HopTalesTheme(dark = dark) {
                SettingsContent(
                    SettingsState(
                        childName = "Maya",
                        profile = profile,
                        journey = Journey.starting(Friend.HARE),
                        plusStatus = status,
                        foundNothingToRestore = nothingToRestore,
                    ),
                    SettingsActions(),
                )
            }
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    private fun settings(dark: Boolean) {
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
                        speechLogOn = true,
                        speechLogLines = 42,
                    ),
                    SettingsActions(),
                )
            }
        }
        compose.onRoot().captureRoboImage(path("settings", dark), options)
    }

    private val midway = Progress(
        stars = 56,
        completedSentences = mapOf("meadow-walk" to 6, "golden-hour" to 3),
        journey = Journey.starting(Friend.HARE),
    )

    private fun home(name: String, progress: Progress, dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) {
                HomeScreen(library = app.library, progress = progress, onStory = {}, childName = "Maya", hour = 9)
            }
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    private val newQuestion = ParentGateState(seed = 1, round = 1, entry = "4")

    private fun homeLocked(dark: Boolean) {
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

    private fun homeLockedLevels(dark: Boolean) {
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

    private fun lockedCard(dark: Boolean) {
        val locked = app.library.stories(Friend.HARE.level)[1]
        val standing = StoryStanding.of(locked, Progress(completedSentences = mapOf(locked.id to 4)))
        compose.setContent {
            HopTalesTheme(dark = dark) { LockedStoryScreen(standing, FakePlusSource(), onDone = {}) }
        }
        compose.onRoot().captureRoboImage(path("locked-card", dark), options)
    }

    private fun parentGate(name: String, gate: ParentGateState, dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) { ParentGate(onPassed = {}, onClose = {}, initial = gate) }
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    private fun paywall(name: String, plus: FakePlusSource, dark: Boolean, onboarding: Boolean = false) {
        compose.setContent {
            HopTalesTheme(dark = dark) { Paywall(plus, onClose = {}, onboarding = onboarding, live = false) }
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    private fun paywallPending(dark: Boolean) {
        compose.setContent {
            HopTalesTheme(dark = dark) { Paywall(FakePlusSource(outcome = PurchaseOutcome.PENDING), onClose = {}, live = false) }
        }
        compose.onNodeWithContentDescription("Yearly", substring = true).performClick()
        compose.onRoot().captureRoboImage(path("paywall-pending", dark), options)
    }

    private fun basketFull(dark: Boolean) {
        app.progressStore.save(Progress(baskets = mapOf(Friend.HARE to Basket(inBasket = 3))))
        storyFinished(dark, name = "basket-full")
    }

    private fun journeyMap(dark: Boolean) {
        val journey = Journey.starting(Friend.HARE).copy(steps = 150.0)
        compose.setContent {
            HopTalesTheme(dark = dark) { JourneyMapScreen(app.library, journey, onFriend = {}, onBigStory = {}, onDone = {}) }
        }
        compose.onRoot().captureRoboImage(path("journey-map", dark), options)
    }

    private fun friends(dark: Boolean) {
        val progress = Progress(
            journey = Journey.starting(Friend.HARE).copy(steps = 164.0),
            baskets = mapOf(Friend.HARE to Basket(total = 64)),
        )
        compose.setContent {
            HopTalesTheme(dark = dark) { FriendsScreen(progress, app.wardrobe, onFriend = {}, onJourney = {}, onDone = {}) }
        }
        compose.onRoot().captureRoboImage(path("friends", dark), options)
    }

    private fun wardrobe(dark: Boolean) {
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

    private fun book(dark: Boolean) {
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

    private fun reading(dark: Boolean) {
        showReading(dark)
        compose.onRoot().captureRoboImage(path("reading", dark), options)
    }

    private fun moment(name: String, id: String, sentence: Int, word: Int, dark: Boolean = false, soundButtons: Boolean = false) {
        val story = app.library[id]!!
        if (soundButtons) app.profileStore.save(Profile("Maya", soundButtons = true))
        midPage(name, story, story.sentences.take(sentence).sumOf { it.words.size } + word, dark)
    }

    private fun mood(sky: Sky, weather: Weather) {
        val story = story.copy(mood = Mood(sky, weather), sentences = story.sentences.map { it.copy(sky = null, weather = null) })
        midPage("mood-${sky.name.lowercase()}-${weather.name.lowercase()}", story)
    }

    private fun world(friend: Friend) {
        midPage("world-${friend.key}", app.library["meadow-walk"]!!.copy(level = friend.level), words = 0)
    }

    private fun midPage(name: String, story: Story, words: Int = 3, dark: Boolean = false) {
        showReading(dark, story)
        repeat(words) {
            compose.onNodeWithText("Read “", substring = true).performClick()
            compose.waitForIdle()
        }
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    private fun storyFinished(dark: Boolean, name: String = "story-finished", story: Story = this.story) {
        showReading(dark, story)
        readToTheEnd()
        compose.onRoot().captureRoboImage(path(name, dark), options)
    }

    private fun readToTheEnd() {
        val hear = compose.onNodeWithText("Read “", substring = true)
        while (hear.exists()) {
            hear.performClick()
            compose.waitForIdle()
        }
    }

    private fun challengeTip(dark: Boolean) {
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

    private fun triedItOn(dark: Boolean) {
        app.progressStore.save(Progress(baskets = mapOf(Friend.HARE to Basket(inBasket = 3))))
        showReading(dark)
        readToTheEnd()
        compose.onNodeWithContentDescription("A present. Double tap to open it.").performClick()
        compose.waitForIdle()
        compose.onNodeWithText("Try it on").performClick()
        compose.waitForIdle()
        compose.onRoot().captureRoboImage(path("tried-it-on", dark), options)
    }

    @Test
    fun backToMyStoriesAfterLevelOneGoesHome() {
        var done = 0
        finishLevelOne(dark = false) { done += 1 }
        compose.onNodeWithText("Ask a grown-up").assertDoesNotExist()
        compose.onNodeWithText("Back to my stories").performClick()
        compose.waitForIdle()
        assertEquals(1, done)
    }

    @Test
    fun aNewFriendLeadsBackToMyStoriesNotIntoTheirFirstStory() {
        var done = 0
        compose.setContent {
            HopTalesTheme { ReadingScreen(story = app.library["skip-big-story"]!!, onDone = { done += 1 }) }
        }
        compose.waitForIdle()
        readToTheEnd()
        compose.onNodeWithText("Go to", substring = true).assertDoesNotExist()
        compose.onNodeWithText("Back to my stories").performClick()
        compose.waitForIdle()
        assertEquals(1, done)
    }

    private fun finishLevelOne(dark: Boolean, onDone: () -> Unit = {}) {
        val levelOne = app.library.stories(Friend.BUNNY.level)
        app.progressStore.save(Progress(completedSentences = levelOne.associate { it.id to it.sentences.size }))
        compose.setContent {
            HopTalesTheme(dark = dark) { ReadingScreen(story = levelOne.first(), onDone = onDone, locksStories = true) }
        }
        compose.waitForIdle()
        readToTheEnd()
    }

    private fun levelOneFinished(dark: Boolean) {
        finishLevelOne(dark)
        compose.onNodeWithText("You finished Level 1!").assertExists()
        compose.onNodeWithContentDescription("Skip is waiting. Words like ship, duck, frog.").assertExists()
        compose.onNodeWithText("New friends are waiting on your stories page.").assertExists()
        compose.onNodeWithText("Back to my stories").assertExists()
        compose.onRoot().captureRoboImage(path("level-one-finished", dark), options)
    }

    private fun newFriend(dark: Boolean) {
        storyFinished(dark, name = "new-friend", story = app.library["skip-big-story"]!!)
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
