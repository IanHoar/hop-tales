package com.hoptales.android.reading

import android.content.res.AssetManager
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import com.hoptales.android.design.Palette
import com.hoptales.android.world.Art
import com.hoptales.content.Story
import com.hoptales.content.StoryProps
import com.hoptales.reading.PropItem
import com.hoptales.reading.PropPose
import kotlin.math.roundToInt

class PropArt(private val images: Map<String, ImageBitmap>) {
    operator fun get(name: String): ImageBitmap? = images[name]

    companion object {
        fun load(assets: AssetManager, story: Story, props: StoryProps): PropArt {
            val names = story.sentences.flatMap { it.events }.map { it.prop }.toSet()
            val images = mutableMapOf<String, ImageBitmap>()
            for (name in names) {
                val prop = props.named(name) ?: continue
                val frames = if (prop.motion.frames == 2) listOf("cast-$name-1", "cast-$name-2") else listOf("cast-$name")
                for (frame in frames) Art.image(assets, frame)?.let { images[frame] = it }
            }
            return PropArt(images)
        }
    }
}

object ThoughtBubble {
    const val WIDTH = 112f
    const val HEIGHT = 96f
}

fun DrawScope.drawProps(items: List<PropItem>, art: PropArt, now: Double?, unit: Float, tint: Color, palette: Palette) {
    for (item in items) {
        if (item.thought) drawThought(item, art, now, unit, tint, palette) else drawFigure(item, art, now, unit, tint)
    }
}

private fun DrawScope.drawFigure(item: PropItem, art: PropArt, now: Double?, unit: Float, tint: Color) {
    val pose = PropPose.at(item, item.elapsed(now), item.exit(now), size.width, unit)
    if (pose.opacity <= 0f) return
    val image = art[item.art(pose.frame)] ?: return
    val height = item.height.toFloat() * unit
    val width = height * image.width / image.height
    val centre = Offset(item.anchor + pose.dx + item.spread * height * 1.3f, item.baseline - height / 2 + pose.dy)
    val bottom = Offset(centre.x, centre.y + height / 2)
    withTransform({
        rotate(pose.rotation, if (pose.pivotsAtBase) bottom else centre)
        scale(pose.scale, pose.scale, bottom)
        if (pose.flip) scale(-1f, 1f, centre)
    }) {
        drawSticker(image, centre, width, height, pose.opacity, tint)
    }
}

private fun DrawScope.drawThought(item: PropItem, art: PropArt, now: Double?, unit: Float, tint: Color, palette: Palette) {
    val pose = PropPose.thinking(item.elapsed(now), item.exit(now), unit)
    if (pose.opacity <= 0f) return
    val left = item.anchor
    val bottom = item.baseline + pose.dy
    val top = bottom - ThoughtBubble.HEIGHT * unit
    val fill = multiply(palette.paperChip, tint)
    val rim = multiply(palette.paperRim, tint)
    val bounds = Rect(left, top, left + ThoughtBubble.WIDTH * unit, bottom).inflate(8 * unit)
    withTransform({ scale(pose.scale, pose.scale, Offset(left, bottom)) }) {
        drawIntoCanvas { it.saveLayer(bounds, Paint().apply { alpha = pose.opacity.coerceIn(0f, 1f) }) }
        val chip = Rect(Offset(left + 16 * unit, top), Size(96 * unit, 66 * unit))
        drawIntoCanvas { canvas ->
            val shadow = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
                color = fill.toArgb()
                setShadowLayer(4 * unit, 0f, 3 * unit, multiply(palette.paperShadow, tint).toArgb())
            }
            canvas.nativeCanvas.drawOval(chip.left, chip.top, chip.right, chip.bottom, shadow)
        }
        drawOval(rim, chip.deflate(1.5f * unit).topLeft, chip.deflate(1.5f * unit).size, style = Stroke(3 * unit))
        art[item.art(1)]?.let { image ->
            val height = 46 * unit
            drawSticker(image, chip.center, height * image.width / image.height, height, 1f, tint)
        }
        bead(Offset(left + 20 * unit, bottom - 20 * unit), 8 * unit, 2 * unit, fill, rim)
        bead(Offset(left + 4.5f * unit, bottom - 4.5f * unit), 4.5f * unit, 1.5f * unit, fill, rim)
        drawIntoCanvas { it.restore() }
    }
}

private fun DrawScope.bead(centre: Offset, radius: Float, line: Float, fill: Color, rim: Color) {
    drawCircle(fill, radius, centre)
    drawCircle(rim, radius - line / 2, centre, style = Stroke(line))
}

private fun DrawScope.drawSticker(image: ImageBitmap, centre: Offset, width: Float, height: Float, opacity: Float, tint: Color) {
    drawImage(
        image = image,
        dstOffset = IntOffset((centre.x - width / 2).roundToInt(), (centre.y - height / 2).roundToInt()),
        dstSize = IntSize(width.roundToInt(), height.roundToInt()),
        alpha = opacity.coerceIn(0f, 1f),
        colorFilter = if (tint == Color.White) null else ColorFilter.tint(tint, BlendMode.Modulate),
        filterQuality = FilterQuality.Medium,
    )
}
