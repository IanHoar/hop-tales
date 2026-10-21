package com.hoptales.android.reading

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.hoptales.android.BuildConfig
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.BackChip
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.rememberReducedMotion
import com.hoptales.android.world.Art
import com.hoptales.android.world.HareSheet
import com.hoptales.android.world.HareSheets
import com.hoptales.android.world.MeadowGround
import com.hoptales.android.world.MeadowLayer
import com.hoptales.android.world.MeadowStars
import com.hoptales.android.world.SkyArt
import com.hoptales.android.world.SkyLayout
import com.hoptales.android.world.SkyWeather
import com.hoptales.android.world.StillDrops
import com.hoptales.android.world.WorldStyle
import com.hoptales.android.world.drawSky
import com.hoptales.android.world.drawWeather
import com.hoptales.android.world.rememberSkyLook
import com.hoptales.content.Friend
import com.hoptales.content.Story
import com.hoptales.content.StoryTreat
import com.hoptales.content.WordRef
import com.hoptales.reading.HopTarget
import com.hoptales.reading.PropCue
import com.hoptales.reading.PropKey
import com.hoptales.reading.PropTiming
import com.hoptales.reading.ReadingState
import com.hoptales.reading.StoryPropLayout
import kotlinx.coroutines.delay

@Composable
fun ReadingScreen(story: Story, onDone: () -> Unit, onStory: (Story) -> Unit = {}, onTryItOn: (Friend) -> Unit = {}) {
    val context = LocalContext.current
    val app = context.applicationContext as HopTalesApplication
    val owner = remember { ReadingOwner() }
    DisposableEffect(owner) { onDispose { owner.viewModelStore.clear() } }
    val model: ReadingViewModel = viewModel(owner) { ReadingViewModel(story, app) }
    val state by model.state.collectAsStateWithLifecycle()
    val listening by model.listening.collectAsStateWithLifecycle()
    var permission by remember {
        mutableStateOf(ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED)
    }
    val request = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        app.listeningPreferences.hasAskedForMicrophone = true
        permission = granted
        model.start(granted)
    }

    LifecycleStartEffect(permission) {
        model.start(permission)
        onStopOrDispose { model.stop() }
    }
    BackHandler { if (model.backTapped()) onDone() }

    val haptics = LocalHapticFeedback.current
    LaunchedEffect(state.recognised) {
        if (state.recognised != null) haptics.performHapticFeedback(HapticFeedbackType.SegmentTick)
    }
    LaunchedEffect(state.completionCount) {
        if (state.completionCount > 0) haptics.performHapticFeedback(HapticFeedbackType.Confirm)
    }

    val reduceMotion = rememberReducedMotion()
    var pickup by remember { mutableStateOf<StoryTreat?>(null) }
    var passed by remember { mutableStateOf(HopTarget(state.sentenceIndex, state.wordIndex)) }
    LaunchedEffect(state.sentenceIndex, state.wordIndex) {
        val old = passed
        passed = HopTarget(state.sentenceIndex, state.wordIndex)
        val treat = state.treat ?: return@LaunchedEffect
        if (reduceMotion || passed <= old || WordRef(old.sentence, old.word) != treat.word) return@LaunchedEffect
        delay(PathMarks.PICKUP_DELAY_MILLIS)
        pickup = treat
        delay(PathMarks.BASKET_HOLD_MILLIS)
        pickup = null
    }

    Box(Modifier.fillMaxSize()) {
        PathStage(state = state, wearing = model.look, soundButtons = model.soundButtons, onWordTapped = model::help)
        Box(Modifier.fillMaxSize().safeDrawingPadding().padding(horizontal = 12.dp, vertical = 4.dp)) {
            BackChip(Modifier.align(Alignment.TopStart)) { if (model.backTapped()) onDone() }
            AnimatedVisibility(
                pickup != null,
                Modifier.align(Alignment.TopEnd).padding(top = 8.dp, end = 4.dp),
                enter = fadeIn(),
                exit = fadeOut(),
            ) {
                pickup?.let { BasketChip(it) }
            }
            val word = state.currentWord
            if (BuildConfig.DEBUG && word != null) {
                Box(Modifier.align(Alignment.BottomCenter).padding(bottom = 6.dp)) { DebugHear(word.text, model::skipWord) }
            }
        }
        when (listening) {
            Listening.NeedsPermission -> AskToListen { request.launch(Manifest.permission.RECORD_AUDIO) }
            Listening.Denied, Listening.Unsupported -> ListeningUnavailable(listening, onBack = onDone)
            else -> Unit
        }
        AnimatedVisibility(state.isFinished, enter = fadeIn(), exit = fadeOut()) {
            StoryFinished(
                title = story.title,
                stars = (state.completed as? ReadingState.Completed.Story)?.stars ?: state.stars,
                readAgain = model::readAgain,
                done = onDone,
            )
        }
        AnimatedVisibility(state.isFinished, enter = fadeIn(), exit = fadeOut()) {
            JourneyPanel(
                state,
                onStory = onStory,
                onTryItOn = { friend ->
                    model.tryItOn(friend)
                    onTryItOn(friend)
                },
                dismiss = model::momentDismissed,
            )
        }
        AnimatedVisibility(state.isConfirmingStop, enter = fadeIn(), exit = fadeOut()) {
            StopReading(friend = story.friend.friendName, keepReading = model::keepReading, stop = onDone)
        }
    }
}

@Composable
private fun PathStage(state: ReadingState, wearing: String?, soundButtons: Boolean, onWordTapped: () -> Unit) {
    val context = LocalContext.current
    val reduceMotion = rememberReducedMotion()
    val palette = LocalPalette.current
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val measurer = rememberTextMeasurer()
    val friend = state.story.friend
    val layers = remember(friend) {
        MeadowLayer.entries.associateWith { Art.image(context.assets, it.asset(friend)) ?: Art.image(context.assets, "${it.prefix}-day") }
    }
    val skyArt = remember { SkyArt.load(context.assets) }
    val ground = remember(friend) {
        val name = if (Art.image(context.assets, MeadowLayer.NEAR.asset(friend)) != null) MeadowLayer.NEAR.asset(friend) else "near-day"
        MeadowGround.of(WorldStyle.of(friend), layers[MeadowLayer.NEAR], name)
    }
    val look = rememberSkyLook(state.mood, still = reduceMotion)
    val weather = remember { SkyWeather() }
    var skyTime by remember { mutableDoubleStateOf(0.0) }
    LaunchedEffect(state.mood) { weather.apply(state.mood, skyTime) }
    LaunchedEffect(reduceMotion) {
        if (reduceMotion) return@LaunchedEffect
        val origin = withFrameNanos { it } - (skyTime * 1e9).toLong()
        while (true) withFrameNanos { skyTime = (it - origin) / 1e9 }
    }
    val hare = remember(friend, wearing) {
        val sheets = HareSheets.of(friend)
        fun sheet(sheet: HareSheet) = wearing?.let { Art.image(context.assets, sheets.dressed(friend, it, sheet)) }
            ?: Art.image(context.assets, sheets.of(sheet).asset)
        HareArt(sheet(HareSheet.IDLE), sheet(HareSheet.HOP), sheets)
    }
    val marks = remember(state.story, state.treat) { MarkArt.load(context.assets, state.treat) }
    val props = (context.applicationContext as HopTalesApplication).props
    val propArt = remember(state.story) { PropArt.load(context.assets, state.story, props) }
    val position = HopTarget(state.sentenceIndex, state.wordIndex)
    var cues by remember(state.story) { mutableStateOf(emptyMap<PropKey, PropCue>()) }
    var cued by remember(state.story) { mutableStateOf<HopTarget?>(null) }
    var propTime by remember { mutableDoubleStateOf(0.0) }
    LaunchedEffect(state.story, position) {
        val backward = cued?.let { position < it } ?: false
        cues = PropTiming.cues(if (backward) emptyMap() else cues, state.story, position, System.nanoTime() / 1e9)
        cued = position
    }
    val cueing = cues.isNotEmpty()
    LaunchedEffect(reduceMotion, cueing) {
        if (reduceMotion || !cueing) return@LaunchedEffect
        while (true) withFrameNanos { propTime = it / 1e9 }
    }

    BoxWithConstraints(Modifier.fillMaxSize().background(palette.page)) {
        val density = LocalDensity.current
        val geometry = with(density) { PathGeometry(constraints.maxWidth.toFloat(), constraints.maxHeight.toFloat(), this.density) }
        val wordStyle = type.word((geometry.path(PathGeometry.WORD_SIZE) / density.density).sp)
        val world = WorldStyle.of(friend)
        val phonics = (context.applicationContext as HopTalesApplication).phonics.takeIf { soundButtons }
        val path = remember(state.story, geometry, wordStyle, world, phonics) {
            WordPath(state.story, geometry, measurer, wordStyle, world, phonics)
        }
        val target = path.camera(state.sentenceIndex, state.wordIndex)
        val camera = remember(path) { Animatable(target) }
        var motion by remember { mutableStateOf(HareMotion()) }
        var now by remember { mutableDoubleStateOf(0.0) }
        var bigHop by remember { mutableStateOf(false) }
        val clock = remember { HopClock() }

        LaunchedEffect(reduceMotion, motion) {
            if (reduceMotion) return@LaunchedEffect
            while (true) {
                val time = clock.time(withFrameNanos { it } / 1e9)
                now = time
                val landing = motion.hop?.let { it.start + it.length } ?: 0.0
                if (time >= landing) delay(IDLE_FRAME_MILLIS)
            }
        }
        LaunchedEffect(state.recognised) {
            val recognised = state.recognised ?: return@LaunchedEffect
            if (reduceMotion) return@LaunchedEffect
            val start = System.nanoTime() / 1e9
            bigHop = state.isBig(recognised.sentenceIndex, recognised.wordIndex)
            clock.began(start)
            motion = motion.jump(start, distance = 0f, carried = recognised.sentenceIndex != state.sentenceIndex)
        }
        LaunchedEffect(target) {
            if (reduceMotion) {
                camera.snapTo(target)
            } else {
                val rate = motion.hop?.rate ?: 1.0
                camera.animateTo(target, tween((PathGeometry.PAN_MILLIS / rate).toInt(), easing = CubicBezierEasing(0.45f, 0f, 0.3f, 1f)))
            }
        }

        val skyLayout = SkyLayout.of(geometry.meadow, geometry.height)
        val stars = remember(skyLayout) { MeadowStars.field(skyLayout) }
        val stillDrops = if (reduceMotion) remember(geometry) { StillDrops(geometry.width, geometry.height, geometry.density) } else null
        Canvas(Modifier.fillMaxSize()) {
            drawSky(look(), skyLayout, skyArt, stars, skyTime, still = reduceMotion)
        }
        Canvas(Modifier.fillMaxSize()) {
            drawMeadow(layers, geometry.meadow, camera.value, look(), ground)
        }
        Canvas(Modifier.fillMaxSize()) {
            drawWeather(look(), weather, skyTime, geometry.density, stillDrops)
        }
        val propLayout = remember(path, props, friend) { StoryPropLayout(path, state.story.sentences, props, friend) }
        Canvas(Modifier.fillMaxSize()) {
            val time = if (reduceMotion) null else propTime
            val items = propLayout.items(position, camera.value, cues, time)
            drawProps(items, propArt, time, geometry.path(1f), look().tint(MeadowLayer.NEAR), paper)
        }

        val signs =
            remember(path, type, density) { Signposts(context.assets, path, measurer, type.displayFamily, state.story.title, density) }
        val currentStop = path.stop(state.sentenceIndex, state.wordIndex)
        Canvas(
            Modifier
                .fillMaxSize()
                .pointerInputTaps(path, camera, state, onWordTapped)
                .semantics {
                    contentDescription = state.wordCardLabel
                    if (currentStop != null) {
                        onClick(label = "Hear the word") {
                            onWordTapped()
                            true
                        }
                    }
                },
        ) {
            drawSigns(signs, camera.value, look().tint(MeadowLayer.NEAR))
            drawWords(path, camera.value, state.sentenceIndex, state.wordIndex)
            drawBigWords(path, marks, camera.value, state)
            drawTreatOnPath(path, marks, camera.value, state, look().tint(MeadowLayer.NEAR))
        }
        Canvas(Modifier.fillMaxSize()) {
            val pose = motion.pose(now, reduceMotion)
            val lift = if (reduceMotion) {
                0f
            } else {
                motion.arc(now) * path.apex(motion.hop?.carried ?: false) * if (bigHop) PathMarks.BIG_WORD_LIFT else 1f
            }
            drawHare(hare, path, pose, lift, paper.shadow)
        }
    }
}

private const val IDLE_FRAME_MILLIS = (1_000f / IDLE_FPS).toLong()

private fun Modifier.pointerInputTaps(path: WordPath, camera: Animatable<Float, *>, state: ReadingState, onWordTapped: () -> Unit) =
    pointerInput(path, state.sentenceIndex, state.wordIndex) {
        detectTapGestures { offset ->
            if (path.hit(offset, camera.value, state.sentenceIndex, state.wordIndex)) onWordTapped()
        }
    }

private class ReadingOwner : ViewModelStoreOwner {
    override val viewModelStore = ViewModelStore()
}
