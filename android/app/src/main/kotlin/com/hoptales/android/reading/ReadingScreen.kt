package com.hoptales.android.reading

import android.Manifest
import android.content.pm.PackageManager
import android.provider.Settings
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.hoptales.android.BuildConfig
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperChip
import com.hoptales.android.design.StarChip
import com.hoptales.android.world.Art
import com.hoptales.android.world.HareSheets
import com.hoptales.android.world.MeadowLayer
import com.hoptales.android.world.WorldStyle
import com.hoptales.content.Story
import com.hoptales.reading.ReadingState
import kotlinx.coroutines.delay

@Composable
fun ReadingScreen(story: Story, onDone: () -> Unit) {
    val context = LocalContext.current
    val app = context.applicationContext as HopTalesApplication
    val model: ReadingViewModel = viewModel(key = story.id) { ReadingViewModel(story, app) }
    val state by model.state.collectAsStateWithLifecycle()
    val listening by model.listening.collectAsStateWithLifecycle()
    var permission by remember {
        mutableStateOf(ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED)
    }
    val request = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
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

    Box(Modifier.fillMaxSize()) {
        PathStage(state = state, onWordTapped = model::help)
        Box(Modifier.fillMaxSize().safeDrawingPadding().padding(16.dp)) {
            BackChip(Modifier.align(Alignment.TopStart)) { if (model.backTapped()) onDone() }
            StarChip(state.stars, Modifier.align(Alignment.TopEnd))
            Column(Modifier.align(Alignment.BottomCenter), horizontalAlignment = Alignment.CenterHorizontally) {
                if (BuildConfig.DEBUG && state.currentWord != null) {
                    PaperChip(onClick = model::skipWord) {
                        Text(
                            "Hear “${state.currentWord?.text}”",
                            style = LocalTypography.current.ui(15.sp),
                            color = LocalPalette.current.ink,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                        )
                    }
                    Spacer(Modifier.height(12.dp))
                }
                if (!state.isFinished) MicPill(listening)
            }
        }
        if (listening == Listening.NeedsPermission) {
            AskToListen { request.launch(Manifest.permission.RECORD_AUDIO) }
        }
        AnimatedVisibility(state.isFinished, enter = fadeIn(), exit = fadeOut()) {
            StoryFinished(
                title = story.title,
                stars = (state.completed as? ReadingState.Completed.Story)?.stars ?: state.stars,
                readAgain = model::readAgain,
                done = onDone,
            )
        }
    }

    if (state.isConfirmingStop) {
        StopReading(keepReading = model::keepReading, stop = onDone)
    }
}

@Composable
private fun PathStage(state: ReadingState, onWordTapped: () -> Unit) {
    val context = LocalContext.current
    val reduceMotion = remember {
        Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    }
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val measurer = rememberTextMeasurer()
    val friend = state.story.friend
    val layers = remember(friend) {
        MeadowLayer.entries.associateWith { Art.image(context.assets, it.asset(friend)) ?: Art.image(context.assets, "${it.prefix}-day") }
    }
    val hare = remember(friend) {
        val sheets = HareSheets.of(friend)
        HareArt(Art.image(context.assets, sheets.idle.asset), Art.image(context.assets, sheets.hop.asset), sheets)
    }

    BoxWithConstraints(Modifier.fillMaxSize().background(palette.page)) {
        val density = LocalDensity.current
        val geometry = with(density) { PathGeometry(constraints.maxWidth.toFloat(), constraints.maxHeight.toFloat(), this.density) }
        val wordStyle = type.word(with(density) { geometry.path(PathGeometry.WORD_SIZE).toSp() })
        val world = WorldStyle.of(friend)
        val path = remember(state.story, geometry, wordStyle, world) { WordPath(state.story, geometry, measurer, wordStyle, world) }
        val target = path.camera(state.sentenceIndex, state.wordIndex)
        val camera = remember(path) { Animatable(target) }
        var motion by remember { mutableStateOf(HareMotion()) }
        var now by remember { mutableDoubleStateOf(0.0) }

        LaunchedEffect(reduceMotion, motion) {
            if (reduceMotion) return@LaunchedEffect
            while (true) {
                val time = withFrameNanos { it } / 1e9
                now = time
                val landing = motion.hop?.let { it.start + it.length } ?: 0.0
                if (time >= landing) delay(IDLE_FRAME_MILLIS)
            }
        }
        LaunchedEffect(state.recognised) {
            val recognised = state.recognised ?: return@LaunchedEffect
            if (reduceMotion) return@LaunchedEffect
            motion = motion.jump(System.nanoTime() / 1e9, distance = 0f, carried = recognised.sentenceIndex != state.sentenceIndex)
        }
        LaunchedEffect(target) {
            if (reduceMotion) {
                camera.snapTo(target)
            } else {
                val rate = motion.hop?.rate ?: 1.0
                camera.animateTo(target, tween((PathGeometry.PAN_MILLIS / rate).toInt(), easing = CubicBezierEasing(0.45f, 0f, 0.3f, 1f)))
            }
        }

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
            val cameraX = camera.value
            drawSky(state.mood.sky)
            drawMeadow(layers, geometry.meadow, cameraX, state.mood.sky)
            drawWords(path, cameraX, state.sentenceIndex, state.wordIndex)
        }
        Canvas(Modifier.fillMaxSize()) {
            val pose = motion.pose(now, reduceMotion)
            val lift = if (reduceMotion) 0f else motion.arc(now) * path.apex(motion.hop?.carried ?: false)
            drawHare(hare, path, pose, lift)
        }
    }
}

private const val IDLE_FRAME_MILLIS = (1_000f / IDLE_FPS).toLong()

private fun Modifier.pointerInputTaps(
    path: WordPath,
    camera: Animatable<Float, *>,
    state: ReadingState,
    onWordTapped: () -> Unit,
) =
    pointerInput(path, state.sentenceIndex, state.wordIndex) {
        detectTapGestures { offset ->
            if (path.hit(offset, camera.value, state.sentenceIndex, state.wordIndex)) onWordTapped()
        }
    }

@Composable
private fun BackChip(modifier: Modifier = Modifier, onClick: () -> Unit) {
    PaperChip(modifier.size(48.dp).semantics { contentDescription = "Back" }, onClick = onClick) {
        Box(contentAlignment = Alignment.Center) {
            Text("‹", style = LocalTypography.current.display(30.sp), color = LocalPalette.current.ink)
        }
    }
}

@Composable
private fun MicPill(listening: Listening) {
    val palette = LocalPalette.current
    val (text, background) = when (listening) {
        Listening.Waiting, Listening.NeedsPermission -> "Getting ready…" to palette.parchment
        Listening.Unavailable -> "Tap the word to hear it" to palette.parchment
        Listening.Active -> "Listening…" to palette.parchment
        is Listening.Heard -> "Heard it — “${listening.word}”" to palette.heardBg
    }
    Surface(
        shape = CircleShape,
        color = background,
        border = BorderStroke(3.dp, palette.outline),
        shadowElevation = 2.dp,
    ) {
        Text(
            text,
            style = LocalTypography.current.ui(16.sp, FontWeight.Medium),
            color = if (listening is Listening.Heard) palette.heardText else palette.ink,
            modifier = Modifier.padding(horizontal = 22.dp, vertical = 14.dp),
        )
    }
}

@Composable
private fun PaperCard(content: @Composable () -> Unit) {
    val palette = LocalPalette.current
    Box(Modifier.fillMaxSize().background(palette.outline.copy(alpha = 0.35f)), contentAlignment = Alignment.Center) {
        Surface(
            modifier = Modifier.padding(24.dp).widthIn(max = 420.dp),
            shape = RoundedCornerShape(34.dp),
            color = palette.parchment,
            border = BorderStroke(3.dp, palette.outline),
            shadowElevation = 6.dp,
        ) {
            Column(
                Modifier.padding(28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) { content() }
        }
    }
}

@Composable
private fun BigButton(text: String, filled: Boolean = true, onClick: () -> Unit) {
    val palette = LocalPalette.current
    Surface(
        onClick = onClick,
        shape = CircleShape,
        color = if (filled) palette.teal else palette.paper,
        border = BorderStroke(3.dp, palette.outline),
    ) {
        Text(
            text,
            style = LocalTypography.current.ui(19.sp),
            color = if (filled) palette.onTeal else palette.ink,
            modifier = Modifier.padding(horizontal = 28.dp, vertical = 14.dp),
        )
    }
}

@Composable
private fun AskToListen(onAllow: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    PaperCard {
        Text("Read it out loud", style = type.display(26.sp), color = palette.ink, textAlign = TextAlign.Center)
        Text(
            "Hop Tales listens while you read so the hare can hop along. Listening happens on this " +
                "device — nothing is recorded or sent anywhere.",
            style = type.ui(16.sp, FontWeight.Medium),
            color = palette.muted,
            textAlign = TextAlign.Center,
        )
        BigButton("Let's read", onClick = onAllow)
    }
}

@Composable
private fun StoryFinished(title: String, stars: Int, readAgain: () -> Unit, done: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    PaperCard {
        Text("You read", style = type.caps(13.sp), color = palette.muted)
        Text(title, style = type.display(28.sp), color = palette.ink, textAlign = TextAlign.Center)
        StarChip(stars)
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            BigButton("Read again", filled = false, onClick = readAgain)
            BigButton("Done", onClick = done)
        }
    }
}

@Composable
private fun StopReading(keepReading: () -> Unit, stop: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    AlertDialog(
        onDismissRequest = keepReading,
        containerColor = palette.parchment,
        title = { Text("Stop reading?", style = type.display(24.sp), color = palette.ink) },
        confirmButton = { TextButton(onClick = keepReading) { Text("Keep reading", style = type.ui(18.sp), color = palette.teal) } },
        dismissButton = { TextButton(onClick = stop) { Text("Stop", style = type.ui(18.sp), color = palette.muted) } },
    )
}
