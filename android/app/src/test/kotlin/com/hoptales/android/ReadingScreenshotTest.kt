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
class ReadingScreenshotTest : ScreenshotFixture() {
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
}
