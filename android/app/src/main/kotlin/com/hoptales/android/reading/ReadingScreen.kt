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
import androidx.compose.animation.core.EaseInOut
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
import androidx.compose.foundation.layout.size
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
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
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
import androidx.compose.ui.semantics.hideFromAccessibility
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.onLongClick
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.DpOffset
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
import com.hoptales.android.settings.ParentGate
import com.hoptales.android.settings.Paywall
import com.hoptales.android.world.Art
import com.hoptales.android.world.HareSheet
import com.hoptales.android.world.HareSheets
import com.hoptales.android.world.LocalLooks
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
import com.hoptales.android.world.rememberSkyTime
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

private enum class GrownUpStep { GATE, PAYWALL }

@Composable
fun ReadingScreen(
    story: Story,
    onDone: () -> Unit,
    onStory: (Story) -> Unit = {},
    onTryItOn: (Friend) -> Unit = {},
    locksStories: Boolean = BuildConfig.PLUS_LOCKS_STORIES,
) {
    val context = LocalContext.current
    val app = context.applicationContext as HopTalesApplication
    val owner = remember { ReadingOwner() }
    DisposableEffect(owner) { onDispose { owner.viewModelStore.clear() } }
    val model: ReadingViewModel = viewModel(owner) { ReadingViewModel(story, app, locksStories) }
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
    val unavailable = listening == Listening.Denied || listening == Listening.Unsupported
    var grownUp by rememberSaveable { mutableStateOf<GrownUpStep?>(null) }
    BackHandler {
        when {
            grownUp != null -> grownUp = null
            unavailable -> onDone()
            state.isConfirmingStop -> model.keepReading()
            model.backTapped() -> onDone()
        }
    }

    val haptics = LocalHapticFeedback.current
    LaunchedEffect(state.recognised) {
        if (state.recognised != null) haptics.performHapticFeedback(HapticFeedbackType.SegmentTick)
    }
    LaunchedEffect(state.completionCount) {
        if (state.endedASentence) haptics.performHapticFeedback(HapticFeedbackType.Confirm)
    }

    BoxWithConstraints(Modifier.fillMaxSize()) {
        val geometry = with(LocalDensity.current) { PathGeometry(constraints.maxWidth.toFloat(), constraints.maxHeight.toFloat(), density) }
        PathStage(
            state = state,
            wearing = look,
            soundButtons = model.soundButtons,
            onWordTapped = model::help,
            onMeadowTapped = if (BuildConfig.DEBUG) model::skipWord else null,
        )
        Box(Modifier.fillMaxSize().safeDrawingPadding()) {
            BackChip(
                Modifier.align(Alignment.TopStart),
                scale = geometry.chipScale,
                at = DpOffset(geometry.dp(BACK_CHIP_X), geometry.dp(BACK_CHIP_Y)),
            ) { if (model.backTapped()) onDone() }
            val word = state.currentWord
            if (BuildConfig.DEBUG && word != null) {
                Box(Modifier.align(Alignment.BottomCenter).padding(bottom = 10.dp).semantics { hideFromAccessibility() }) {
                    DebugControls(word.text, readWord = model::skipWord, restOfSentence = model::readRestOfSentence)
                }
            }
        }
        when (listening) {
            Listening.NeedsPermission -> AskToListen { request.launch(Manifest.permission.RECORD_AUDIO) }
            Listening.Denied, Listening.Unsupported -> ListeningUnavailable(listening, onBack = onDone)
            else -> Unit
        }
        AnimatedVisibility(state.isFinished, enter = finishedFade, exit = finishedFadeOut) {
            StoryFinished(
                title = story.title,
                stars = (state.completed as? ReadingState.Completed.Story)?.stars ?: state.stars,
                geometry = geometry,
                readAgain = model::readAgain,
                done = onDone,
            )
        }
        AnimatedVisibility(state.isFinished, enter = finishedFade, exit = finishedFadeOut) {
            JourneyPanel(
                state,
                geometry,
                onStory = onStory,
                onTryItOn = { friend ->
                    model.tryItOn(friend)
                    onTryItOn(friend)
                },
                isDone = state.hasTriedItOn,
                dismiss = model::momentDismissed,
                onAskAGrownUp = { grownUp = GrownUpStep.GATE },
                onKeepReading = { if (model.levelOneKeepReading()) onDone() },
            )
        }
        AnimatedVisibility(state.isConfirmingStop, enter = fadeIn(stopFade), exit = fadeOut(stopFade)) {
            StopReading(friend = story.friend.friendName, keepReading = model::keepReading, stop = onDone)
        }
        when (grownUp) {
            GrownUpStep.GATE -> ParentGate(onPassed = { grownUp = GrownUpStep.PAYWALL }, onClose = { grownUp = null })

            GrownUpStep.PAYWALL -> Paywall(
                app.plus,
                onClose = { grownUp = null },
                onSubscribed = {
                    grownUp = null
                    model.momentDismissed()
                },
            )

            null -> Unit
        }
    }
}

@Composable
private fun PathStage(
    state: ReadingState,
    wearing: String?,
    soundButtons: Boolean,
    onWordTapped: () -> Unit,
    onMeadowTapped: (() -> Unit)?,
) {
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
    val skyTime by rememberSkyTime(running = !reduceMotion)
    LaunchedEffect(state.mood) { weather.apply(state.mood, skyTime) }
    val looks = LocalLooks.current
    val hare = remember(friend, wearing, looks) {
        val sheets = HareSheets.of(friend)
        fun sheet(sheet: HareSheet) = wearing?.let { Art.image(context.assets, sheets.dressed(friend, it, sheet), looks) }
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
        var still by remember(path) { mutableStateOf<StillStep?>(null) }
        var settled by remember(path) { mutableStateOf(position) }

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
            still = null
            val from = StillStep(camera.value, settled)
            settled = position
            if (reduceMotion) {
                camera.snapTo(target)
                if (from.cameraX == target) return@LaunchedEffect
                still = from
                val start = withFrameNanos { it }
                while (true) {
                    val elapsed = (withFrameNanos { it } - start) / 1e6f / StillStep.CROSSFADE_MILLIS
                    if (elapsed >= 1f) break
                    still = from.copy(fade = EaseInOut.transform(elapsed))
                }
                still = null
            } else if (!PathCamera.pans(from.position, position)) {
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
            crossfading(still) { cameraX, _ -> drawMeadow(layers, geometry.meadow, cameraX ?: camera.value, look(), ground) }
        }
        Canvas(Modifier.fillMaxSize()) {
            drawWeather(look(), weather, skyTime, geometry.density, stillDrops)
        }
        val signs =
            remember(path, type, density) { Signposts(context.assets, path, measurer, type.displayFamily, state.story.title, density) }
        Canvas(Modifier.fillMaxSize()) {
            crossfading(still) { cameraX, _ -> drawSigns(signs, cameraX ?: camera.value, look().tint(MeadowLayer.NEAR)) }
        }
        val propLayout = remember(path, props, friend) { StoryPropLayout(path, state.story.sentences, props, friend) }
        Canvas(Modifier.fillMaxSize()) {
            val time = if (reduceMotion) null else propTime
            crossfading(still) { cameraX, from ->
                val items = propLayout.items(from ?: position, cameraX ?: camera.value, cues, time)
                drawProps(items, propArt, time, geometry.path(1f), look().tint(MeadowLayer.NEAR), paper)
            }
        }

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
                    .wordPresses(path, camera, position, isChallenge, onWordTapped, explain, onMeadowTapped),
            ) {
                val wordNow = if (reduceMotion) null else wordClock
                crossfading(still) { stepX, _ ->
                    val cameraX = stepX ?: camera.value
                    drawWords(path, cameraX, wordMarks, { state.isBig(it.sentence, it.word) }) { stop ->
                        val target = HopTarget(stop.sentence, stop.word)
                        WordMotion.look(target, isChallenge(target), move, speech, wordNow)
                    }
                    drawTreatOnPath(path, marks, cameraX, state, look().tint(MeadowLayer.NEAR))
                }
            }
        }
        if (currentStop != null) {
            val minimum = geometry.path(CurrentWord.MINIMUM)
            val challenge = isChallenge(position)
            Box(
                Modifier
                    .centredOn { Offset(currentStop.centre - camera.value, path.wordCentreY(currentStop)) }
                    .size(
                        with(density) { maxOf(minimum, currentStop.width).toDp() },
                        with(density) { maxOf(minimum, currentStop.layout.size.height.toFloat()).toDp() },
                    )
                    .semantics {
                        contentDescription = CurrentWord.label(state.wordCardLabel, challenge)
                        onClick(label = CurrentWord.HEAR) {
                            onWordTapped()
                            true
                        }
                        if (challenge) {
                            onLongClick(label = ChallengeTip.TITLE) {
                                explain(position)
                                true
                            }
                        }
                    },
            )
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
        pickup = treat
        landed.snapTo(0f)
        leaving.snapTo(1f)
        scope.launch {
            delay((PathMarks.PICKUP_DELAY * 1_000).toLong())
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
            BasketChip(treat, geometry)
        }
    }
}

object PathCamera {
    fun pans(from: HopTarget, to: HopTarget): Boolean = to > from
}

private data class StillStep(val cameraX: Float, val position: HopTarget, val fade: Float = 0f) {
    companion object {
        const val CROSSFADE_MILLIS = 200f
    }
}

private fun DrawScope.crossfading(step: StillStep?, block: DrawScope.(cameraX: Float?, position: HopTarget?) -> Unit) {
    if (step == null) {
        block(null, null)
        return
    }
    faded(1 - step.fade) { block(step.cameraX, step.position) }
    faded(step.fade) { block(null, null) }
}

private fun DrawScope.faded(alpha: Float, block: DrawScope.() -> Unit) {
    if (alpha <= 0f) return
    drawIntoCanvas { it.saveLayer(Rect(Offset.Zero, size), Paint().apply { this.alpha = alpha }) }
    block()
    drawIntoCanvas { it.restore() }
}

private fun Modifier.centredOn(point: () -> Offset) = layout { measurable, constraints ->
    val placeable = measurable.measure(constraints.copy(minWidth = 0, minHeight = 0))
    layout(constraints.maxWidth, constraints.maxHeight) {
        val centre = point()
        placeable.place((centre.x - placeable.width / 2f).roundToInt(), (centre.y - placeable.height / 2f).roundToInt())
    }
}

private val finishedFade = fadeIn(tween(FINISHED_FADE_MILLIS, delayMillis = PathGeometry.PAN_MILLIS, easing = EaseOut))
private val finishedFadeOut = fadeOut(tween(FINISHED_FADE_MILLIS, delayMillis = PathGeometry.PAN_MILLIS, easing = EaseOut))
private val stopFade = tween<Float>(STOP_FADE_MILLIS, easing = EaseInOut)

object CurrentWord {
    const val MINIMUM = 44f
    const val HEAR = "Hear the word"

    fun label(word: String, challenge: Boolean): String = if (challenge) "$word ${ChallengeTip.TITLE}: ${ChallengeTip.DETAIL}" else word
}

private const val FINISHED_FADE_MILLIS = 400
private const val STOP_FADE_MILLIS = 200
private const val PLUS_FIVE_SIZE = 0.4f
private const val BACK_CHIP_X = 18f
private const val BACK_CHIP_Y = 7f
private const val IDLE_FRAME_MILLIS = (1_000f / IDLE_FPS).toLong()

private fun Modifier.wordPresses(
    path: WordPath,
    camera: Animatable<Float, *>,
    position: HopTarget,
    isChallenge: (HopTarget) -> Boolean,
    onWordTapped: () -> Unit,
    explain: (HopTarget) -> Unit,
    onMeadowTapped: (() -> Unit)?,
) = pointerInput(path, position, onMeadowTapped) {
    fun respond(press: WordPress, offset: Offset) {
        val target = path.pressed(offset, camera.value, position, isChallenge)
        if (target == null) {
            if (press == WordPress.TAP) onMeadowTapped?.invoke()
            return
        }
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
