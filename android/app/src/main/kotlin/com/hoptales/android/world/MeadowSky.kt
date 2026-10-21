package com.hoptales.android.world

import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin

data class SkyCloud(
    val asset: String,
    val storm: Boolean,
    val slot: Float,
    val speed: Float,
    val spotX: Float = 0f,
    val spotY: Float = 0f,
) {
    fun x(artWidth: Float, layout: SkyLayout, time: Double): Float {
        val half = artWidth / 2
        val start = slot * (layout.width + artWidth)
        val travelled = (speed * layout.k * time).toFloat()
        val past = travelled - (start + half)
        if (past <= 0f) return start - travelled
        return layout.width + half - past % (layout.width + artWidth)
    }

    fun y(layout: SkyLayout): Float = (70 + 130 * slot) * layout.k

    companion object {
        const val ART_SCALE = 0.5f

        private fun group(names: List<String>, storm: Boolean) =
            names.mapIndexed { index, name -> SkyCloud(name, storm, index.toFloat() / names.size, 6f + 3 * index) }

        val drifting = group(listOf("sky-cloud-1", "sky-cloud-2", "sky-cloud-3", "sky-cloud-4"), storm = false) +
            group(listOf("sky-storm-1", "sky-storm-2", "sky-storm-3"), storm = true)

        val still = listOf(
            SkyCloud("sky-cloud-1", storm = false, slot = 0f, speed = 0f, spotX = 0.18f, spotY = 70f),
            SkyCloud("sky-cloud-3", storm = false, slot = 0f, speed = 0f, spotX = 0.72f, spotY = 140f),
            SkyCloud("sky-storm-1", storm = true, slot = 0f, speed = 0f, spotX = 0.3f, spotY = 100f),
            SkyCloud("sky-storm-2", storm = true, slot = 0f, speed = 0f, spotX = 0.82f, spotY = 60f),
        )
    }
}

object Lightning {
    const val PEAK = 0.55f
    private const val RISE = 0.05
    private const val FALL = 0.35
    private const val FIRST = 6.0
    private const val SEED = 13L

    fun flash(sinceStorm: Double): Float {
        val random = SeededRandom(SEED)
        var at = FIRST
        while (at + RISE + FALL < sinceStorm) at += random.nextDouble(4.0, 9.0)
        val local = sinceStorm - at
        return when {
            local < 0 -> 0f
            local < RISE -> (PEAK * local / RISE).toFloat()
            local < RISE + FALL -> (PEAK * (1 - (local - RISE) / FALL)).toFloat()
            else -> 0f
        }
    }
}

data class Emitter(
    val rate: Double,
    val lifetime: Double,
    val speed: Float,
    val alpha: Float,
    val scale: Float,
    val angle: Float,
    val x: Float,
    val xRange: Float,
    val above: Float,
    val salt: Long,
    val speedRange: Float = 0f,
    val angleRange: Float = 0f,
    val scaleRange: Float = 0f,
    val xAcceleration: Float = 0f,
)

data class Particle(val x: Float, val y: Float, val dx: Float, val dy: Float, val alpha: Float, val scale: Float)

class Shower(private val emitters: List<Emitter>) {
    private val spells = mutableListOf<DoubleArray>()
    private val lifetime = emitters.maxOf { it.lifetime }

    var isFalling = false
        private set

    fun fall(falling: Boolean, now: Double) {
        if (falling == isFalling) return
        isFalling = falling
        if (falling) spells += doubleArrayOf(now, Double.POSITIVE_INFINITY) else spells.lastOrNull()?.set(1, now)
        spells.removeAll { it[1] + lifetime < now }
    }

    fun isVisible(now: Double) = spells.any { now < it[1] + lifetime }

    fun forEach(now: Double, width: Float, unit: Float, block: (Particle) -> Unit) {
        for (emitter in emitters) {
            for (spell in spells) {
                val first = ceil(maxOf(now - emitter.lifetime, spell[0]) * emitter.rate).toLong()
                val last = floor(minOf(now, spell[1]) * emitter.rate).toLong()
                for (index in first..last) {
                    block(emitter.particle(index, now - index / emitter.rate, width, unit))
                }
            }
        }
    }

    companion object {
        private const val RAIN_ANGLE = (-PI / 2 - 0.26).toFloat()
        private const val SNOW_ANGLE = (-PI / 2).toFloat()

        fun rain() = Shower(
            listOf(
                Emitter(90.0, 2.2, 620f, 0.55f, 1f, RAIN_ANGLE, 0.6f, 1.6f, 20f, salt = 1),
                Emitter(55.0, 2.2, 440f, 0.35f, 0.7f, RAIN_ANGLE, 0.6f, 1.6f, 20f, salt = 2),
            ),
        )

        fun snow() = Shower(
            listOf(
                Emitter(
                    14.0, 9.0, 70f, 0.9f, 0.9f, SNOW_ANGLE, 0.5f, 1.4f, 12f, salt = 3,
                    speedRange = 20f, angleRange = 0.5f, scaleRange = 0.3f, xAcceleration = -6f,
                ),
                Emitter(
                    22.0, 9.0, 45f, 0.6f, 0.5f, SNOW_ANGLE, 0.5f, 1.4f, 12f, salt = 4,
                    speedRange = 20f, angleRange = 0.5f, scaleRange = 0.3f, xAcceleration = -6f,
                ),
            ),
        )
    }
}

private fun Emitter.particle(index: Long, age: Double, width: Float, unit: Float): Particle {
    val speed = speed + speedRange * (unit(index, 1) - 0.5f)
    val angle = angle + angleRange * (unit(index, 2) - 0.5f)
    val scale = scale + scaleRange * (unit(index, 3) - 0.5f)
    val startX = width * (x + xRange * (unit(index, 0) - 0.5f))
    val dx = cos(angle) * speed
    val dy = -sin(angle) * speed
    val seconds = age.toFloat()
    return Particle(
        x = startX + (dx * seconds + xAcceleration * seconds * seconds / 2) * unit,
        y = (-above + dy * seconds) * unit,
        dx = dx + xAcceleration * seconds,
        dy = dy,
        alpha = alpha,
        scale = scale,
    )
}

private fun Emitter.unit(index: Long, lane: Int): Float {
    var value = (index * 8 + lane).toULong() * 0x9E3779B97F4A7C15uL + salt.toULong() * 0xD1B54A32D192ED03uL
    value = (value xor (value shr 30)) * 0xBF58476D1CE4E5B9uL
    value = (value xor (value shr 27)) * 0x94D049BB133111EBuL
    value = value xor (value shr 31)
    return ((value shr 40).toFloat()) / (1 shl 24)
}

data class Streak(val x: Float, val y: Float, val radius: Float = 0f)

object StillWeather {
    fun rain(width: Float, height: Float, unit: Float): List<Streak> {
        val points = width / unit to height / unit
        val random = SeededRandom(7)
        return List((points.first * points.second / 2600).toInt()) {
            val x = random.nextDouble(-40.0, points.first.toDouble())
            val y = random.nextDouble(0.0, points.second.toDouble())
            Streak(x.toFloat() * unit, y.toFloat() * unit)
        }
    }

    fun snow(width: Float, height: Float, unit: Float): List<Streak> {
        val points = width / unit to height / unit
        val random = SeededRandom(11)
        return List((points.first * points.second / 5200).toInt()) {
            val x = random.nextDouble(0.0, points.first.toDouble())
            val y = random.nextDouble(0.0, points.second.toDouble())
            val radius = random.nextDouble(1.5, 4.0)
            Streak(x.toFloat() * unit, y.toFloat() * unit, radius.toFloat() * unit)
        }
    }
}
