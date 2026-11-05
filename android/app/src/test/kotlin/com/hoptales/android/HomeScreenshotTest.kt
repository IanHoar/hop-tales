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
class HomeScreenshotTest : ScreenshotFixture() {
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

    @Test
    @Config(qualifiers = "w412dp-h2540dp-xhdpi")
    fun settingsLight() = settings(dark = false)

    @Test
    @Config(qualifiers = "w412dp-h2540dp-xhdpi")
    fun settingsDark() = settings(dark = true)

    @Test fun plusFreeLight() = plusSection("plus-free", PlusStatus.Free, dark = false)

    @Test fun plusFreeDark() = plusSection("plus-free", PlusStatus.Free, dark = true)

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
}
