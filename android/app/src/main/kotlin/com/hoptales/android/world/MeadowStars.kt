package com.hoptales.android.world

import kotlin.math.hypot
import kotlin.math.max

data class SkyLayout(val width: Float, val height: Float, val k: Float, val farTop: Float) {
    val scale: Float get() = BASE_SCALE * k
    val sunWidth: Float get() = 295 * scale
    val sunTop: Float get() = farTop - 238 * scale
    val moonWidth: Float get() = 150 * k
    val moonHeight: Float get() = 162 * k
    val moonX: Float get() = width * 0.78f
    val moonY: Float get() = 150 * k

    fun sunCentreY(sunHeight: Float, drop: Float) = sunTop + sunHeight / 2 + drop * k

    companion object {
        const val BASE_SCALE = 0.42f
        const val SUN_X = 0.24f

        fun of(meadow: MeadowLayout, height: Float) = SkyLayout(meadow.width, height, meadow.pathScale, meadow.top(MeadowLayer.FAR))
    }
}

data class MeadowStar(val asset: String, val x: Float, val y: Float, val width: Float)

object MeadowStars {
    const val ASPECT = 239f / 244f

    fun field(layout: SkyLayout): List<MeadowStar> {
        val width = layout.width.toDouble()
        val height = layout.height.toDouble()
        val k = layout.k.toDouble()
        if (width <= 0 || height <= 0) return emptyList()
        val random = SeededRandom(42)
        val columns = max(5, (width / (80 * k)).toInt())
        val rows = 3
        val top = height * 0.04
        val bottom = height * 0.4
        val cellWidth = width / columns
        val cellHeight = (bottom - top) / rows
        val moonReach = max(layout.moonWidth, layout.moonHeight) * 0.6
        val stars = mutableListOf<MeadowStar>()
        for (row in 0 until rows) {
            for (column in 0 until columns) {
                val size = 244 * random.nextDouble(0.07, 0.12) * k
                val jitterX = random.nextDouble(0.0, 1.0)
                val jitterY = random.nextDouble(0.0, 1.0)
                val skip = random.nextDouble(0.0, 1.0) < 0.2
                val inset = size / 2 + 4 * k
                val x = column * cellWidth + inset + jitterX * max(0.0, cellWidth - 2 * inset)
                val y = top + row * cellHeight + inset + jitterY * max(0.0, cellHeight - 2 * inset)
                val clearOfMoon = hypot(x - layout.moonX, y - layout.moonY) > moonReach + size / 2
                if (skip || !clearOfMoon) continue
                stars += MeadowStar("sky-star-${stars.size % 3 + 1}", x.toFloat(), y.toFloat(), size.toFloat())
            }
        }
        return stars
    }
}

class SeededRandom(seed: Long) {
    private var state: ULong = seed.toULong() + 0x9E3779B97F4A7C15uL

    fun next(): ULong {
        state += 0x9E3779B97F4A7C15uL
        var value = state
        value = (value xor (value shr 30)) * 0xBF58476D1CE4E5B9uL
        value = (value xor (value shr 27)) * 0x94D049BB133111EBuL
        return value xor (value shr 31)
    }

    fun next(upperBound: ULong): ULong {
        var random = next()
        var low = random * upperBound
        if (low < upperBound) {
            val threshold = (0uL - upperBound) % upperBound
            while (low < threshold) {
                random = next()
                low = random * upperBound
            }
        }
        return multiplyHigh(random, upperBound)
    }

    fun nextDouble(from: Double, to: Double): Double {
        val max = 1uL shl 53
        val random = next(max + 1uL)
        if (random == max) return to
        return (to - from) * (random.toDouble() * HALF_ULP) + from
    }

    private fun multiplyHigh(a: ULong, b: ULong): ULong {
        val aLow = a and MASK
        val aHigh = a shr 32
        val bLow = b and MASK
        val bHigh = b shr 32
        val lowLow = aLow * bLow
        val highLow = aHigh * bLow
        val lowHigh = aLow * bHigh
        val highHigh = aHigh * bHigh
        val middle = (lowLow shr 32) + (highLow and MASK) + (lowHigh and MASK)
        return highHigh + (highLow shr 32) + (lowHigh shr 32) + (middle shr 32)
    }

    private companion object {
        const val MASK = 0xFFFFFFFFuL
        const val HALF_ULP = 1.0 / (1L shl 53)
    }
}
