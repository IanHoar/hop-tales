package com.hoptales.android.reading

import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.ui.geometry.Offset
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

data class CheerStar(val centre: Offset, val scale: Float)

object FinishCheer {
    const val STARS = 6
    const val START = PathGeometry.PAN_MILLIS / 1000.0
    const val POP_SECONDS = 0.45
    const val POP_SCALE = 0.22f
    const val BURST_SECONDS = 0.28
    const val FLIGHT_SECONDS = 0.55
    const val STAGGER = 0.06
    const val BUMP_SECONDS = 0.32
    const val BUMP_SCALE = 0.18f
    const val FAN_DEGREES = 150.0
    const val ARC = 0.35f
    const val LANDED_SCALE = 0.55f

    val firstLanding: Double get() = START + BURST_SECONDS + FLIGHT_SECONDS
    val lastLanding: Double get() = firstLanding + STAGGER * (STARS - 1)
    val end: Double get() = lastLanding + BUMP_SECONDS

    private val easeOut = CubicBezierEasing(0f, 0f, 0.58f, 1f)
    private val easeIn = CubicBezierEasing(0.42f, 0f, 1f, 1f)

    fun wordScale(elapsed: Double): Float {
        val progress = (elapsed - START) / POP_SECONDS
        if (progress <= 0.0 || progress >= 1.0) return 1f
        return 1f + POP_SCALE * sin(PI * progress).toFloat()
    }

    fun chipScale(elapsed: Double): Float {
        val progress = (elapsed - firstLanding) / (lastLanding - firstLanding + BUMP_SECONDS)
        if (progress <= 0.0 || progress >= 1.0) return 1f
        return 1f + BUMP_SCALE * sin(PI * progress).toFloat()
    }

    fun star(index: Int, elapsed: Double, from: Offset, to: Offset, reach: Float): CheerStar? {
        val since = elapsed - START
        if (since < 0) return null
        val angle = Math.toRadians(-90.0 - FAN_DEGREES / 2 + FAN_DEGREES * index / (STARS - 1))
        val burst = from + Offset(cos(angle).toFloat(), sin(angle).toFloat()) * reach
        if (since < BURST_SECONDS) {
            val out = easeOut.transform((since / BURST_SECONDS).toFloat())
            return CheerStar(from + (burst - from) * out, out)
        }
        val flight = (since - BURST_SECONDS - STAGGER * index) / FLIGHT_SECONDS
        if (flight >= 1.0) return null
        if (flight <= 0.0) return CheerStar(burst, 1f)
        val eased = easeIn.transform(flight.toFloat())
        val middle = (burst + to) / 2f
        val control = Offset(middle.x, minOf(burst.y, to.y) - (to - burst).getDistance() * ARC)
        val inverse = 1f - eased
        val centre = burst * (inverse * inverse) + control * (2 * inverse * eased) + to * (eased * eased)
        return CheerStar(centre, 1f - (1f - LANDED_SCALE) * eased)
    }
}
