package com.hoptales.android.design

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import kotlin.math.hypot
import kotlin.math.max

class Deckle(private val seed: Int = 1, private val jitter: Dp = 2.4.dp, private val step: Dp = 9.dp) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline {
        val jitter = with(density) { jitter.toPx() }
        val step = with(density) { step.toPx() }
        val random = Scatter(seed)
        val path = Path()
        val corners = listOf(Offset(0f, 0f), Offset(size.width, 0f), Offset(size.width, size.height), Offset(0f, size.height))
        val inwards = listOf(Offset(0f, 1f), Offset(-1f, 0f), Offset(0f, -1f), Offset(1f, 0f))
        var started = false
        for (side in 0 until 4) {
            val start = corners[side]
            val end = corners[(side + 1) % 4]
            val count = max(2, (hypot(end.x - start.x, end.y - start.y) / step).toInt())
            for (index in 0 until count) {
                val fraction = index.toFloat() / count
                val bite = random.next() * jitter
                val x = start.x + (end.x - start.x) * fraction + inwards[side].x * bite
                val y = start.y + (end.y - start.y) * fraction + inwards[side].y * bite
                if (started) path.lineTo(x, y) else path.moveTo(x, y)
                started = true
            }
        }
        path.close()
        return Outline.Generic(path)
    }
}

private class Scatter(seed: Int) {
    private var state: ULong = seed.toLong().toULong() * 0x9E3779B97F4A7C15uL or 1uL

    fun next(): Float {
        state = state xor (state shl 13)
        state = state xor (state shr 7)
        state = state xor (state shl 17)
        return (state % 10_000uL).toFloat() / 10_000f
    }
}

@Composable
fun PaperLabel(modifier: Modifier = Modifier, seed: Int = 1, content: @Composable () -> Unit) {
    val paper = LocalPaper.current
    val shape = Deckle(seed)
    Box(
        modifier
            .dropShadow(shape, Shadow(3.5.dp, paper.shadow, offset = DpOffset(0.dp, 4.dp)))
            .background(paper.paper, shape),
    ) { content() }
}
