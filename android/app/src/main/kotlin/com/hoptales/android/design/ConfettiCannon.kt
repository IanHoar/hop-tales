package com.hoptales.android.design

import android.provider.Settings
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.random.Random

@Composable
fun ConfettiCannon(delaySeconds: Float = 0f, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val still = remember { Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
    val paper = LocalPaper.current
    val colours = remember(paper) {
        listOf(paper.red, paper.wash, paper.sage, Color(0xFF8FB7D9), Color(0xFFE8A7B8), Color(0xFFF2A65A), Color(0xFFB9A6E0))
    }
    val pieces = remember(colours) { ConfettiPiece.burst(140, colours) }
    var elapsed by remember { mutableFloatStateOf(-1f) }
    LaunchedEffect(still) {
        if (still) return@LaunchedEffect
        val start = withFrameNanos { it }
        while (elapsed < CONFETTI_SECONDS + delaySeconds) {
            withFrameNanos { elapsed = (it - start) / 1e9f }
        }
    }
    Canvas(modifier.fillMaxSize().clearAndSetSemantics {}) {
        val time = elapsed - delaySeconds
        if (time <= 0f || time >= CONFETTI_SECONDS) return@Canvas
        pieces.forEach { it.draw(this, time.toDouble()) }
    }
}

private const val CONFETTI_SECONDS = 4.6f

private class ConfettiPiece(
    val fromLeft: Boolean,
    val angle: Double,
    val speed: Double,
    val launch: Double,
    val shape: Int,
    val colour: Color,
    val length: Float,
    val spin: Double,
    val flip: Double,
    val flutter: Double,
    val phase: Double,
) {
    fun draw(scope: DrawScope, elapsed: Double) = with(scope) {
        val time = elapsed - launch
        if (time <= 0) return
        val unit = density
        val height = size.height.toDouble()
        val drag = 3.0
        val gravity = height * 0.8
        val velocity = speed * height
        val vx = cos(angle) * velocity
        val vy = sin(angle) * velocity
        val slowed = (1 - exp(-drag * time)) / drag
        val settled = max(0.0, time - 0.7)
        var x = (if (fromLeft) -10.0 * unit else size.width + 10.0 * unit) + vx * slowed
        val y = height + 10 * unit + gravity * time / drag + (vy - gravity / drag) * slowed
        x += sin(time * 3.2 + phase) * flutter * unit * min(1.0, settled)
        val fade = min(1.0, (CONFETTI_SECONDS - launch - time) / 0.7)
        if (y > height + 40 * unit || fade <= 0) return
        val alpha = fade.toFloat()
        val l = length * unit
        translate(x.toFloat(), y.toFloat()) {
            rotate(Math.toDegrees(spin * time + phase).toFloat(), Offset.Zero) {
                scale(cos(flip * time + phase).toFloat(), 1f, Offset.Zero) {
                    when (shape) {
                        0 -> drawRoundRect(colour, Offset(-l / 2, -l / 2), Size(l, l * 0.8f), CornerRadius(1.5f * unit), alpha = alpha)

                        1 -> drawRoundRect(colour, Offset(-l * 0.25f, -l), Size(l * 0.5f, l * 2), CornerRadius(1.5f * unit), alpha = alpha)

                        2 -> drawCircle(colour, l / 2.4f, Offset.Zero, alpha = alpha)

                        else -> {
                            val curl = Path().apply {
                                moveTo(-l, 0f)
                                cubicTo(-l / 3, -l, l / 3, l, l, 0f)
                            }
                            drawPath(curl, colour, alpha = alpha, style = Stroke(3 * unit, cap = StrokeCap.Round))
                        }
                    }
                }
            }
        }
    }

    companion object {
        fun burst(count: Int, colours: List<Color>): List<ConfettiPiece> {
            val random = Random(0x5EEDC0FE)
            fun next(from: Double, until: Double) = from + random.nextDouble() * (until - from)
            return List(count) { index ->
                val fromLeft = index % 2 == 0
                val tilt = next(52.0, 84.0)
                ConfettiPiece(
                    fromLeft = fromLeft,
                    angle = (if (fromLeft) 360 - tilt else 180 + tilt) * PI / 180,
                    speed = next(2.6, 4.4),
                    launch = next(0.0, 0.22),
                    shape = random.nextInt(4),
                    colour = colours[random.nextInt(colours.size)],
                    length = next(8.0, 16.0).toFloat(),
                    spin = next(-9.0, 9.0),
                    flip = next(4.0, 12.0),
                    flutter = next(14.0, 40.0),
                    phase = next(0.0, 2 * PI),
                )
            }
        }
    }
}
