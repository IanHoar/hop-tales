package com.hoptales.android.world

import android.content.res.AssetManager
import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import com.hoptales.content.Friend
import kotlin.math.roundToInt

class IntroArt(private val images: Map<String, ImageBitmap>) {
    operator fun get(name: String): ImageBitmap? = images[name]

    companion object {
        private val names = MeadowLayer.entries.map { it.asset(Friend.HARE) } +
            listOf("sky-sun", "sky-cloud-2", "sky-cloud-3", "sky-star-1", "sky-star-2", "sky-star-3") +
            listOf(FRONT, SIDE, HOP)

        fun load(assets: AssetManager): IntroArt {
            val images = names.mapNotNull { name -> Art.image(assets, name)?.let { name to it } }.toMap()
            images.values.forEach(ImageBitmap::prepareToDraw)
            return IntroArt(images)
        }
    }
}

@Composable
fun IntroScene(art: IntroArt, time: () -> Double, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val layout = IntroLayout(size.width, size.height, density)
        drawIntro(art, layout, IntroFrame.at(time()))
    }
}

fun DrawScope.drawIntro(art: IntroArt, layout: IntroLayout, frame: IntroFrame) {
    drawGradient(IntroLayout.night, 1f)
    drawGradient(IntroLayout.dawn, frame.dawn)
    drawGradient(IntroLayout.day, frame.day)
    for (star in layout.stars) {
        val image = art[star.asset] ?: continue
        drawSprite(image, star.x, star.y, star.width, star.width * MeadowStars.ASPECT, frame.stars)
    }
    val sun = art["sky-sun"]
    val sunHeight = sun?.let { layout.sunWidth * it.height / it.width } ?: 0f
    val sunY = layout.sunCentreY(sunHeight, frame.sunRise)
    val centre = layout.width / 2
    if (frame.glow > 0f) {
        val radius = layout.glowWidth / 2 * frame.glowScale
        drawCircle(
            Brush.radialGradient(
                0f to GLOW_CORE,
                0.55f to GLOW_EDGE,
                1f to GLOW_EDGE.copy(alpha = 0f),
                center = Offset(centre, sunY),
                radius = radius,
            ),
            radius = radius,
            center = Offset(centre, sunY),
            alpha = frame.glow,
        )
    }
    sun?.let { drawSprite(it, centre, sunY, layout.sunWidth, sunHeight, 1f) }
    for (cloud in layout.clouds) {
        val image = art[cloud.asset] ?: continue
        val height = cloud.width * image.height / image.width
        drawSprite(image, cloud.x + cloud.drift * frame.cloudDrift, cloud.top + height / 2, cloud.width, height, frame.clouds)
    }
    drawLand(art, layout, frame)
    drawHares(art, layout, frame)
}

private fun DrawScope.drawGradient(colours: List<Long>, alpha: Float) {
    if (alpha <= 0f) return
    val stops = colours.mapIndexed { index, colour -> listOf(0f, GRADIENT_MIDDLE, 1f)[index] to Color(colour) }
    drawRect(Brush.verticalGradient(*stops.toTypedArray()), alpha = alpha.coerceAtMost(1f))
}

private fun DrawScope.drawLand(art: IntroArt, layout: IntroLayout, frame: IntroFrame) {
    translate(top = layout.landDrop * frame.landDrop) {
        for (layer in MeadowLayer.entries) {
            val image = art[layer.asset(Friend.HARE)] ?: continue
            val filter = IntroLayout.landMatrix(frame.saturation, frame.landTints[layer.ordinal])?.let {
                ColorFilter.colorMatrix(ColorMatrix(it))
            }
            val width = layout.tileWidth(layer)
            val offset = layout.offset(layer)
            for (index in 0 until layout.tileCount(layer)) {
                drawImage(
                    image = image,
                    dstOffset = IntOffset((offset + index * width).roundToInt(), layout.top(layer).roundToInt()),
                    dstSize = IntSize(width.roundToInt() + 1, layout.tileHeight(layer).roundToInt()),
                    colorFilter = filter,
                    filterQuality = FilterQuality.Medium,
                )
            }
        }
    }
}

private fun DrawScope.drawHares(art: IntroArt, layout: IntroLayout, frame: IntroFrame) {
    val centre = layout.width / 2
    val ground = layout.ground
    art[FRONT]?.let { image ->
        val height = layout.hareFrontHeight
        drawStanding(image, centre, ground, height * image.width / image.height, height, frame.front)
    }
    art[SIDE]?.let { image ->
        val height = layout.hareSideHeight
        val width = height * image.width / image.height
        drawStanding(image, centre - width * 0.02f, ground, width, height, frame.side)
    }
    val hop = art[HOP] ?: return
    if (frame.run <= 0f) return
    val width = layout.hareRunWidth
    val height = layout.hareRunHeight
    val x = centre + layout.runDistance * frame.runTravel
    val bottom = ground + layout.hareRunFeet
    val cell = IntroLayout.HOP_FRAME_WIDTH.roundToInt()
    drawImage(
        image = hop,
        srcOffset = IntOffset(cell * frame.runFrame, 0),
        srcSize = IntSize(cell, hop.height),
        dstOffset = IntOffset((x - width / 2).roundToInt(), (bottom - height).roundToInt()),
        dstSize = IntSize(width.roundToInt(), height.roundToInt()),
        alpha = frame.run,
        filterQuality = FilterQuality.Medium,
    )
}

private fun DrawScope.drawStanding(image: ImageBitmap, x: Float, bottom: Float, width: Float, height: Float, pose: HarePose) {
    if (pose.alpha <= 0f) return
    scale(pose.scaleX, pose.scaleY, pivot = Offset(x, bottom)) {
        drawSprite(image, x, bottom - height / 2, width, height, pose.alpha)
    }
}

private fun DrawScope.drawSprite(image: ImageBitmap, x: Float, y: Float, width: Float, height: Float, alpha: Float) {
    if (alpha <= 0f || width <= 0f) return
    drawImage(
        image = image,
        dstOffset = IntOffset((x - width / 2).roundToInt(), (y - height / 2).roundToInt()),
        dstSize = IntSize(width.roundToInt(), height.roundToInt()),
        alpha = alpha.coerceAtMost(1f),
        filterQuality = FilterQuality.Medium,
    )
}

private const val FRONT = "hare-front-sit"
private const val SIDE = "look-hare-scarf"
private const val HOP = "look-hare-scarf-hop"
private val GLOW_CORE = Color(1f, 224 / 255f, 160 / 255f, 0.85f)
private val GLOW_EDGE = Color(1f, 210 / 255f, 150 / 255f, 0.35f)
