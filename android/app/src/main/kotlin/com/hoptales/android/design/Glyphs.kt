package com.hoptales.android.design

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.addPathNodes
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

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

object Glyphs {
    val chevronLeft: ImageVector = ImageVector.Builder("chevronLeft", 24.dp, 24.dp, 24f, 24f).apply {
        path(
            stroke = SolidColor(Color.Black),
            strokeLineWidth = 3.4f,
            strokeLineCap = StrokeCap.Round,
            strokeLineJoin = StrokeJoin.Round,
        ) {
            moveTo(15f, 4.5f)
            lineTo(7.5f, 12f)
            lineTo(15f, 19.5f)
        }
    }.build()

    val again = filled(
        "again",
        "M17.65,6.35C16.2,4.9 14.21,4 12,4c-4.42,0 -7.99,3.58 -7.99,8s3.57,8 7.99,8c3.73,0 6.84,-2.55 7.73,-6h-2.08" +
            "c-0.82,2.33 -3.04,4 -5.65,4 -3.31,0 -6,-2.69 -6,-6s2.69,-6 6,-6c1.66,0 3.14,0.69 4.22,1.78L13,11h7V4l-2.35,2.35z",
    )

    val book = filled(
        "book",
        "M18,2H6c-1.1,0 -2,0.9 -2,2v16c0,1.1 0.9,2 2,2h12c1.1,0 2,-0.9 2,-2V4c0,-1.1 -0.9,-2 -2,-2zM6,4h5v8l-2.5,-1.5L6,12V4z",
    )

    val house = filled("house", "M10,20v-6h4v6h5v-8h3L12,3 2,12h3v8z")

    val mic = filled(
        "mic",
        "M12,14c1.66,0 3,-1.34 3,-3V5c0,-1.66 -1.34,-3 -3,-3S9,3.34 9,5v6c0,1.66 1.34,3 3,3z" +
            "M17.3,11c0,3 -2.54,5.1 -5.3,5.1S6.7,14 6.7,11H5c0,3.41 2.72,6.23 6,6.72V21h2v-3.28c3.28,-0.48 6,-3.3 6,-6.72h-1.7z",
    )

    val check = filled("check", "M9,16.17L4.83,12l-1.42,1.41L9,19 21,7l-1.41,-1.41z")

    private fun filled(name: String, data: String): ImageVector = ImageVector.Builder(name, 24.dp, 24.dp, 24f, 24f)
        .addPath(addPathNodes(data), fill = SolidColor(Color.Black))
        .build()
}

class Star(private val points: Int = 5, private val innerRatio: Float = 0.42f) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline {
        val centre = Offset(size.width / 2, size.height / 2)
        val outer = min(size.width, size.height) / 2
        val path = Path()
        for (step in 0 until points * 2) {
            val radius = if (step % 2 == 0) outer else outer * innerRatio
            val angle = -PI / 2 + step * PI / points
            val x = centre.x + radius * cos(angle).toFloat()
            val y = centre.y + radius * sin(angle).toFloat()
            if (step == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()
        return Outline.Generic(path)
    }
}
