package com.hoptales.android.design

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathOperation
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.addOutline
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.platform.LocalGraphicsContext
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection

private class RimShape(private val shape: Shape, private val rim: Dp) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline {
        val width = with(density) { rim.toPx() }
        val outer = Path().apply { addOutline(shape.createOutline(size, layoutDirection, density)) }
        val inner = Path().apply {
            addOutline(shape.createOutline(Size(size.width - width * 2, size.height - width * 2), layoutDirection, density))
            translate(Offset(width, width))
        }
        return Outline.Generic(Path.combine(PathOperation.Difference, outer, inner))
    }

    override fun equals(other: Any?): Boolean = other is RimShape && other.shape == shape && other.rim == rim

    override fun hashCode(): Int = shape.hashCode() * 31 + rim.hashCode()
}

@Composable
fun rememberShadow(shape: Shape, shadow: Shadow): Painter {
    val context = LocalGraphicsContext.current.shadowContext
    return remember(context, shape, shadow) { context.createDropShadowPainter(shape, shadow) }
}

@Composable
fun rememberRimShadow(shape: Shape, rim: Dp, shadow: Shadow): Painter = rememberShadow(RimShape(shape, rim), shadow)

fun DrawScope.drawShadow(painter: Painter) {
    with(painter) { draw(size) }
}

@Composable
fun Modifier.contentShadow(shadow: Shadow): Modifier {
    val layer = rememberGraphicsLayer()
    return drawWithContent {
        val radius = shadow.radius.toPx()
        layer.record { this@drawWithContent.drawContent() }
        layer.renderEffect = if (radius > 0f) BlurEffect(radius, radius, TileMode.Decal) else null
        layer.colorFilter = ColorFilter.tint(shadow.color, BlendMode.SrcIn)
        translate(shadow.offset.x.toPx(), shadow.offset.y.toPx()) { drawLayer(layer) }
        drawContent()
    }
}
