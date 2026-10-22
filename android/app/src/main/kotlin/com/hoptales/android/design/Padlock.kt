package com.hoptales.android.design

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp

@Composable
fun PadlockGlyph(color: Color, hole: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val unit = size.width / 24f
        val shackle = Path().apply {
            moveTo(8 * unit, 11 * unit)
            lineTo(8 * unit, 8 * unit)
            arcTo(
                rect = Rect(Offset(12 * unit, 8 * unit), 4 * unit),
                startAngleDegrees = 180f,
                sweepAngleDegrees = 180f,
                forceMoveTo = false,
            )
            lineTo(16 * unit, 11 * unit)
        }
        drawPath(shackle, color, style = Stroke(width = 2.4f * unit, cap = StrokeCap.Round))
        drawRoundRect(color, Offset(5 * unit, 10.5f * unit), Size(14 * unit, 10 * unit), CornerRadius(2.5f * unit))
        drawCircle(hole, radius = 1.6f * unit, center = Offset(12 * unit, 14.6f * unit))
        drawRoundRect(hole, Offset(11.3f * unit, 14.6f * unit), Size(1.4f * unit, 3.4f * unit), CornerRadius(0.7f * unit))
    }
}

@Composable
fun PadlockSticker(size: Dp = 30.dp, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    Box(
        modifier
            .clearAndSetSemantics {}
            .rotate(-8f)
            .size(size)
            .dropShadow(CircleShape, Shadow(size * 0.1f, paper.shadow, offset = DpOffset(0.dp, size * 0.07f)))
            .background(paper.wash, CircleShape)
            .border(maxOf(2.dp, size * 0.09f), paper.rim, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        PadlockGlyph(paper.ink, paper.wash, Modifier.size(size * 0.6f))
    }
}
