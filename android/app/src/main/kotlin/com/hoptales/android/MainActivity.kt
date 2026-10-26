package com.hoptales.android

import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.graphics.Color
import android.media.AudioManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import com.hoptales.android.design.FoldAware
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.design.Metrics
import com.hoptales.android.design.reducesMotion
import com.hoptales.android.home.BookScreen
import com.hoptales.android.home.FriendsScreen
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.home.JourneyMapScreen
import com.hoptales.android.home.LockedLevelScreen
import com.hoptales.android.home.LockedStoryScreen
import com.hoptales.android.home.WardrobeScreen
import com.hoptales.android.intro.IntroScreen
import com.hoptales.android.onboarding.OnboardingScreen
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.android.settings.SettingsScreen
import com.hoptales.android.world.IntroArt
import com.hoptales.android.world.IntroLayout
import com.hoptales.android.world.IntroTimeline
import com.hoptales.android.world.LocalLooks
import com.hoptales.content.Friend
import com.hoptales.content.Plus
import com.hoptales.content.Profile
import com.hoptales.content.Story
import com.hoptales.content.StoryStanding
import com.hoptales.content.tapping
import com.hoptales.content.undressing
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
        val restored = savedInstanceState?.takeIf { processStarted }
        processStarted = true
        super.onCreate(restored)
        introDone = restored?.getBoolean(INTRO_DONE) ?: false
        splash.setKeepOnScreenCondition { introArt == null && !introDone }
        splash.setOnExitAnimationListener { view ->
            view.view.animate().alpha(0f).setDuration(SPLASH_FADE_MILLIS).withEndAction(view::remove).start()
        }
        lifecycleScope.launch { introArt = withContext(Dispatchers.IO) { IntroArt.load(assets) } }
        holdPhonesUpright(resources.configuration)
        enableEdgeToEdge(SystemBarStyle.dark(Color.TRANSPARENT), SystemBarStyle.dark(Color.TRANSPARENT))
        volumeControlStream = AudioManager.STREAM_MUSIC
        val app = application as HopTalesApplication
        finishAnsweredDraft(app)
        val reduceMotion = reducesMotion()
        setContent {
            val profile by app.profileStore.profile.collectAsStateWithLifecycle()
            val looks by app.looks.sheets.collectAsStateWithLifecycle()
            var keptTheme by remember { mutableStateOf(Profile.Theme.DEVICE) }
            LaunchedEffect(profile?.theme) { profile?.theme?.let { keptTheme = it } }
            val dark = (profile?.theme ?: keptTheme).isDark(isSystemInDarkTheme())
            HopTalesTheme(dark = dark) {
                LaunchedEffect(introDone, dark) {
                    if (introDone) {
                        enableEdgeToEdge(
                            SystemBarStyle.auto(Color.TRANSPARENT, Color.TRANSPARENT) { dark },
                            SystemBarStyle.auto(LIGHT_SCRIM, DARK_SCRIM) { dark },
                        )
                    }
                }
                CompositionLocalProvider(LocalLooks provides looks) {
                    FoldAware {
                        Entry(
                            introArt = introArt,
                            introDone = introDone,
                            reduceMotion = reduceMotion,
                            onIntroFinished = { introDone = true },
                        ) { Destination(app) }
                    }
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        (application as HopTalesApplication).plus.refresh()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        holdPhonesUpright(newConfig)
    }

    private fun holdPhonesUpright(configuration: Configuration) {
        val upright = configuration.smallestScreenWidthDp < Metrics.REGULAR_WIDTH
        val wanted = if (upright) ActivityInfo.SCREEN_ORIENTATION_PORTRAIT else ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        if (requestedOrientation != wanted) requestedOrientation = wanted
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(INTRO_DONE, introDone)
    }

    private fun finishAnsweredDraft(app: HopTalesApplication) {
        app.profileStore.load()?.let {
            app.progressStore.startJourney(it.startingFriend)
            return
        }
        val draft = app.profileStore.loadDraft()?.let(OnboardingState::resuming) ?: return
        if (!draft.isComplete) return
        val profile = draft.profile(Locale.getDefault().country)
        app.profileStore.save(profile)
        app.progressStore.startJourney(profile.startingFriend)
    }

    private companion object {
        var processStarted = false
        const val INTRO_DONE = "introDone"
        const val SPLASH_FADE_MILLIS = 300L
        val LIGHT_SCRIM = Color.argb(0xE6, 0xFF, 0xFF, 0xFF)
        val DARK_SCRIM = Color.argb(0x80, 0x1B, 0x1B, 0x1B)
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
    var sheet by rememberSaveable { mutableStateOf<String?>(null) }
    var trying by rememberSaveable { mutableStateOf<String?>(null) }
    var isShowingSettings by rememberSaveable { mutableStateOf(false) }
    var visit by rememberSaveable { mutableIntStateOf(0) }
    var fromOnboarding by remember { mutableStateOf(false) }
    val progress by app.progressStore.progress.collectAsStateWithLifecycle()
    val profile by app.profileStore.profile.collectAsStateWithLifecycle()
    val isPlus by app.plus.isPlus.collectAsStateWithLifecycle()
    val isLocked: (Story) -> Boolean = { Plus.isLocked(it, isPlus, BuildConfig.PLUS_LOCKS_STORIES) }
    val open: (Story) -> Unit = {
        trying = null
        if (isLocked(it)) {
            storyID = null
            sheet = Sheet.locked(it)
        } else {
            storyID = it.id
        }
    }
    val route = when {
        profile == null -> Route.Onboarding
        else -> storyID?.let(app.library::get)?.let(Route::Reading) ?: Route.Home
    }
    val overlay = when {
        route is Route.Reading -> trying
        route != Route.Home -> null
        isShowingSettings -> Sheet.SETTINGS
        else -> sheet
    }
    val closeSheet: () -> Unit = {
        if (route is Route.Reading) {
            trying = null
        } else {
            sheet = null
        }
    }
    val friend = progress.journey.activeFriend
    Box(Modifier.fillMaxSize()) {
        AnimatedContent(
            targetState = route,
            transitionSpec = { routeTransition(initialState, targetState) },
            modifier = Modifier.fillMaxSize().then(if (overlay != null) Modifier.clearAndSetSemantics {} else Modifier),
            label = "route",
        ) { target ->
            when (target) {
                Route.Onboarding -> {
                    LaunchedEffect(Unit) { fromOnboarding = true }
                    OnboardingScreen(key = "onboarding-$visit") { sheet = null }
                }

                is Route.Reading -> ReadingScreen(
                    story = target.story,
                    onDone = {
                        trying = null
                        storyID = null
                    },
                    onTryItOn = { trying = Sheet.wardrobe(it) },
                )

                Route.Home -> {
                    LaunchedEffect(Unit) { fromOnboarding = false }
                    HomeScreen(
                        library = app.library,
                        progress = progress,
                        onStory = { storyID = it.id },
                        childName = profile?.childName,
                        onGrownUps = {
                            visit += 1
                            isShowingSettings = true
                        },
                        onJourney = { sheet = Sheet.JOURNEY },
                        onFriends = { sheet = Sheet.FRIENDS },
                        onWardrobe = { sheet = Sheet.wardrobe(friend) },
                        onBook = { sheet = Sheet.book(friend) },
                        entrance = fromOnboarding,
                        covered = overlay != null,
                        isLocked = isLocked,
                        onLockedStory = { sheet = Sheet.locked(it) },
                        lockedLevels = Plus.lockedLevels(friend.level, app.library, isPlus, BuildConfig.PLUS_LOCKS_STORIES),
                        onLockedLevel = { sheet = Sheet.LOCKED_LEVEL },
                    )
                }
            }
        }
        SheetOverlay(overlay) { target ->
            when {
                target == Sheet.SETTINGS -> SettingsScreen(key = "settings-$visit", onDone = { isShowingSettings = false })

                target == Sheet.LOCKED_LEVEL -> LockedLevelScreen(app.plus, onDone = { sheet = null })

                target == Sheet.JOURNEY -> JourneyMapScreen(
                    library = app.library,
                    journey = progress.journey,
                    onFriend = { tapped -> app.progressStore.update { it.copy(journey = it.journey.readingWith(tapped)) } },
                    onBigStory = {
                        sheet = null
                        open(it)
                    },
                    onDone = { sheet = null },
                )

                target == Sheet.FRIENDS -> FriendsScreen(
                    progress = progress,
                    wardrobe = app.wardrobe,
                    onFriend = { tapped -> app.progressStore.update { it.copy(journey = it.journey.readingWith(tapped)) } },
                    onJourney = { sheet = Sheet.JOURNEY },
                    onDone = { sheet = null },
                )

                target.startsWith(Sheet.LOCKED) -> {
                    val locked = app.library[target.removePrefix(Sheet.LOCKED)]
                    if (locked != null) {
                        LockedStoryScreen(StoryStanding.of(locked, progress), app.plus, onDone = { sheet = null })
                    }
                }

                target.startsWith(Sheet.WARDROBE) -> {
                    val dressing = Sheet.friend(target) ?: friend
                    WardrobeScreen(
                        friend = dressing,
                        progress = progress,
                        wardrobe = app.wardrobe,
                        onItem = { item -> app.progressStore.update { it.tapping(item, dressing, app.wardrobe) } },
                        onJustMe = { app.progressStore.update { it.undressing(dressing) } },
                        onDone = closeSheet,
                    )
                }

                else -> BookScreen(
                    library = app.library,
                    progress = progress,
                    friend = Sheet.friend(target) ?: friend,
                    onFriend = { sheet = Sheet.book(it) },
                    onDone = { sheet = null },
                )
            }
        }
        BackHandler(enabled = overlay != null && overlay != Sheet.SETTINGS, onBack = closeSheet)
    }
}

@Composable
private fun SheetOverlay(sheet: String?, content: @Composable (String) -> Unit) {
    val scrim by animateFloatAsState(if (sheet != null) SCRIM_ALPHA else 0f, tween(SHEET_FADE_MILLIS), label = "scrim")
    if (scrim > 0f) {
        Box(
            Modifier
                .fillMaxSize()
                .background(ComposeColor.Black.copy(alpha = scrim))
                .then(
                    if (sheet != null) {
                        Modifier.clickable(remember { MutableInteractionSource() }, indication = null, onClick = {})
                    } else {
                        Modifier
                    },
                ),
        )
    }
    val slide =
        spring(dampingRatio = Spring.DampingRatioNoBouncy, stiffness = Spring.StiffnessMediumLow, visibilityThreshold = IntOffset(1, 1))
    AnimatedContent(
        targetState = sheet,
        transitionSpec = {
            when {
                initialState == null -> slideInVertically(slide) { it } togetherWith ExitTransition.None
                targetState == null -> EnterTransition.None togetherWith slideOutVertically(slide) { it }
                else -> fadeIn(tween(SHEET_FADE_MILLIS)) togetherWith fadeOut(tween(SHEET_FADE_MILLIS))
            }
        },
        modifier = Modifier.fillMaxSize(),
        label = "sheet",
    ) { target ->
        if (target == null) {
            Box(Modifier.fillMaxSize())
        } else {
            BoxWithConstraints(
                Modifier
                    .fillMaxSize()
                    .windowInsetsPadding(WindowInsets.statusBars)
                    .padding(top = SHEET_GAP),
            ) {
                if (Metrics.isRegular(maxWidth.value, maxHeight.value)) {
                    Box(
                        Modifier
                            .align(Alignment.Center)
                            .size(minOf(maxWidth, FORM_SHEET_WIDTH), minOf(maxHeight - SHEET_GAP, FORM_SHEET_HEIGHT))
                            .clip(RoundedCornerShape(SHEET_CORNER)),
                    ) { content(target) }
                } else {
                    Box(Modifier.fillMaxSize().clip(RoundedCornerShape(topStart = SHEET_CORNER, topEnd = SHEET_CORNER))) {
                        content(target)
                    }
                }
            }
        }
    }
}

private const val SCRIM_ALPHA = 0.25f
private const val SHEET_FADE_MILLIS = 250
private val SHEET_GAP = 10.dp
private val SHEET_CORNER = 28.dp
private val FORM_SHEET_WIDTH = 540.dp
private val FORM_SHEET_HEIGHT = 620.dp

private fun routeTransition(from: Route, to: Route): ContentTransform {
    val push = tween<IntOffset>(PUSH_MILLIS, easing = FastOutSlowInEasing)
    return when {
        to is Route.Reading -> slideInHorizontally(push) { it } togetherWith slideOutHorizontally(push) { -it / PARALLAX }

        from is Route.Reading && to == Route.Home -> {
            (
                slideInHorizontally(push) {
                    -it / PARALLAX
                } togetherWith slideOutHorizontally(push) { it }
                ).apply { targetContentZIndex = -1f }
        }

        else -> fadeIn(tween(HANDOFF_MILLIS, easing = IntroTimeline.easeInOut)) togetherWith
            fadeOut(tween(HANDOFF_MILLIS, easing = IntroTimeline.easeInOut))
    }
}

private const val PUSH_MILLIS = 350
private const val PARALLAX = 3
private const val HANDOFF_MILLIS = 450

private sealed interface Route {
    data object Onboarding : Route
    data object Home : Route
    data class Reading(val story: Story) : Route
}

private object Sheet {
    const val SETTINGS = "settings"
    const val JOURNEY = "journey"
    const val FRIENDS = "friends"
    const val LOCKED_LEVEL = "locked-level"
    const val WARDROBE = "wardrobe:"
    const val BOOK = "book:"
    const val LOCKED = "locked:"

    fun wardrobe(friend: Friend) = WARDROBE + friend.key

    fun book(friend: Friend) = BOOK + friend.key

    fun locked(story: Story) = LOCKED + story.id

    fun friend(sheet: String): Friend? = Friend.entries.firstOrNull { sheet.endsWith(":${it.key}") }
}
