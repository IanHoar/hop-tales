package com.hoptales.android

import android.graphics.Color
import android.media.AudioManager
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.dp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.intro.IntroScreen
import com.hoptales.android.onboarding.OnboardingScreen
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.android.settings.SettingsScreen
import com.hoptales.android.world.IntroArt
import com.hoptales.android.world.IntroLayout
import com.hoptales.android.world.IntroTimeline
import com.hoptales.content.Story
import com.hoptales.onboarding.OnboardingState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.Locale
import androidx.compose.ui.graphics.Color as ComposeColor

class MainActivity : ComponentActivity() {
    private var introArt by mutableStateOf<IntroArt?>(null)
    private var introDone by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        val splash = installSplashScreen()
        super.onCreate(savedInstanceState)
        introDone = savedInstanceState?.getBoolean(INTRO_DONE) ?: false
        splash.setKeepOnScreenCondition { introArt == null && !introDone }
        splash.setOnExitAnimationListener { view ->
            view.view.animate().alpha(0f).setDuration(SPLASH_FADE_MILLIS).withEndAction(view::remove).start()
        }
        lifecycleScope.launch { introArt = withContext(Dispatchers.IO) { IntroArt.load(assets) } }
        enableEdgeToEdge(SystemBarStyle.dark(Color.TRANSPARENT), SystemBarStyle.dark(Color.TRANSPARENT))
        volumeControlStream = AudioManager.STREAM_MUSIC
        val app = application as HopTalesApplication
        finishAnsweredDraft(app)
        val reduceMotion = Settings.Global.getFloat(contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
        setContent {
            HopTalesTheme {
                LaunchedEffect(introDone) { if (introDone) enableEdgeToEdge() }
                Entry(
                    introArt = introArt,
                    introDone = introDone,
                    reduceMotion = reduceMotion,
                    onIntroFinished = { introDone = true },
                ) { Destination(app) }
            }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(INTRO_DONE, introDone)
    }

    private fun finishAnsweredDraft(app: HopTalesApplication) {
        if (app.profileStore.load() != null) return
        val draft = app.profileStore.loadDraft()?.let(OnboardingState::resuming) ?: return
        if (draft.isComplete) app.profileStore.save(draft.profile(Locale.getDefault().country))
    }

    private companion object {
        const val INTRO_DONE = "introDone"
        const val SPLASH_FADE_MILLIS = 300L
    }
}

@Composable
private fun Entry(
    introArt: IntroArt?,
    introDone: Boolean,
    reduceMotion: Boolean,
    onIntroFinished: () -> Unit,
    destination: @Composable () -> Unit,
) {
    val handover by animateFloatAsState(
        targetValue = if (introDone) 1f else 0f,
        animationSpec = if (reduceMotion) {
            tween(IntroTimeline.REDUCED_HANDOVER_MILLIS, easing = IntroTimeline.easeInOut)
        } else {
            tween(IntroTimeline.HANDOVER_MILLIS, easing = IntroTimeline.handover)
        },
        label = "handover",
    )
    val backdrop = if (introDone) Modifier else Modifier.background(ComposeColor(IntroLayout.NIGHT))
    Box(Modifier.fillMaxSize().then(backdrop)) {
        Box(
            Modifier
                .fillMaxSize()
                .graphicsLayer {
                    alpha = handover
                    translationY = if (reduceMotion) 0f else (1 - handover) * IntroTimeline.HANDOVER_RISE.dp.toPx()
                }
                .then(if (introDone) Modifier else Modifier.clearAndSetSemantics {}),
        ) { destination() }
        if (!introDone || handover < 1f) {
            IntroScreen(
                art = introArt,
                reduceMotion = reduceMotion,
                onFinished = onIntroFinished,
                modifier = Modifier.graphicsLayer { alpha = 1 - handover },
            )
        }
    }
}

@Composable
private fun Destination(app: HopTalesApplication) {
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

private sealed interface Route {
    data object Onboarding : Route
    data object Home : Route
    data object Settings : Route
    data class Reading(val story: Story) : Route
}
