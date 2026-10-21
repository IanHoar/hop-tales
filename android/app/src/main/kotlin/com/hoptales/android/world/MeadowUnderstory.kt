package com.hoptales.android.world

import android.graphics.Bitmap
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import com.hoptales.android.reading.multiply
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.ceil
import kotlin.math.roundToInt

class MeadowGround(val colour: Color, val band: ImageBitmap?) {
    companion object {
        fun of(style: WorldStyle, near: ImageBitmap?, name: String): MeadowGround =
            MeadowGround(style.ground, near?.let { MeadowUnderstory.band(it, name) })
    }
}

object MeadowUnderstory {
    const val BAND_TOP = 0.62f
    const val FADE = 0.22f
    const val STEP = 0.58f
    const val DRIFT = 0.37f
    val TORN_EDGE = 6.dp
    private const val FADE_STEPS = 24
    private val faded = ConcurrentHashMap<String, ImageBitmap>()

    fun overlap(tileWidth: Float): Float = tileWidth * MeadowLayer.NEAR.pixelHeight * (1 - BAND_TOP) / MeadowLayer.NEAR.pixelWidth * FADE

    fun band(near: ImageBitmap, name: String): ImageBitmap = faded.getOrPut(name) { fade(near.asAndroidBitmap()).asImageBitmap() }

    private fun fade(source: Bitmap): Bitmap {
        val top = (source.height * BAND_TOP).toInt()
        val width = source.width
        val height = source.height - top
        val band = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(band)
        val from = Rect(0, top, width, source.height)
        val to = RectF(0f, 0f, width.toFloat(), height.toFloat())
        val fade = height * FADE
        canvas.save()
        canvas.clipRect(0f, fade, width.toFloat(), height.toFloat())
        canvas.drawBitmap(source, from, to, null)
        canvas.restore()
        val slice = fade / FADE_STEPS
        val paint = Paint()
        for (index in 0 until FADE_STEPS) {
            val bottom = fade - index * slice
            canvas.save()
            canvas.clipRect(0f, bottom - slice - 0.5f, width.toFloat(), bottom)
            paint.alpha = ((1 - (index + 1f) / (FADE_STEPS + 1)) * 255).roundToInt()
            canvas.drawBitmap(source, from, to, paint)
            canvas.restore()
        }
        return band
    }
}

fun DrawScope.drawGround(ground: MeadowGround, top: Float, tileWidth: Float, offset: Float, tint: Color) {
    if (top >= size.height) return
    val colours = listOf(ground.colour, GROUND_MIDDLE, GROUND_FOOT).map { multiply(it, tint) }
    drawRect(
        Brush.verticalGradient(colours, startY = top, endY = size.height),
        topLeft = Offset(0f, top - 1),
        size = Size(size.width, size.height - top + 1),
    )
    val band = ground.band ?: return
    if (tileWidth <= 0f) return
    val height = band.height * tileWidth / band.width
    val bandTop = top - MeadowUnderstory.overlap(tileWidth)
    val rows = ceil((size.height - bandTop) / (height * MeadowUnderstory.STEP)).toInt() + 1
    val filter = if (tint == Color.White) null else ColorFilter.tint(tint, BlendMode.Modulate)
    for (row in 0 until rows) {
        val y = bandTop + row * height * MeadowUnderstory.STEP
        val shift = ((row + 1) * MeadowUnderstory.DRIFT) % 1f
        var x = (offset - shift * tileWidth) % tileWidth
        if (x > 0) x -= tileWidth
        while (x < size.width) {
            drawImage(
                band,
                dstOffset = IntOffset(x.roundToInt(), y.roundToInt()),
                dstSize = IntSize(tileWidth.roundToInt() + 1, height.roundToInt()),
                colorFilter = filter,
                filterQuality = FilterQuality.Medium,
            )
            x += tileWidth
        }
    }
}

private val GROUND_MIDDLE = Color(0xFFD9D6A6)
private val GROUND_FOOT = Color(0xFFEDE6C8)
