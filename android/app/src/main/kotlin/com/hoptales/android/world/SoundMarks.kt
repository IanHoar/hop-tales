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
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.content.SoundMark

object SoundMarks {
    val examples = listOf("cat", "ship", "lake")

    fun height(size: Float) = size * 0.3f

    fun edges(layout: TextLayoutResult, start: Int, length: Int): List<Float> {
        val origin = layout.getHorizontalPosition(start, usePrimaryDirection = true)
        return (0..length).map { layout.getHorizontalPosition(start + it, usePrimaryDirection = true) - origin }
    }
}

@Composable
fun SoundMarksExamples(size: Float = 30f, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    val phonics = (LocalContext.current.applicationContext as HopTalesApplication).phonics
    val style = LocalTypography.current.word(size.sp)
    val density = LocalDensity.current
    val measurer = rememberTextMeasurer()
    Row(
        modifier.fillMaxWidth().clearAndSetSemantics { contentDescription = "Examples: cat, ship and lake, with a dot under each sound." },
        horizontalArrangement = Arrangement.spacedBy((size * 0.9f).dp, Alignment.CenterHorizontally),
    ) {
        for (word in SoundMarks.examples) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy((size * 0.08f).dp)) {
                Text(word, style = style, color = paper.ink)
                val marks = phonics.soundMarks(word)
                if (marks != null) {
                    val edges = SoundMarks.edges(measurer.measure(word, style), 0, word.length)
                    Canvas(Modifier.size(with(density) { edges.last().toDp() }, SoundMarks.height(size).dp)) {
                        drawSoundMarks(marks, edges, size.dp.toPx(), paper.ink.copy(alpha = 0.8f))
                    }
                }
            }
        }
    }
}

fun DrawScope.drawSoundMarks(
    marks: List<SoundMark>,
    edges: List<Float>,
    size: Float,
    color: Color,
    origin: Offset = Offset.Zero,
    blendMode: BlendMode = BlendMode.SrcOver,
) {
    val y = origin.y + size * 0.08f
    fun edge(index: Int) = origin.x + edges[index]
    fun centre(index: Int) = (edge(index) + edge(index + 1)) / 2
    for (mark in marks) {
        when (mark.kind) {
            SoundMark.Kind.BUTTON -> drawCircle(
                color,
                radius = size * 0.065f,
                center = Offset(centre(mark.start), y),
                blendMode = blendMode,
            )

            SoundMark.Kind.BAR -> {
                val inset = size * 0.07f
                val width = maxOf(size * 0.1f, edges[mark.end] - edges[mark.start] - inset * 2)
                drawRoundRect(
                    color,
                    topLeft = Offset(edge(mark.start) + inset, y - size * 0.04f),
                    size = Size(width, size * 0.08f),
                    cornerRadius = CornerRadius(size * 0.04f),
                    blendMode = blendMode,
                )
            }

            SoundMark.Kind.SPLIT -> {
                val from = Offset(centre(mark.start), y)
                val to = Offset(centre(mark.end - 1), y)
                val path = Path().apply {
                    moveTo(from.x, from.y)
                    quadraticTo((from.x + to.x) / 2, y + size * 0.3f, to.x, to.y)
                }
                drawPath(path, color, style = Stroke(width = size * 0.06f, cap = StrokeCap.Round), blendMode = blendMode)
            }
        }
    }
}
