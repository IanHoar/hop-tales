package com.hoptales.android.design

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun SpeakerGlyph(color: Color, size: Dp = 22.dp) {
    Canvas(Modifier.size(size)) {
        val unit = this.size.width / 24f
        val body = Path().apply {
            moveTo(3 * unit, 9 * unit)
            lineTo(7 * unit, 9 * unit)
            lineTo(12 * unit, 4.5f * unit)
            lineTo(12 * unit, 19.5f * unit)
            lineTo(7 * unit, 15 * unit)
            lineTo(3 * unit, 15 * unit)
            close()
        }
        drawPath(body, color)
        val stroke = Stroke(width = 2.2f * unit, cap = StrokeCap.Round)
        for (radius in listOf(4f, 7.5f)) {
            drawArc(
                color,
                startAngle = -50f,
                sweepAngle = 100f,
                useCenter = false,
                topLeft = Offset((12 - radius) * unit, (12 - radius) * unit),
                size = Size(radius * 2 * unit, radius * 2 * unit),
                style = stroke,
            )
        }
    }
}

@Composable
fun ChevronGlyph(color: Color, size: Dp = 16.dp) {
    Canvas(Modifier.size(size)) {
        val unit = this.size.width / 16f
        val path = Path().apply {
            moveTo(3 * unit, 6 * unit)
            lineTo(8 * unit, 11 * unit)
            lineTo(13 * unit, 6 * unit)
        }
        drawPath(path, color, style = Stroke(width = 2.5f * unit, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun GearGlyph(color: Color, size: Dp = 22.dp) {
    Canvas(Modifier.size(size)) {
        val unit = this.size.width / 24f
        for (tooth in 0 until 8) {
            rotate(tooth * 45f) {
                drawRoundRect(
                    color,
                    topLeft = Offset(10.25f * unit, 1.5f * unit),
                    size = Size(3.5f * unit, 5f * unit),
                    cornerRadius = CornerRadius(unit),
                )
            }
        }
        drawCircle(color, radius = 7.5f * unit, style = Stroke(width = 3f * unit))
        drawCircle(color, radius = 2.4f * unit)
    }
}
