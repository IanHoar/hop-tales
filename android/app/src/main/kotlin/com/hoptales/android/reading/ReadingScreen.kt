package com.hoptales.android.reading

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.EaseIn
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalViewConfiguration
import androidx.compose.ui.platform.ViewConfiguration
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.onLongClick
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
import com.hoptales.android.world.TreatSticker
import com.hoptales.android.world.WorldStyle
import com.hoptales.android.world.drawSky
import com.hoptales.android.world.drawWeather
import com.hoptales.android.world.rememberSkyLook
import com.hoptales.content.Friend
import com.hoptales.content.Story
import com.hoptales.content.StoryTreat
import com.hoptales.reading.HopTarget
import com.hoptales.reading.PropCue
import com.hoptales.reading.PropKey
import com.hoptales.reading.PropTiming
import com.hoptales.reading.ReadingState
import com.hoptales.reading.StoryPropLayout
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

@Composable
fun ReadingScreen(story: Story, onDone: () -> Unit, onStory: (Story) -> Unit = {}, onTryItOn: (Friend) -> Unit = {}) {
    val context = LocalContext.current
    val app = context.applicationContext as HopTalesApplication
    val owner = remember { ReadingOwner() }
    DisposableEffect(owner) { onDispose { owner.viewModelStore.clear() } }
    val model: ReadingViewModel = viewModel(owner) { ReadingViewModel(story, app) }
    val state by model.state.collectAsStateWithLifecycle()
    val listening by model.listening.collectAsStateWithLifecycle()
    val look by model.look.collectAsStateWithLifecycle()
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
        if (state.endedASentence) haptics.performHapticFeedback(HapticFeedbackType.Confirm)
    }

    Box(Modifier.fillMaxSize()) {
        PathStage(state = state, wearing = look, soundButtons = model.soundButtons, onWordTapped = model::help)
        Box(Modifier.fillMaxSize().safeDrawingPadding().padding(horizontal = 12.dp, vertical = 4.dp)) {
            BackChip(Modifier.align(Alignment.TopStart)) { if (model.backTapped()) onDone() }
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
        AnimatedVisibility(state.isFinished, enter = finishedFade, exit = fadeOut()) {
            StoryFinished(
                title = story.title,
                stars = (state.completed as? ReadingState.Completed.Story)?.stars ?: state.stars,
                readAgain = model::readAgain,
                done = onDone,
            )
        }
        AnimatedVisibility(state.isFinished, enter = finishedFade, exit = fadeOut()) {
            JourneyPanel(
                state,
                onStory = onStory,
                onTryItOn = { friend ->
                    model.tryItOn(friend)
                    onTryItOn(friend)
                },
                isDone = state.hasTriedItOn,
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
        val plusFive = remember(measurer, type, path) {
            measurer.measure("+5", type.display((path.wordSize * PLUS_FIVE_SIZE / density.density).sp))
        }
        val wordMarks = WordMarks(marks.star, plusFive, paper.ink)
        val moves = remember(state.story) { WordMoves(position, state.isSpeaking) }
        val move = moves.moved(position, System.nanoTime() / 1e9)
        val speech = moves.spoke(state.isSpeaking, System.nanoTime() / 1e9)
        var wordClock by remember { mutableDoubleStateOf(0.0) }
        LaunchedEffect(move, speech, reduceMotion) {
            if (reduceMotion) return@LaunchedEffect
            while (true) {
                withFrameNanos { }
                val time = System.nanoTime() / 1e9
                wordClock = time
                if (WordMotion.isSettled(move, speech, time)) break
            }
        }
        var tip by remember(state.story) { mutableStateOf<ChallengeTipState?>(null) }
        var tips by remember { mutableLongStateOf(0L) }
        val explain: (HopTarget) -> Unit = { target ->
            tips += 1
            tip = ChallengeTipState(target, tips)
        }
        LaunchedEffect(tip) {
            if (tip == null) return@LaunchedEffect
            delay(ChallengeTip.HOLD_MILLIS)
            tip = null
        }
        val isChallenge: (HopTarget) -> Boolean = { state.isBig(it.sentence, it.word) }
        val viewConfiguration = LocalViewConfiguration.current
        val pressing = remember(viewConfiguration) {
            object : ViewConfiguration by viewConfiguration {
                override val longPressTimeoutMillis: Long get() = ChallengeTip.LONG_PRESS_MILLIS
            }
        }
        CompositionLocalProvider(LocalViewConfiguration provides pressing) {
            Canvas(
                Modifier
                    .fillMaxSize()
                    .wordPresses(path, camera, position, isChallenge, onWordTapped, explain)
                    .semantics {
                        contentDescription = state.wordCardLabel
                        if (currentStop != null) {
                            onClick(label = "Hear the word") {
                                onWordTapped()
                                true
                            }
                            if (isChallenge(position)) {
                                onLongClick(label = ChallengeTip.TITLE) {
                                    explain(position)
                                    true
                                }
                            }
                        }
                    },
            ) {
                drawSigns(signs, camera.value, look().tint(MeadowLayer.NEAR))
                val wordNow = if (reduceMotion) null else wordClock
                drawWords(path, camera.value, wordMarks, { state.isBig(it.sentence, it.word) }) { stop ->
                    val target = HopTarget(stop.sentence, stop.word)
                    WordMotion.look(target, isChallenge(target), move, speech, wordNow)
                }
                drawTreatOnPath(path, marks, camera.value, state, look().tint(MeadowLayer.NEAR))
            }
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
        PickupLayer(state, geometry, reduceMotion)
        var shownTip by remember { mutableStateOf<ChallengeTipState?>(null) }
        if (tip != null) shownTip = tip
        AnimatedVisibility(
            tip != null,
            Modifier.centredOn {
                val stop = shownTip?.let { path.stop(it.target.sentence, it.target.word) } ?: return@centredOn Offset.Zero
                Offset(
                    ChallengeTip.x(stop.centre - camera.value, geometry.width, geometry),
                    path.wordCentreY(stop) - stop.layout.size.height - geometry.path(ChallengeTip.ABOVE_WORD),
                )
            },
            enter = fadeIn(tween(ChallengeTip.SHOW_MILLIS, easing = EaseOut)) +
                scaleIn(tween(ChallengeTip.SHOW_MILLIS, easing = EaseOut), ChallengeTip.FROM_SCALE, TransformOrigin(0.5f, 1f)),
            exit = fadeOut(tween(ChallengeTip.HIDE_MILLIS, easing = EaseIn)) +
                scaleOut(tween(ChallengeTip.HIDE_MILLIS, easing = EaseIn), ChallengeTip.FROM_SCALE, TransformOrigin(0.5f, 1f)),
        ) {
            ChallengeTipCard(geometry)
        }
    }
}

@Composable
private fun PickupLayer(state: ReadingState, geometry: PathGeometry, reduceMotion: Boolean) {
    val density = LocalDensity.current
    var pickup by remember { mutableStateOf<StoryTreat?>(null) }
    var showsBasket by remember { mutableStateOf(false) }
    val landed = remember { Animatable(0f) }
    val leaving = remember { Animatable(1f) }
    val position = HopTarget(state.sentenceIndex, state.wordIndex)
    var passed by remember { mutableStateOf(position) }
    val scope = rememberCoroutineScope()
    LaunchedEffect(position) {
        val old = passed
        passed = position
        if (reduceMotion) return@LaunchedEffect
        val treat = Pickup.passed(state.treat, old, position) ?: return@LaunchedEffect
        scope.launch {
            delay((PathMarks.PICKUP_DELAY * 1_000).toLong())
            pickup = treat
            landed.snapTo(0f)
            leaving.snapTo(1f)
            launch { landed.animateTo(1f, swiftSpring(PathMarks.FLIGHT_SECONDS, PathMarks.FLIGHT_BOUNCE)) }
            delay((PathMarks.CHIP_DELAY * 1_000).toLong())
            showsBasket = true
            delay(((PathMarks.HIDE_AFTER - PathMarks.CHIP_DELAY) * 1_000).toLong())
            leaving.animateTo(0f, tween((PathMarks.HIDE_SECONDS * 1_000).toInt(), easing = EaseIn))
            pickup = null
            showsBasket = false
        }
    }
    val start = Pickup.start(geometry)
    val chip = Pickup.chip(geometry)
    Box(Modifier.fillMaxSize()) {
        val treat = pickup ?: return@Box
        val height = with(density) { geometry.path(PathMarks.TREAT_HEIGHT).toDp() }
        TreatSticker(
            treat.friend,
            height,
            Modifier
                .centredOn { Pickup.frame(start, chip, landed.value).let { Offset(it.x, it.y) } }
                .graphicsLayer {
                    val frame = Pickup.frame(start, chip, landed.value)
                    rotationZ = frame.rotation
                    scaleX = frame.scale
                    scaleY = frame.scale
                    alpha = frame.alpha * leaving.value
                },
        )
        AnimatedVisibility(
            showsBasket,
            Modifier.centredOn { chip }.graphicsLayer {
                alpha = leaving.value
                scaleX = PathMarks.CHIP_FROM + (1 - PathMarks.CHIP_FROM) * leaving.value
                scaleY = scaleX
            },
            enter = fadeIn(tween((PathMarks.CHIP_SECONDS * 1_000).toInt(), easing = EaseOut)) +
                scaleIn(tween((PathMarks.CHIP_SECONDS * 1_000).toInt(), easing = EaseOut), PathMarks.CHIP_FROM),
            exit = fadeOut(tween(0)),
        ) {
            BasketChip(treat)
        }
    }
}

private fun Modifier.centredOn(point: () -> Offset) = layout { measurable, constraints ->
    val placeable = measurable.measure(constraints.copy(minWidth = 0, minHeight = 0))
    layout(constraints.maxWidth, constraints.maxHeight) {
        val centre = point()
        placeable.place((centre.x - placeable.width / 2f).roundToInt(), (centre.y - placeable.height / 2f).roundToInt())
    }
}

private val finishedFade = fadeIn(tween(FINISHED_FADE_MILLIS, delayMillis = PathGeometry.PAN_MILLIS, easing = EaseOut))

private const val FINISHED_FADE_MILLIS = 400
private const val PLUS_FIVE_SIZE = 0.4f
private const val IDLE_FRAME_MILLIS = (1_000f / IDLE_FPS).toLong()

private fun Modifier.wordPresses(
    path: WordPath,
    camera: Animatable<Float, *>,
    position: HopTarget,
    isChallenge: (HopTarget) -> Boolean,
    onWordTapped: () -> Unit,
    explain: (HopTarget) -> Unit,
) = pointerInput(path, position) {
    fun respond(press: WordPress, offset: Offset) {
        val target = path.pressed(offset, camera.value, position, isChallenge) ?: return
        when (val response = ChallengeTip.respond(press, target, position, isChallenge(target))) {
            WordResponse.Hear -> onWordTapped()
            is WordResponse.Explain -> explain(response.target)
            null -> Unit
        }
    }
    detectTapGestures(
        onLongPress = { respond(WordPress.LONG_PRESS, it) },
        onTap = { respond(WordPress.TAP, it) },
    )
}

private class ReadingOwner : ViewModelStoreOwner {
    override val viewModelStore = ViewModelStore()
}
