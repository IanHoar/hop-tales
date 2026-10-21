package com.hoptales.android.world

import android.content.res.AssetManager
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.roundToInt

data class PropPlacement(val asset: String, val x: Float, val depth: Float)

object MeadowProps {
    val assets = listOf("prop-bush", "prop-fence", "prop-flowers", "prop-mushrooms", "prop-oak", "prop-signpost")
    const val SEGMENT_WIDTH = 900f
    private const val SEED = 7919L
    private const val SIZE_BASE = 0.62f
    private const val SIZE_DEPTH = 0.3f
    private const val GROUND_BASE = 300f
    private const val GROUND_DEPTH = 90f
    private const val ANCHOR_Y = 0.04f

    fun placements(segment: Int): List<PropPlacement> {
        val random = SeededRandom(segment * SEED)
        val count = random.next(3uL).toInt()
        val span = SEGMENT_WIDTH / max(count, 1)
        return List(count) { slot ->
            val asset = assets[random.next(assets.size.toULong()).toInt()]
            val x = slot * span + random.nextDouble(0.15, 0.85).toFloat() * span
            val depth = random.nextDouble(0.0, 1.0).toFloat()
            PropPlacement(asset, x, depth)
        }
    }

    fun load(assets: AssetManager): Map<String, ImageBitmap> =
        this.assets.mapNotNull { name -> Art.image(assets, name)?.let { name to it } }.toMap()

    fun DrawScope.drawProps(art: Map<String, ImageBitmap>, layout: MeadowLayout, progress: Float, tint: Color) {
        val scale = layout.scale(MeadowLayer.NEAR)
        val width = SEGMENT_WIDTH * scale
        if (width <= 0f || art.isEmpty()) return
        val first = floor(progress / width).toInt() - 1
        val last = floor((progress + layout.width) / width).toInt() + 1
        val filter = if (tint == Color.White) null else ColorFilter.tint(tint, BlendMode.Modulate)
        val placed = (first..last).flatMap { segment -> placements(segment).map { segment to it } }.sortedBy { it.second.depth }
        for ((segment, placement) in placed) {
            val image = art[placement.asset] ?: continue
            val size = scale * (SIZE_BASE + SIZE_DEPTH * placement.depth)
            val drawn = IntSize((image.width * size).roundToInt(), (image.height * size).roundToInt())
            val centre = segment * width + placement.x * scale - progress
            val ground = layout.top(MeadowLayer.NEAR) + (GROUND_BASE + GROUND_DEPTH * placement.depth) * scale
            drawImage(
                image,
                dstOffset = IntOffset((centre - drawn.width / 2f).roundToInt(), (ground - drawn.height * (1 - ANCHOR_Y)).roundToInt()),
                dstSize = drawn,
                colorFilter = filter,
                filterQuality = FilterQuality.Medium,
            )
        }
    }
}
