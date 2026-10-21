package com.hoptales.android.design

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.RenderEffect
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.addOutline
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.layer.GraphicsLayer
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.unit.Dp

@Composable
fun Modifier.paperShading(shape: Shape, fill: Color, rim: Color, rimWidth: Dp, shadow: Shadow): Modifier {
    val back = rememberGraphicsLayer()
    val content = rememberGraphicsLayer()
    val over = rememberGraphicsLayer()
    return drawWithContent {
        val path = Path().apply { addOutline(shape.createOutline(size, layoutDirection, this@drawWithContent)) }
        val stroke = Stroke(rimWidth.toPx() * 2)
        val sigma = shadow.radius.toPx() * SWIFTUI_SIGMA_PER_RADIUS
        val blur = ((sigma - BLUR_SIGMA_BIAS) / BLUR_SIGMA_SCALE).coerceAtLeast(0f)
        val effect = if (blur > 0f) BlurEffect(blur, blur, TileMode.Decal) else null
        val offset = Offset(shadow.offset.x.toPx(), shadow.offset.y.toPx())
        drawShadowed(back, effect, shadow.color, offset) { drawPath(path, fill) }
        drawShadowed(content, effect, shadow.color, offset) { this@drawWithContent.drawContent() }
        drawShadowed(over, effect, shadow.color, offset) { clipPath(path) { drawPath(path, rim, style = stroke) } }
    }
}

private fun DrawScope.drawShadowed(
    layer: GraphicsLayer,
    effect: RenderEffect?,
    colour: Color,
    offset: Offset,
    block: DrawScope.() -> Unit,
) {
    layer.record { this@drawShadowed.block() }
    layer.renderEffect = effect
    layer.colorFilter = ColorFilter.tint(colour, BlendMode.SrcIn)
    translate(offset.x, offset.y) { drawLayer(layer) }
    block()
}

private const val SWIFTUI_SIGMA_PER_RADIUS = 1f
private const val BLUR_SIGMA_SCALE = 0.57735f
private const val BLUR_SIGMA_BIAS = 0.5f
