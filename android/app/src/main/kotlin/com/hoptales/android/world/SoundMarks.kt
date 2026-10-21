package com.hoptales.android.world

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalTypography

enum class SoundMarkKind { BUTTON, BAR, SPLIT }

data class SoundMark(val start: Int, val end: Int, val kind: SoundMarkKind)

private val examples = listOf(
    "cat" to listOf(SoundMark(0, 1, SoundMarkKind.BUTTON), SoundMark(1, 2, SoundMarkKind.BUTTON), SoundMark(2, 3, SoundMarkKind.BUTTON)),
    "ship" to listOf(SoundMark(0, 2, SoundMarkKind.BAR), SoundMark(2, 3, SoundMarkKind.BUTTON), SoundMark(3, 4, SoundMarkKind.BUTTON)),
    "lake" to listOf(SoundMark(0, 1, SoundMarkKind.BUTTON), SoundMark(1, 4, SoundMarkKind.SPLIT), SoundMark(2, 3, SoundMarkKind.BUTTON)),
)

@Composable
fun SoundMarksExamples(size: Float = 30f, modifier: Modifier = Modifier) {
    val palette = LocalPalette.current
    val style = LocalTypography.current.word(size.sp)
    val density = LocalDensity.current
    val measurer = rememberTextMeasurer()
    Row(
        modifier.fillMaxWidth().clearAndSetSemantics { contentDescription = "Examples: cat, ship and lake, with a dot under each sound." },
        horizontalArrangement = Arrangement.spacedBy((size * 0.9f).dp, Alignment.CenterHorizontally),
    ) {
        for ((word, marks) in examples) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(word, style = style, color = palette.ink)
                val layout = measurer.measure(word, style)
                val edges = (0..word.length).map { if (it == 0) 0f else layout.getBoundingBox(it - 1).right }
                val width = with(density) { edges.last().toDp() }
                Canvas(Modifier.size(width, with(density) { (size * 0.3f).sp.toDp() })) {
                    for (mark in marks) drawMark(mark, edges, size.sp.toPx(), palette.ink.copy(alpha = 0.8f))
                }
            }
        }
    }
}

private fun DrawScope.drawMark(mark: SoundMark, edges: List<Float>, size: Float, color: Color) {
    val y = size * 0.08f
    fun centre(index: Int) = (edges[index] + edges[index + 1]) / 2
    when (mark.kind) {
        SoundMarkKind.BUTTON -> drawCircle(color, radius = size * 0.065f, center = Offset(centre(mark.start), y))

        SoundMarkKind.BAR -> {
            val inset = size * 0.07f
            val width = maxOf(size * 0.1f, edges[mark.end] - edges[mark.start] - inset * 2)
            drawRoundRect(
                color,
                topLeft = Offset(edges[mark.start] + inset, y - size * 0.04f),
                size = Size(width, size * 0.08f),
                cornerRadius = CornerRadius(size * 0.04f),
            )
        }

        SoundMarkKind.SPLIT -> {
            val from = Offset(centre(mark.start), y)
            val to = Offset(centre(mark.end - 1), y)
            val path = Path().apply {
                moveTo(from.x, from.y)
                quadraticTo((from.x + to.x) / 2, y + size * 0.3f, to.x, to.y)
            }
            drawPath(path, color, style = Stroke(width = size * 0.06f, cap = StrokeCap.Round))
        }
    }
}
