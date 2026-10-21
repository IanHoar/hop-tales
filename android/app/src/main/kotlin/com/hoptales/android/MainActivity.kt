package com.hoptales.android

import android.media.AudioManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.onboarding.OnboardingScreen
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.android.settings.SettingsScreen
import com.hoptales.content.Story
import com.hoptales.onboarding.OnboardingState
import java.util.Locale

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        volumeControlStream = AudioManager.STREAM_MUSIC
        val app = application as HopTalesApplication
        finishAnsweredDraft(app)
        setContent {
            HopTalesTheme {
                var storyID by rememberSaveable { mutableStateOf<String?>(null) }
                var isShowingSettings by rememberSaveable { mutableStateOf(false) }
                var visit by rememberSaveable { mutableIntStateOf(0) }
                val progress by app.progressStore.progress.collectAsStateWithLifecycle()
                val profile by app.profileStore.profile.collectAsStateWithLifecycle()
                val route = when {
                    profile == null -> Route.Onboarding
                    isShowingSettings -> Route.Settings
                    else -> storyID?.let(app.library::get)?.let(Route::Reading) ?: Route.Home
                }
                AnimatedContent(
                    targetState = route,
                    transitionSpec = { fadeIn() togetherWith fadeOut() },
                    label = "route",
                ) { target ->
                    when (target) {
                        Route.Onboarding -> OnboardingScreen(key = "onboarding-$visit")

                        Route.Settings -> SettingsScreen(key = "settings-$visit", onDone = { isShowingSettings = false })

                        Route.Home -> HomeScreen(
                            library = app.library,
                            progress = progress,
                            onStory = { storyID = it.id },
                            childName = profile?.childName,
                            onGrownUps = {
                                visit += 1
                                isShowingSettings = true
                            },
                        )

                        is Route.Reading -> ReadingScreen(story = target.story, onDone = { storyID = null })
                    }
                }
            }
        }
    }

    private fun finishAnsweredDraft(app: HopTalesApplication) {
        if (app.profileStore.load() != null) return
        val draft = app.profileStore.loadDraft()?.let(OnboardingState::resuming) ?: return
        if (draft.isComplete) app.profileStore.save(draft.profile(Locale.getDefault().country))
    }
}

private sealed interface Route {
    data object Onboarding : Route
    data object Home : Route
    data object Settings : Route
    data class Reading(val story: Story) : Route
}
