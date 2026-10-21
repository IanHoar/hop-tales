package com.hoptales.android

import android.Manifest
import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.window.layout.FoldingFeature
import androidx.window.testing.layout.FoldingFeature
import androidx.window.testing.layout.TestWindowLayoutInfo
import androidx.window.testing.layout.WindowLayoutInfoPublisherRule
import com.github.takahirom.roborazzi.RoborazziOptions
import com.github.takahirom.roborazzi.captureRoboImage
import com.hoptales.android.design.FoldAware
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.BookScreen
import com.hoptales.android.home.FriendsScreen
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.home.JourneyMapScreen
import com.hoptales.android.home.WardrobeScreen
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
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import android.graphics.Rect as WindowRect

private const val TABLET_PORTRAIT = "w800dp-h1280dp-port-mdpi"
private const val TABLET_LANDSCAPE = "w1280dp-h800dp-land-mdpi"
private const val FOLD_OPEN = "w841dp-h701dp-land-mdpi"
private const val FOLD_OPEN_PORTRAIT = "w701dp-h841dp-port-mdpi"
private const val FOLD_OUTER = "w411dp-h797dp-port-mdpi"

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36])
class LargeScreenshotTest {
    @get:Rule(order = 0)
    val publisher = WindowLayoutInfoPublisherRule()

    @get:Rule(order = 1)
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
    @Config(qualifiers = TABLET_PORTRAIT)
    fun readingTabletPortrait() = reading("tablet-portrait")

    @Test
    @Config(qualifiers = TABLET_PORTRAIT)
    fun homeTabletPortrait() = home("tablet-portrait")

    @Test
    @Config(qualifiers = TABLET_PORTRAIT)
    fun onboardingTabletPortrait() = onboarding(OnboardingStep.FRIEND, "tablet-portrait")

    @Test
    @Config(qualifiers = TABLET_PORTRAIT)
    fun settingsTabletPortrait() = settings("tablet-portrait")

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun readingTabletLandscape() = reading("tablet-landscape")

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun readingTabletLandscapeDark() = reading("tablet-landscape", dark = true)

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun storyFinishedTabletLandscape() = storyFinished("tablet-landscape")

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun homeTabletLandscape() = home("tablet-landscape")

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun homeTabletLandscapeDark() = home("tablet-landscape", dark = true)

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun onboardingTabletLandscape() = onboarding(OnboardingStep.FRIEND, "tablet-landscape")

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun settingsTabletLandscape() = settings("tablet-landscape")

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun journeyMapTabletLandscape() = shoot("journey-map-tablet-landscape") {
        JourneyMapScreen(app.library, Journey.starting(Friend.HARE).copy(steps = 150.0), onFriend = {}, onBigStory = {}, onDone = {})
    }

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun friendsTabletLandscape() {
        val progress = Progress(
            journey = Journey.starting(Friend.HARE).copy(steps = 164.0),
            baskets = mapOf(Friend.HARE to Basket(total = 64)),
        )
        shoot("friends-tablet-landscape") { FriendsScreen(progress, app.wardrobe, onFriend = {}, onJourney = {}, onDone = {}) }
    }

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun wardrobeTabletLandscape() {
        val worn = app.wardrobe.items(Friend.BUNNY)[1]
        val progress = Progress(
            journey = Journey.starting(Friend.FROG),
            baskets = mapOf(Friend.BUNNY to Basket(filled = 3)),
            outfits = mapOf(Friend.BUNNY to mapOf(worn.slot to worn.id)),
        )
        shoot("wardrobe-tablet-landscape") {
            WardrobeScreen(Friend.BUNNY, progress, app.wardrobe, onItem = {}, onJustMe = {}, onDone = {})
        }
    }

    @Test
    @Config(qualifiers = TABLET_LANDSCAPE)
    fun bookTabletLandscape() {
        val progress = Progress(
            completedSentences = mapOf("golden-hour" to 6, "skip-and-frog" to 6),
            journey = Journey.starting(Friend.HARE),
            baskets = mapOf(Friend.HARE to Basket(total = 64, golden = 3)),
        )
        shoot("book-tablet-landscape") { BookScreen(app.library, progress, Friend.HARE, onFriend = {}, onDone = {}) }
    }

    @Test
    @Config(qualifiers = FOLD_OUTER)
    fun readingFoldOuter() = reading("fold-outer")

    @Test
    @Config(qualifiers = FOLD_OUTER)
    fun homeFoldOuter() = home("fold-outer")

    @Test
    @Config(qualifiers = FOLD_OPEN)
    fun readingFoldOpen() = reading("fold-open")

    @Test
    @Config(qualifiers = FOLD_OPEN)
    fun homeFoldOpen() = home("fold-open")

    @Test
    @Config(qualifiers = FOLD_OPEN)
    fun onboardingFoldOpen() = onboarding(OnboardingStep.FRIEND, "fold-open")

    @Test
    @Config(qualifiers = FOLD_OPEN)
    fun readingBook() = reading("book", fold = FoldingFeature.Orientation.VERTICAL)

    @Test
    @Config(qualifiers = FOLD_OPEN)
    fun homeBook() = home("book", fold = FoldingFeature.Orientation.VERTICAL)

    @Test
    @Config(qualifiers = FOLD_OPEN)
    fun homeBookDark() = home("book", dark = true, fold = FoldingFeature.Orientation.VERTICAL)

    @Test
    @Config(qualifiers = FOLD_OPEN)
    fun onboardingBackupBook() = onboarding(OnboardingStep.BACKUP, "book", fold = FoldingFeature.Orientation.VERTICAL)

    @Test
    @Config(qualifiers = FOLD_OPEN)
    fun onboardingNameBook() = onboarding(OnboardingStep.NAME, "book", fold = FoldingFeature.Orientation.VERTICAL)

    @Test
    @Config(qualifiers = FOLD_OPEN)
    fun onboardingFriendBook() = onboarding(OnboardingStep.FRIEND, "book", fold = FoldingFeature.Orientation.VERTICAL)

    @Test
    @Config(qualifiers = FOLD_OPEN_PORTRAIT)
    fun readingTabletop() = reading("tabletop", fold = FoldingFeature.Orientation.HORIZONTAL)

    @Test
    @Config(qualifiers = FOLD_OPEN_PORTRAIT)
    fun homeTabletop() = home("tabletop", fold = FoldingFeature.Orientation.HORIZONTAL)

    @Test
    @Config(qualifiers = FOLD_OPEN_PORTRAIT)
    fun onboardingBackupTabletop() = onboarding(OnboardingStep.BACKUP, "tabletop", fold = FoldingFeature.Orientation.HORIZONTAL)

    @Test
    @Config(qualifiers = FOLD_OPEN_PORTRAIT)
    fun onboardingNameTabletop() = onboarding(OnboardingStep.NAME, "tabletop", fold = FoldingFeature.Orientation.HORIZONTAL)

    @Test
    @Config(qualifiers = FOLD_OPEN_PORTRAIT)
    fun onboardingFriendTabletop() = onboarding(OnboardingStep.FRIEND, "tabletop", fold = FoldingFeature.Orientation.HORIZONTAL)

    private fun halfOpen(orientation: FoldingFeature.Orientation) {
        val metrics = app.resources.displayMetrics
        val window = WindowRect(0, 0, metrics.widthPixels, metrics.heightPixels)
        val hinge = FoldingFeature(window, size = 0, state = FoldingFeature.State.HALF_OPENED, orientation = orientation)
        publisher.overrideWindowLayoutInfo(TestWindowLayoutInfo(listOf(hinge)))
    }

    private fun show(dark: Boolean, fold: FoldingFeature.Orientation?, content: @Composable () -> Unit) {
        compose.setContent { HopTalesTheme(dark = dark) { FoldAware(content) } }
        if (fold != null) halfOpen(fold)
        compose.waitForIdle()
    }

    private fun shoot(name: String, dark: Boolean = false, fold: FoldingFeature.Orientation? = null, content: @Composable () -> Unit) {
        show(dark, fold, content)
        capture(name, dark)
    }

    private fun capture(name: String, dark: Boolean) {
        compose.onRoot().captureRoboImage("src/test/screenshots/large/$name-${if (dark) "dark" else "light"}.png", options)
    }

    private fun reading(device: String, dark: Boolean = false, fold: FoldingFeature.Orientation? = null) =
        shoot("reading-$device", dark, fold) { ReadingScreen(story = story, onDone = {}) }

    private fun storyFinished(device: String) {
        show(dark = false, fold = null) { ReadingScreen(story = story, onDone = {}) }
        val hear = compose.onNodeWithText("Hear “", substring = true)
        while (hear.exists()) {
            hear.performClick()
            compose.waitForIdle()
        }
        capture("story-finished-$device", dark = false)
    }

    private fun home(device: String, dark: Boolean = false, fold: FoldingFeature.Orientation? = null) {
        val progress = Progress(
            stars = 56,
            completedSentences = mapOf("meadow-walk" to 6, "golden-hour" to 3),
            journey = Journey.starting(Friend.HARE),
        )
        shoot("home-$device", dark, fold) {
            HomeScreen(library = app.library, progress = progress, onStory = {}, childName = "Maya", hour = 9)
        }
    }

    private fun onboarding(step: OnboardingStep, device: String, fold: FoldingFeature.Orientation? = null) {
        val state = OnboardingState(
            step = step,
            backup = true,
            childName = "Maya",
            startingFriend = Friend.HARE.takeIf { step >= OnboardingStep.FRIEND },
        )
        shoot("onboarding-${step.name.lowercase()}-$device", fold = fold) { OnboardingContent(state, OnboardingActions()) }
    }

    private fun settings(device: String) {
        val profile = Profile("Maya", Friend.HARE, Profile.Accent.CANADIAN, soundButtons = true)
        shoot("settings-$device") {
            SettingsContent(
                SettingsState(childName = "Maya", profile = profile, journey = Journey.starting(Friend.HARE)),
                SettingsActions(),
            )
        }
    }

    private fun SemanticsNodeInteraction.exists(): Boolean = runCatching { fetchSemanticsNode() }.isSuccess

    private val options = RoborazziOptions(
        compareOptions = RoborazziOptions.CompareOptions(changeThreshold = 0.005f),
    )
}
