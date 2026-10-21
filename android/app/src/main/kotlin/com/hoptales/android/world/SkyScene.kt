package com.hoptales.android.world

import android.content.res.AssetManager
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DoubleState
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.currentStateAsState
import com.hoptales.content.Mood
import kotlin.math.hypot
import kotlin.math.roundToInt

class SkyArt(private val images: Map<String, ImageBitmap>) {
    operator fun get(name: String): ImageBitmap? = images[name]

    companion object {
        private val names = listOf("sky-sun", "sky-moon", "sky-star-1", "sky-star-2", "sky-star-3") +
            SkyCloud.drifting.map { it.asset }

        fun load(assets: AssetManager) = SkyArt(names.mapNotNull { name -> Art.image(assets, name)?.let { name to it } }.toMap())
    }
}

@Composable
fun rememberSkyLook(mood: Mood, still: Boolean): () -> SkyLook {
    val target = remember(mood) { SkyLook.of(mood) }
    var from by remember { mutableStateOf(target) }
    var to by remember { mutableStateOf(target) }
    val fade = remember { Animatable(1f) }
    LaunchedEffect(target, still) {
        if (target == to) return@LaunchedEffect
        from = from.blend(to, fade.value)
        to = target
        if (still) {
            from = target
            fade.snapTo(1f)
        } else {
            fade.snapTo(0f)
            fade.animateTo(1f, tween(SkyLook.CROSSFADE_MILLIS, easing = LinearEasing))
        }
    }
    return { from.blend(to, fade.value) }
}

@Composable
fun rememberSkyTime(running: Boolean): DoubleState {
    val time = remember { mutableDoubleStateOf(0.0) }
    val state by LocalLifecycleOwner.current.lifecycle.currentStateAsState()
    val live = running && state.isAtLeast(Lifecycle.State.STARTED)
    LaunchedEffect(live) {
        if (!live) return@LaunchedEffect
        val origin = withFrameNanos { it } - (time.doubleValue * 1e9).toLong()
        while (true) withFrameNanos { time.doubleValue = (it - origin) / 1e9 }
    }
    return time
}

class SkyWeather {
    val rain = Shower.rain()
    val snow = Shower.snow()
    private var stormSince: Double? = null

    fun apply(mood: Mood, now: Double) {
        val style = mood.weather.style
        rain.fall(style.rain, now)
        snow.fall(style.snow, now)
        stormSince = if (style.lightning) stormSince ?: now else null
    }

    fun flash(now: Double): Float = stormSince?.let { Lightning.flash(now - it) } ?: 0f

    fun isMoving(now: Double) = rain.isVisible(now) || snow.isVisible(now) || stormSince != null
}

private fun DrawScope.drawArt(
    image: ImageBitmap,
    x: Float,
    y: Float,
    width: Float,
    height: Float,
    alpha: Float,
    colorFilter: ColorFilter? = null,
) {
    if (alpha <= 0f || width <= 0f) return
    drawImage(
        image = image,
        dstOffset = IntOffset((x - width / 2).roundToInt(), (y - height / 2).roundToInt()),
        dstSize = IntSize(width.roundToInt(), height.roundToInt()),
        alpha = alpha.coerceAtMost(1f),
        colorFilter = colorFilter,
        filterQuality = FilterQuality.Medium,
    )
}

fun DrawScope.drawSky(
    look: SkyLook,
    layout: SkyLayout,
    art: SkyArt,
    stars: List<MeadowStar>,
    time: Double,
    still: Boolean,
    postcard: Boolean = false,
) {
    drawRect(Brush.verticalGradient(0f to look.gradient[0], GRADIENT_MIDDLE to look.gradient[1], 1f to look.gradient[2]))
    if (look.stars > 0f) {
        for (star in stars) {
            val image = art[star.asset] ?: continue
            drawArt(image, star.x, star.y, star.width, star.width * MeadowStars.ASPECT, look.stars)
        }
    }
    art["sky-moon"]?.let { drawArt(it, layout.moonX, layout.moonY, layout.moonWidth, layout.moonHeight, look.moon) }
    art["sky-sun"]?.let { sun ->
        val height = layout.sunWidth * sun.height / sun.width
        drawArt(
            sun,
            layout.width * SkyLayout.SUN_X,
            layout.sunCentreY(if (postcard) layout.sunWidth else height, look.sunDrop),
            layout.sunWidth,
            height,
            look.sun,
        )
    }
    for (cloud in if (still) SkyCloud.still else SkyCloud.drifting) {
        val image = art[cloud.asset] ?: continue
        val width = image.width * SkyCloud.ART_SCALE * layout.k
        val height = image.height * SkyCloud.ART_SCALE * layout.k
        val x = if (still) cloud.spotX * layout.width else cloud.x(width, layout, time)
        val y = if (still) cloud.spotY * layout.k else cloud.y(layout)
        if (x + width / 2 < 0 || x - width / 2 > layout.width) continue
        val backing = if (cloud.storm) look.stormBacking else look.fairBacking
        val alpha = if (cloud.storm) look.stormClouds else look.fairClouds
        val colour = look.skyColor(y / layout.height.coerceAtLeast(1f))
        drawArt(image, x, y, width, height, backing, ColorFilter.tint(colour, BlendMode.SrcIn))
        drawArt(image, x, y, width, height, alpha)
    }
}

fun DrawScope.drawWeather(look: SkyLook, weather: SkyWeather, time: Double, unit: Float, still: StillDrops?) {
    if (look.overlay > 0f) drawRect(OVERLAY.copy(alpha = look.overlay.coerceAtMost(1f)))
    if (still != null) {
        if (weather.rain.isFalling) {
            for (drop in still.rain) {
                drawLine(STILL_RAIN, Offset(drop.x, drop.y), Offset(drop.x + 6 * unit, drop.y + 22 * unit), 1.2f * unit)
            }
        }
        if (weather.snow.isFalling) {
            for (flake in still.snow) drawCircle(STILL_SNOW, flake.radius, Offset(flake.x + flake.radius, flake.y + flake.radius))
        }
        return
    }
    weather.rain.forEach(time, size.width, unit) { drop ->
        val length = hypot(drop.dx, drop.dy).coerceAtLeast(1f)
        val half = RAIN_LENGTH / 2 * drop.scale * unit
        val along = Offset(drop.dx / length * half, drop.dy / length * half)
        val centre = Offset(drop.x, drop.y)
        drawLine(Color.White.copy(alpha = RAIN_ALPHA * drop.alpha), centre - along, centre + along, RAIN_WIDTH * drop.scale * unit)
    }
    weather.snow.forEach(time, size.width, unit) { flake ->
        drawCircle(Color.White.copy(alpha = SNOW_ALPHA * flake.alpha), SNOW_RADIUS * flake.scale * unit, Offset(flake.x, flake.y))
    }
    val flash = weather.flash(time)
    if (flash > 0f) drawRect(Color.White.copy(alpha = flash))
}

class StillDrops(width: Float, height: Float, unit: Float) {
    val rain = StillWeather.rain(width, height, unit)
    val snow = StillWeather.snow(width, height, unit)
}

private val OVERLAY = Color(0xFF4E5A6E)
private val STILL_RAIN = Color.White.copy(alpha = 0.45f)
private val STILL_SNOW = Color.White.copy(alpha = 0.8f)
private const val RAIN_LENGTH = 26f
private const val RAIN_WIDTH = 2f
private const val RAIN_ALPHA = 0.7f
private const val SNOW_RADIUS = 4f
private const val SNOW_ALPHA = 0.9f
