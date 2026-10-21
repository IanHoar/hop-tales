package com.hoptales.android.reading

import android.provider.Settings
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.EaseIn
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
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
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.ROSETTE_INK
import com.hoptales.android.world.Sticker
import com.hoptales.content.Friend
import kotlinx.coroutines.launch
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin

enum class RevealStage { HIDDEN, SHAKING, REVEALED, SETTLED }

object FriendReveal {
    const val HIDDEN_MILLIS = 300L
    const val SHAKE_MILLIS = 1_000L
    const val REVEALED_MILLIS = 900L
    const val CONFETTI_DELAY_MILLIS = 1_300
    const val REVEAL_SECONDS = 0.55
    const val REVEAL_BOUNCE = 0.5
    const val SETTLE_SECONDS = 0.5
    const val SETTLE_BOUNCE = 0.35
    const val SPIN_MILLIS = 30_000
    const val HEIGHT = 104f
    const val FRAME = 150f
    const val RAYS = 14
    val swings = listOf(3f, -3f, 5f, -5f, 7f, -7f, 9f, -9f).map { it to 0.11 } + (0f to 0.1)
    val lifts = listOf(16f to 0.18, 0f to 0.18, 6f to 0.14, 0f to 0.14)

    const val SETTLES_AT = HIDDEN_MILLIS + SHAKE_MILLIS + REVEALED_MILLIS

    fun stage(elapsedMillis: Long): RevealStage = when {
        elapsedMillis < HIDDEN_MILLIS -> RevealStage.HIDDEN
        elapsedMillis < HIDDEN_MILLIS + SHAKE_MILLIS -> RevealStage.SHAKING
        elapsedMillis < SETTLES_AT -> RevealStage.REVEALED
        else -> RevealStage.SETTLED
    }

    fun keyframes(frames: List<Pair<Float, Double>>, elapsed: Double): Float {
        var start = 0f
        var time = elapsed
        for ((value, length) in frames) {
            if (time < length) return start + (value - start) * smooth.transform((time / length).toFloat().coerceIn(0f, 1f))
            time -= length
            start = value
        }
        return start
    }

    private val smooth = CubicBezierEasing(0.42f, 0f, 0.58f, 1f)
}

fun swiftSpring(duration: Double, bounce: Double) = spring<Float>(
    dampingRatio = (1 - bounce).toFloat(),
    stiffness = (2 * PI / duration).pow(2).toFloat(),
)

@Composable
fun FriendReveal(friend: Friend, geometry: PathGeometry) {
    val context = LocalContext.current
    val still = remember { Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
    val haptics = LocalHapticFeedback.current
    val type = LocalTypography.current
    val paper = LocalPaper.current
    var stage by remember { mutableStateOf(if (still) RevealStage.SETTLED else RevealStage.HIDDEN) }
    val reveal = remember { Animatable(if (still) 1f else 0f) }
    val settle = remember { Animatable(if (still) 1f else 0f) }
    val spin = remember { Animatable(0f) }
    var shakeTime by remember { mutableDoubleStateOf(0.0) }
    var liftTime by remember { mutableDoubleStateOf(Double.MAX_VALUE) }
    LaunchedEffect(Unit) {
        if (still) return@LaunchedEffect
        val origin = withFrameNanos { it }
        val bounces = FriendReveal.lifts.sumOf { it.second }
        while (liftTime == Double.MAX_VALUE || liftTime <= bounces) {
            val elapsed = (withFrameNanos { it } - origin) / 1_000_000
            val next = FriendReveal.stage(elapsed)
            if (next != stage) {
                stage = next
                when (next) {
                    RevealStage.REVEALED -> {
                        haptics.performHapticFeedback(HapticFeedbackType.Confirm)
                        launch { reveal.animateTo(1f, swiftSpring(FriendReveal.REVEAL_SECONDS, FriendReveal.REVEAL_BOUNCE)) }
                        launch {
                            spin.animateTo(
                                360f,
                                infiniteRepeatable(tween(FriendReveal.SPIN_MILLIS, easing = LinearEasing), RepeatMode.Restart),
                            )
                        }
                    }

                    RevealStage.SETTLED -> launch {
                        settle.animateTo(1f, swiftSpring(FriendReveal.SETTLE_SECONDS, FriendReveal.SETTLE_BOUNCE))
                    }

                    else -> Unit
                }
            }
            shakeTime = (elapsed - FriendReveal.HIDDEN_MILLIS) / 1e3
            if (next == RevealStage.SETTLED) liftTime = (elapsed - FriendReveal.SETTLES_AT) / 1e3
        }
    }
    val height = geometry.dp(FriendReveal.HEIGHT)
    val wash = paper.wash
    Box(
        Modifier
            .fillMaxWidth()
            .height(geometry.dp(FriendReveal.FRAME))
            .clearAndSetSemantics { contentDescription = "${friend.friendName}, your new friend" },
        contentAlignment = Alignment.Center,
    ) {
        val shown = reveal.value
        val settled = settle.value
        Canvas(
            Modifier
                .size(height * 1.6f)
                .graphicsLayer {
                    rotationZ = spin.value
                    scaleX = 0.2f + 0.8f * shown
                    scaleY = 0.2f + 0.8f * shown
                    alpha = shown.coerceIn(0f, 1f)
                },
        ) {
            val centre = center
            val radius = size.minDimension / 2
            val half = PI / FriendReveal.RAYS / 2
            val rays = Path()
            for (ray in 0 until FriendReveal.RAYS) {
                val angle = ray * 2 * PI / FriendReveal.RAYS
                rays.moveTo(centre.x, centre.y)
                rays.arcTo(
                    Rect(centre, radius),
                    Math.toDegrees(angle - half).toFloat(),
                    Math.toDegrees(2 * half).toFloat(),
                    forceMoveTo = false,
                )
                rays.close()
            }
            drawPath(
                rays,
                Brush.radialGradient(listOf(wash.copy(alpha = 0.75f), wash.copy(alpha = 0f)), centre, height.toPx() * 0.8f),
            )
        }
        val sparkle = if (stage >= RevealStage.REVEALED) (shown * (1 - settled)).coerceIn(0f, 1f) else 0f
        for (index in 0 until 8) {
            val angle = index * PI / 4 + PI / 8
            val reach = height * (if (index % 2 == 0) 0.78f else 0.62f) * shown
            Sticker(
                "collect-star",
                Modifier
                    .offset(reach * cos(angle).toFloat(), reach * sin(angle).toFloat() * 0.8f)
                    .size(geometry.dp(if (index % 2 == 0) 20f else 14f))
                    .graphicsLayer {
                        scaleX = 0.2f + 0.8f * sparkle
                        scaleY = 0.2f + 0.8f * sparkle
                        alpha = sparkle
                    },
            )
        }
        FriendSticker(
            friend,
            height,
            Modifier.graphicsLayer {
                alpha = (0.7f * (1 - shown)).coerceIn(0f, 1f)
                scaleX = 0.9f + 0.4f * shown
                scaleY = 0.9f + 0.4f * shown
                transformOrigin = TransformOrigin(0.5f, 1f)
                rotationZ = if (stage == RevealStage.SHAKING) FriendReveal.keyframes(FriendReveal.swings, shakeTime) else 0f
            },
            isSilhouette = true,
        )
        FriendSticker(
            friend,
            height,
            Modifier.graphicsLayer {
                alpha = shown.coerceIn(0f, 1f)
                scaleX = 0.3f + 0.7f * shown
                scaleY = 0.3f + 0.7f * shown
                transformOrigin = TransformOrigin(0.5f, 1f)
                translationY = -geometry.path(FriendReveal.keyframes(FriendReveal.lifts, liftTime))
            },
        )
        FriendSticker(
            Friend.at(friend.level - 1),
            geometry.dp(60f),
            Modifier
                .offset(-height * 0.95f - geometry.dp(30f) * (1 - settled), height / 2 - geometry.dp(30f))
                .graphicsLayer { alpha = settled.coerceIn(0f, 1f) },
        )
        Box(
            Modifier
                .offset(height * 0.85f, -geometry.dp(38f))
                .graphicsLayer {
                    rotationZ = -40f + 48f * settled
                    scaleX = 0.2f + 0.8f * settled
                    scaleY = 0.2f + 0.8f * settled
                    alpha = settled.coerceIn(0f, 1f)
                },
            contentAlignment = Alignment.Center,
        ) {
            Sticker("collect-rosette", Modifier.size(geometry.dp(56f)))
            Text(
                "${friend.level}",
                style = type.display(geometry.sp(18f)),
                color = ROSETTE_INK,
                modifier = Modifier.offset(y = -geometry.dp(5f)),
            )
        }
    }
}

@Composable
fun PaperConfetti(delayMillis: Int = 0) {
    val context = LocalContext.current
    val still = remember { Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
    val paper = LocalPaper.current
    val colours = listOf(paper.red, paper.wash, paper.sage, Color(0xFF8FB7D9), Color(0xFFE8A7B8))
    val fall = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        if (!still) fall.animateTo(1f, tween(CONFETTI_MILLIS, delayMillis = delayMillis, easing = EaseIn))
    }
    Canvas(Modifier.fillMaxSize()) {
        val fallen = fall.value
        if (fallen <= 0f || fallen >= 1f) return@Canvas
        val piece = Size(7.dp.toPx(), 11.dp.toPx())
        for (index in 0 until CONFETTI_PIECES) {
            val x = ((index * 37) % 100) / 100f * size.width + (index % 7 - 3) * 14.dp.toPx() * fallen
            val y = -20.dp.toPx() + (size.height * (0.35f + (index % 9) * 0.06f) + 20.dp.toPx()) * fallen
            rotate(index * 47f * fallen, Offset(x, y)) {
                drawRoundRect(
                    colours[index % colours.size],
                    topLeft = Offset(x - piece.width / 2, y - piece.height / 2),
                    size = piece,
                    cornerRadius = CornerRadius(1.5.dp.toPx()),
                    alpha = 1 - fallen,
                )
            }
        }
    }
}

private const val CONFETTI_PIECES = 36
private const val CONFETTI_MILLIS = 2_200
