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
class OnboardingScreenshotTest : ScreenshotFixture() {
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
}
