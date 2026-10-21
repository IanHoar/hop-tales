package com.hoptales.android.world

import com.hoptales.content.Friend

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
