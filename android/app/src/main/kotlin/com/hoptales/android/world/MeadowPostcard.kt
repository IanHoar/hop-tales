package com.hoptales.android.world

import android.content.res.AssetManager
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.roundToInt

@Composable
fun MeadowPostcard(mood: Mood, modifier: Modifier = Modifier) {
    val assets = LocalContext.current.assets
    val image by produceState(MeadowPostcards.cached(mood), mood) {
        value = withContext(Dispatchers.Default) { MeadowPostcards.image(assets, mood) }
    }
    val postcard = image
    if (postcard == null) {
        Box(modifier.background(SkyLook.of(mood).gradient.last()))
        return
    }
    Image(
        postcard,
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
    private val cache = ConcurrentHashMap<Mood, ImageBitmap>()

    fun cached(mood: Mood): ImageBitmap? = cache[mood]

    fun image(assets: AssetManager, mood: Mood): ImageBitmap = cache.getOrPut(mood) { render(assets, mood) }

    private fun render(assets: AssetManager, mood: Mood): ImageBitmap {
        val look = SkyLook.of(mood)
        val layers = meadowLayers(assets, Friend.HARE)
        val meadow = MeadowLayout.wide(WIDTH.toFloat(), HEIGHT.toFloat(), 1f)
        val sky = SkyLayout.of(meadow, HEIGHT.toFloat())
        val bitmap = ImageBitmap(WIDTH, HEIGHT)
        CanvasDrawScope().draw(Density(1f), LayoutDirection.Ltr, Canvas(bitmap), Size(WIDTH.toFloat(), HEIGHT.toFloat())) {
            drawSky(look, sky, SkyArt.load(assets), MeadowStars.field(sky), 0.0, still = true, postcard = true)
            for (layer in MeadowLayer.entries) {
                val image = layers[layer] ?: continue
                val colour = look.tint(layer)
                drawImage(
                    image,
                    dstOffset = IntOffset(0, meadow.top(layer).roundToInt()),
                    dstSize = IntSize(meadow.tileWidth(layer).roundToInt(), meadow.tileHeight(layer).roundToInt()),
                    colorFilter = if (colour == Color.White) null else ColorFilter.tint(colour, BlendMode.Modulate),
                    filterQuality = FilterQuality.Medium,
                )
            }
            val weather = SkyWeather().apply { apply(mood, 0.0) }
            drawWeather(look, weather, 0.0, 1f, StillDrops(WIDTH.toFloat(), HEIGHT.toFloat(), 1f))
        }
        return bitmap
    }
}
