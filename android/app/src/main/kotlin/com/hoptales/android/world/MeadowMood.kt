package com.hoptales.android.world

import androidx.compose.ui.graphics.Color
import com.hoptales.content.Mood
import com.hoptales.content.Sky
import com.hoptales.content.Weather

data class SkyStyle(
    val gradient: List<Color>,
    val tints: Map<MeadowLayer, Color>,
    val stars: Float = 0f,
    val moon: Float = 0f,
    val sun: Float = 0f,
    val sunDrop: Float = 0f,
    val clouds: Float = 1f,
)

data class WeatherStyle(
    val fairClouds: Float,
    val stormClouds: Float,
    val overlay: Float,
    val dim: Float,
    val rain: Boolean = false,
    val lightning: Boolean = false,
    val snow: Boolean = false,
) {
    val sun: Float get() = if (overlay > 0f) 0f else 1f
}

private fun sky(
    gradient: List<Long>,
    tints: List<Long>,
    stars: Float = 0f,
    moon: Float = 0f,
    sun: Float = 0f,
    drop: Float = 0f,
    clouds: Float = 1f,
) = SkyStyle(
    gradient = gradient.map(::Color),
    tints = mapOf(MeadowLayer.FAR to Color(tints[0]), MeadowLayer.MID to Color(tints[1]), MeadowLayer.NEAR to Color(tints[2])),
    stars = stars,
    moon = moon,
    sun = sun,
    sunDrop = drop,
    clouds = clouds,
)

val Sky.style: SkyStyle
    get() = when (this) {
        Sky.DAY -> sky(listOf(0xFFBCDCEE, 0xFFDCEBEF, 0xFFEEF2E6), listOf(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF), sun = 1f)

        Sky.GOLDEN -> sky(listOf(0xFFF0C9A4, 0xFFF7DDB8, 0xFFFBEBCB), listOf(0xFFFCD6AA, 0xFFFFDEB4, 0xFFFFE8C4), sun = 1f, drop = 70f)

        Sky.DUSK -> sky(
            listOf(0xFF7F74A6, 0xFFC98FA2, 0xFFF0B48E),
            listOf(0xFFC4A0C8, 0xFFD6ACBE, 0xFFE8BEBE),
            stars = 0.35f,
            moon = 0.5f,
            sun = 0.6f,
            drop = 150f,
        )

        Sky.NIGHT -> sky(
            listOf(0xFF18223F, 0xFF2C3A63, 0xFF46557E),
            listOf(0xFF5C6CA0, 0xFF6070A0, 0xFF6876A0),
            stars = 1f,
            moon = 1f,
            clouds = 0.35f,
        )
    }

val Weather.style: WeatherStyle
    get() = when (this) {
        Weather.CLEAR -> WeatherStyle(fairClouds = 0.55f, stormClouds = 0f, overlay = 0f, dim = 1f)
        Weather.CLOUDS -> WeatherStyle(fairClouds = 1f, stormClouds = 0.35f, overlay = 0f, dim = 1f)
        Weather.STORM -> WeatherStyle(fairClouds = 0.2f, stormClouds = 1f, overlay = 0.34f, dim = 0.74f, lightning = true)
        Weather.RAIN -> WeatherStyle(fairClouds = 0f, stormClouds = 1f, overlay = 0.28f, dim = 0.74f, rain = true)
        Weather.SNOW -> WeatherStyle(fairClouds = 0.6f, stormClouds = 0.5f, overlay = 0.12f, dim = 0.9f, snow = true)
    }

fun Mood.tint(layer: MeadowLayer): Color = sky.style.tints.getValue(layer).dimmed(weather.style.dim)

fun Color.dimmed(factor: Float) = Color(red * factor, green * factor, blue * factor, alpha)

fun mix(from: Color, to: Color, fraction: Float) = Color(
    from.red + (to.red - from.red) * fraction,
    from.green + (to.green - from.green) * fraction,
    from.blue + (to.blue - from.blue) * fraction,
    from.alpha + (to.alpha - from.alpha) * fraction,
)

fun mix(from: Float, to: Float, fraction: Float) = from + (to - from) * fraction

fun gradientColor(gradient: List<Color>, fraction: Float): Color {
    if (gradient.size != 3) return gradient.firstOrNull() ?: Color.White
    val at = fraction.coerceIn(0f, 1f)
    return if (at < GRADIENT_MIDDLE) {
        mix(gradient[0], gradient[1], at / GRADIENT_MIDDLE)
    } else {
        mix(gradient[1], gradient[2], (at - GRADIENT_MIDDLE) / (1 - GRADIENT_MIDDLE))
    }
}

const val GRADIENT_MIDDLE = 0.55f

data class SkyLook(
    val gradient: List<Color>,
    val tints: List<Color>,
    val stars: Float,
    val moon: Float,
    val sun: Float,
    val sunDrop: Float,
    val fairClouds: Float,
    val fairBacking: Float,
    val stormClouds: Float,
    val stormBacking: Float,
    val overlay: Float,
) {
    fun tint(layer: MeadowLayer): Color = tints[layer.ordinal]

    fun skyColor(fraction: Float): Color = gradientColor(gradient, fraction)

    fun blend(to: SkyLook, fraction: Float): SkyLook {
        if (fraction >= 1f) return to
        if (fraction <= 0f) return this
        return SkyLook(
            gradient = gradient.zip(to.gradient) { a, b -> mix(a, b, fraction) },
            tints = tints.zip(to.tints) { a, b -> mix(a, b, fraction) },
            stars = mix(stars, to.stars, fraction),
            moon = mix(moon, to.moon, fraction),
            sun = mix(sun, to.sun, fraction),
            sunDrop = mix(sunDrop, to.sunDrop, fraction),
            fairClouds = mix(fairClouds, to.fairClouds, fraction),
            fairBacking = mix(fairBacking, to.fairBacking, fraction),
            stormClouds = mix(stormClouds, to.stormClouds, fraction),
            stormBacking = mix(stormBacking, to.stormBacking, fraction),
            overlay = mix(overlay, to.overlay, fraction),
        )
    }

    companion object {
        const val CROSSFADE_MILLIS = 3_000

        fun of(mood: Mood): SkyLook {
            val sky = mood.sky.style
            val weather = mood.weather.style
            return SkyLook(
                gradient = sky.gradient,
                tints = MeadowLayer.entries.map(mood::tint),
                stars = sky.stars,
                moon = sky.moon,
                sun = sky.sun * weather.sun,
                sunDrop = sky.sunDrop,
                fairClouds = weather.fairClouds * sky.clouds,
                fairBacking = if (weather.fairClouds > 0f) 1f else 0f,
                stormClouds = weather.stormClouds * sky.clouds,
                stormBacking = if (weather.stormClouds > 0f) 1f else 0f,
                overlay = weather.overlay,
            )
        }
    }
}
