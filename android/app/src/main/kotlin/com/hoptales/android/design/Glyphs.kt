package com.hoptales.android.design

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
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
fun UpDownChevronGlyph(color: Color, size: Dp = 16.dp) {
    Canvas(Modifier.size(size)) {
        val unit = this.size.width / 16f
        val path = Path().apply {
            moveTo(4.5f * unit, 6 * unit)
            lineTo(8 * unit, 2.5f * unit)
            lineTo(11.5f * unit, 6 * unit)
            moveTo(4.5f * unit, 10 * unit)
            lineTo(8 * unit, 13.5f * unit)
            lineTo(11.5f * unit, 10 * unit)
        }
        drawPath(path, color, style = Stroke(width = 2.2f * unit, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun GearGlyph(color: Color, size: Dp = 22.dp) {
    Canvas(Modifier.size(size)) {
        val unit = this.size.width / 24f
        val centre = Offset(12 * unit, 12 * unit)
        val outline = Path()
        val steps = GEAR_TEETH * GEAR_PROFILE.size
        for (step in 0..steps) {
            val (offset, radius) = GEAR_PROFILE[step % GEAR_PROFILE.size]
            val angle = ((step / GEAR_PROFILE.size) * (360f / GEAR_TEETH) + offset - 90f) * PI.toFloat() / 180f
            val point = centre + Offset(cos(angle), sin(angle)) * (radius * unit)
            if (step == 0) outline.moveTo(point.x, point.y) else outline.lineTo(point.x, point.y)
        }
        outline.close()
        val stroke = Stroke(width = 2f * unit, cap = StrokeCap.Round, join = StrokeJoin.Round)
        drawPath(outline, color, style = stroke)
        drawCircle(color, radius = 3.4f * unit, center = centre, style = stroke)
    }
}

private const val GEAR_TEETH = 8
private val GEAR_PROFILE = listOf(
    -22.5f to 8.1f,
    -15f to 8.1f,
    -10f to 10.6f,
    0f to 10.6f,
    10f to 10.6f,
    15f to 8.1f,
)

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

    val again = stroked(
        "again",
        "M19.27,9A8.4,8.4 0 1,1 12,4.8H14.6M11.6,1.8L14.6,4.8 11.6,7.8",
        strokeWidth = 3.2f,
    )

    val book = filled(
        "book",
        "M11,5.9C9.1,4.6 6.5,4 3.6,4.3 2.9,4.4 2.4,4.9 2.4,5.6v12c0,0.7 0.6,1.2 1.3,1.1 2.8,-0.3 5.4,0.3 7.3,1.6z" +
            "M13,5.9C14.9,4.6 17.5,4 20.4,4.3c0.7,0.1 1.2,0.6 1.2,1.3v12c0,0.7 -0.6,1.2 -1.3,1.1 -2.8,-0.3 -5.4,0.3 -7.3,1.6z",
    )

    val house = filled(
        "house",
        "M12,1.6L23,11.4H20.3V20.4a1.6,1.6 0 0,1 -1.6,1.6H14.6V16.4a1.2,1.2 0 0,0 -1.2,-1.2H10.6a1.2,1.2 0 0,0 -1.2,1.2V22" +
            "H5.3a1.6,1.6 0 0,1 -1.6,-1.6V11.4H1z",
    )

    val mic = filled(
        "mic",
        "M12,14c1.66,0 3,-1.34 3,-3V5c0,-1.66 -1.34,-3 -3,-3S9,3.34 9,5v6c0,1.66 1.34,3 3,3z" +
            "M17.3,11c0,3 -2.54,5.1 -5.3,5.1S6.7,14 6.7,11H5c0,3.41 2.72,6.23 6,6.72V21h2v-3.28c3.28,-0.48 6,-3.3 6,-6.72h-1.7z",
    )

    val micSlash = stroked(
        "micSlash",
        "M12,2.5a3,3 0 0,1 3,3V11a3,3 0 0,1 -6,0V5.5a3,3 0 0,1 3,-3zM5.5,11a6.5,6.5 0 0,0 13,0M12,17.5V21.5M8.5,21.5H15.5" +
            "M3.5,2.5L20.5,21.5",
        strokeWidth = 1.2f,
    )

    val phoneSlash = stroked(
        "phoneSlash",
        "M9,2H15a2.5,2.5 0 0,1 2.5,2.5V19.5a2.5,2.5 0 0,1 -2.5,2.5H9a2.5,2.5 0 0,1 -2.5,-2.5V4.5A2.5,2.5 0 0,1 9,2z" +
            "M10.5,4.75H13.5M3.5,2.5L20.5,21.5",
        strokeWidth = 1.2f,
    )

    val backspace = stroked(
        "backspace",
        "M8,5H20a1.5,1.5 0 0,1 1.5,1.5v11a1.5,1.5 0 0,1 -1.5,1.5H8L2.5,12zM11.5,9.5L16.5,14.5M16.5,9.5L11.5,14.5",
        strokeWidth = 2f,
    )

    val check = filled("check", "M9,16.17L4.83,12l-1.42,1.41L9,19 21,7l-1.41,-1.41z")

    val counterclockwise = stroked("counterclockwise", "M5,9.4A7.5,7.5 0 1,0 12,4.5H9.5M11.8,1.6L9,4.5 11.8,7.4")

    val uturnBackward = stroked("uturnBackward", "M8.5,4L4,8.5 8.5,13M4,8.5H15a4.75,4.75 0 0,1 0,9.5H11")

    val lockOpen = stroked(
        "lockOpen",
        "M4,11.5h11a1.5,1.5 0 0,1 1.5,1.5v6.5a1.5,1.5 0 0,1 -1.5,1.5H4a1.5,1.5 0 0,1 -1.5,-1.5V13a1.5,1.5 0 0,1 1.5,-1.5z" +
            "M13,11.5V7.5a3.75,3.75 0 0,1 7.5,0V9.5",
    )

    val share = stroked(
        "share",
        "M12,14.5V3M8.25,6.5L12,2.75 15.75,6.5M8.5,9.5H7a1.5,1.5 0 0,0 -1.5,1.5v8.5a1.5,1.5 0 0,0 1.5,1.5h10" +
            "a1.5,1.5 0 0,0 1.5,-1.5V11a1.5,1.5 0 0,0 -1.5,-1.5H15.5",
    )

    val trash = stroked(
        "trash",
        "M3.5,6.5H20.5M9,6.5V4.5a1,1 0 0,1 1,-1h4a1,1 0 0,1 1,1v2M5.5,6.5L6.6,19.6a1.5,1.5 0 0,0 1.5,1.4h7.8" +
            "a1.5,1.5 0 0,0 1.5,-1.4L18.5,6.5",
    )

    private fun filled(name: String, data: String): ImageVector = ImageVector.Builder(name, 24.dp, 24.dp, 24f, 24f)
        .addPath(addPathNodes(data), fill = SolidColor(Color.Black))
        .build()

    private fun stroked(name: String, data: String, strokeWidth: Float = 2.2f): ImageVector =
        ImageVector.Builder(name, 24.dp, 24.dp, 24f, 24f)
            .addPath(
                addPathNodes(data),
                stroke = SolidColor(Color.Black),
                strokeLineWidth = strokeWidth,
                strokeLineCap = StrokeCap.Round,
                strokeLineJoin = StrokeJoin.Round,
            )
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
