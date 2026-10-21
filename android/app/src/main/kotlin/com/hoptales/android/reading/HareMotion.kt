package com.hoptales.android.reading

import com.hoptales.android.world.HareFrame
import com.hoptales.android.world.HareSheet
import com.hoptales.android.world.IdleMotion
import kotlin.math.PI
import kotlin.math.min
import kotlin.math.sin

data class HareMotion(val hop: Hop? = null) {
    data class Pose(
        val frame: HareFrame,
        val x: Float = 0f,
        val lift: Float = 0f,
        val scaleX: Float = 1f,
        val scaleY: Float = 1f,
    ) {
        companion object {
            val resting = Pose(HareFrame.rest)
        }
    }

    data class Hop(
        val start: Double,
        val fromX: Float,
        val distance: Float,
        val carried: Boolean = false,
        val rate: Double = 1.0,
    ) {
        val frameTime: Double get() = 1 / (FPS * rate)
        val length: Double get() = HOP_FRAMES * frameTime
        val takeOff: Double get() = MOVE_FRAMES.first * frameTime
        val airTime: Double get() = MOVE_FRAMES.count() * frameTime
    }

    fun x(time: Double): Float {
        val hop = hop ?: return 0f
        if (hop.carried) return 0f
        val elapsed = time - hop.start
        if (elapsed < hop.length) {
            val progress = eased((elapsed - hop.takeOff) / hop.airTime)
            return hop.fromX + (hop.distance - hop.fromX) * progress
        }
        return hop.distance * (1 - eased((elapsed - hop.length) / RIDE))
    }

    fun isAirborne(time: Double): Boolean {
        val hop = hop ?: return false
        return time >= hop.start && time - hop.start < hop.length
    }

    fun arc(time: Double): Float {
        val hop = hop ?: return 0f
        val progress = (time - hop.start - hop.takeOff) / hop.airTime
        if (progress <= 0 || progress >= 1) return 0f
        return sin(PI * progress).toFloat()
    }

    fun lift(time: Double): Float {
        val hop = hop ?: return 0f
        return (if (hop.carried) SENTENCE_APEX else APEX) * arc(time)
    }

    fun pose(time: Double, reduceMotion: Boolean): Pose {
        if (reduceMotion) return Pose.resting
        val hop = hop
        if (hop != null && isAirborne(time)) {
            val index = min(((time - hop.start) / hop.frameTime).toInt(), HOP_FRAMES - 1)
            return Pose(HareFrame(HareSheet.HOP, index), x(time), lift(time))
        }
        val (breathX, breathY) = IdleMotion.breathing(time)
        return Pose(HareFrame(HareSheet.IDLE, IdleMotion.frame(time)), x(time), scaleX = breathX, scaleY = breathY)
    }

    fun jump(time: Double, distance: Float, carried: Boolean): HareMotion {
        val chained = !carried && isAirborne(time)
        return HareMotion(
            Hop(
                start = time,
                fromX = if (carried) 0f else x(time),
                distance = distance,
                carried = carried,
                rate = if (chained) min((hop?.rate ?: 1.0) + RATE_STEP, FASTEST_RATE) else 1.0,
            ),
        )
    }

    companion object {
        const val FPS = 14.0
        const val HOP_FRAMES = 8
        val MOVE_FRAMES = 1..6
        const val RIDE = 0.45
        const val APEX = 46f
        const val SENTENCE_APEX = 96f
        const val RATE_STEP = 0.6
        const val FASTEST_RATE = 2.2
        val TAKE_OFF = MOVE_FRAMES.first / FPS
        val AIR_TIME = MOVE_FRAMES.count() / FPS

        fun eased(progress: Double): Float {
            val clamped = progress.coerceIn(0.0, 1.0)
            return (clamped * clamped * (3 - 2 * clamped)).toFloat()
        }
    }
}
