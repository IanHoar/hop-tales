package com.hoptales.android.world

import androidx.compose.ui.graphics.Color
import com.hoptales.content.Friend
import com.hoptales.content.Sky

enum class MeadowLayer(val prefix: String, val pixelWidth: Float, val pixelHeight: Float, val speed: Float, val pathScale: Float) {
    FAR("far", 5615f, 826f, 0.3f, 0.42f),
    MID("mid", 4692f, 834f, 0.6f, 0.5f),
    NEAR("near", 3555f, 834f, 1f, 0.74f),
    ;

    fun asset(world: Friend): String = if (world == Friend.HARE) "$prefix-day" else "$prefix-${world.key}"
}

data class MeadowLayout(val width: Float, val pathScale: Float, val pathCentre: Float) {
    fun scale(layer: MeadowLayer) = pathScale * layer.pathScale

    fun tileWidth(layer: MeadowLayer) = layer.pixelWidth * scale(layer)

    fun tileHeight(layer: MeadowLayer) = layer.pixelHeight * scale(layer)

    fun top(layer: MeadowLayer): Float {
        val near = pathCentre - PATH_LINE * scale(MeadowLayer.NEAR)
        return when (layer) {
            MeadowLayer.FAR -> near - 52 * pathScale
            MeadowLayer.MID -> near + 8 * pathScale
            MeadowLayer.NEAR -> near
        }
    }

    fun offset(layer: MeadowLayer, progress: Float): Float {
        val width = tileWidth(layer)
        if (width <= 0f) return 0f
        var travelled = (progress * layer.speed) % width
        if (travelled < 0) travelled += width
        return -travelled
    }

    fun tileCount(layer: MeadowLayer): Int {
        val width = tileWidth(layer)
        return if (width <= 0f) 1 else kotlin.math.ceil(this.width / width).toInt() + 1
    }

    companion object {
        const val PATH_LINE = 440f
    }
}

fun skyColors(sky: Sky): List<Color> = when (sky) {
    Sky.DAY -> listOf(Color(0xFFBCDCEE), Color(0xFFDCEBEF), Color(0xFFEEF2E6))
    Sky.GOLDEN -> listOf(Color(0xFFF0C9A4), Color(0xFFF7DDB8), Color(0xFFFBEBCB))
    Sky.DUSK -> listOf(Color(0xFF7F74A6), Color(0xFFC98FA2), Color(0xFFF0B48E))
    Sky.NIGHT -> listOf(Color(0xFF18223F), Color(0xFF2C3A63), Color(0xFF46557E))
}

fun layerTint(sky: Sky): Color? = when (sky) {
    Sky.DAY -> null
    Sky.GOLDEN -> Color(0xFFFFDEB4)
    Sky.DUSK -> Color(0xFFD6ACBE)
    Sky.NIGHT -> Color(0xFF6070A0)
}
