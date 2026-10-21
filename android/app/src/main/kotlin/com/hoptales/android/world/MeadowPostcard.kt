package com.hoptales.android.world

import android.content.res.AssetManager
import androidx.compose.foundation.Image
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.CanvasDrawScope
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import com.hoptales.content.Friend
import com.hoptales.content.Mood
import kotlin.math.roundToInt

@Composable
fun MeadowPostcard(mood: Mood, modifier: Modifier = Modifier) {
    val assets = LocalContext.current.assets
    val image = remember(mood) { MeadowPostcards.image(assets, mood) }
    Image(
        image,
        contentDescription = null,
        modifier = modifier,
        contentScale = ContentScale.Crop,
        alignment = Alignment.BottomCenter,
        filterQuality = FilterQuality.Medium,
    )
}

object MeadowPostcards {
    private const val WIDTH = 390
    private const val HEIGHT = 520
    private const val FAR_ANCHOR = 986f
    private val cache = mutableMapOf<Mood, ImageBitmap>()

    fun image(assets: AssetManager, mood: Mood): ImageBitmap = cache.getOrPut(mood) { render(assets, mood) }

    private fun render(assets: AssetManager, mood: Mood): ImageBitmap {
        val look = SkyLook.of(mood)
        val layers = meadowLayers(assets, Friend.HARE)
        val sky = SkyLayout(WIDTH.toFloat(), HEIGHT.toFloat(), 1f, HEIGHT - FAR_ANCHOR * SkyLayout.BASE_SCALE)
        val bitmap = ImageBitmap(WIDTH, HEIGHT)
        CanvasDrawScope().draw(Density(1f), LayoutDirection.Ltr, Canvas(bitmap), Size(WIDTH.toFloat(), HEIGHT.toFloat())) {
            drawSky(look, sky, SkyArt.load(assets), MeadowStars.field(sky), 0.0, still = true)
            for (layer in MeadowLayer.entries) {
                val image = layers[layer] ?: continue
                val colour = look.tint(layer)
                val width = layer.pixelWidth * SkyLayout.BASE_SCALE
                val height = layer.pixelHeight * SkyLayout.BASE_SCALE
                val top = HEIGHT - layer.anchor * SkyLayout.BASE_SCALE
                drawImage(
                    image,
                    dstOffset = IntOffset(0, top.roundToInt()),
                    dstSize = IntSize(width.roundToInt(), height.roundToInt()),
                    colorFilter = if (colour == Color.White) null else ColorFilter.tint(colour, BlendMode.Modulate),
                    filterQuality = FilterQuality.Medium,
                )
            }
        }
        return bitmap
    }

    private val MeadowLayer.anchor: Float
        get() = when (this) {
            MeadowLayer.FAR -> FAR_ANCHOR
            MeadowLayer.MID -> 848f
            MeadowLayer.NEAR -> 705f
        }
}
