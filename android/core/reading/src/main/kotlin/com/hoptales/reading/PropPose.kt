package com.hoptales.reading

import com.hoptales.content.StoryProp.Motion
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin

data class PropPose(
    val dx: Float = 0f,
    val dy: Float = 0f,
    val rotation: Float = 0f,
    val scale: Float = 1f,
    val opacity: Float = 1f,
    val frame: Int = 1,
    val flip: Boolean = false,
    val pivotsAtBase: Boolean = true,
) {
    companion object {
        fun at(item: PropItem, elapsed: Double?, exit: Double, width: Float, unit: Float): PropPose {
            if (elapsed == null) return PropPose(flip = item.companion)
            if (elapsed < 0) return PropPose(opacity = 0f)
            if (item.companion) return running(elapsed, exit, width, unit)
            val pose = moving(item, elapsed, width.toDouble(), unit.toDouble())
            return pose.copy(opacity = pose.opacity * (1 - exit).toFloat())
        }

        fun thinking(time: Double?, exit: Double, unit: Float): PropPose {
            if (time == null) return PropPose()
            if (time < 0) return PropPose(opacity = 0f)
            return PropPose(
                dy = (sin(time * 1.4) * 2 * unit - exit * 18 * unit).toFloat(),
                scale = popScale(time).toFloat(),
                opacity = (1 - exit).toFloat(),
            )
        }

        fun running(time: Double, exit: Double, width: Float, unit: Float): PropPose {
            val arrive = easeOut(min(1.0, time / 0.9))
            val dash = exit * exit
            return PropPose(
                dx = (-(1 - arrive) * width * 0.35 + dash * width).toFloat(),
                dy = (-abs(sin(time * PI / 0.1)) * 1.5 * unit).toFloat(),
                frame = (time / 0.1).toInt() % 2 + 1,
                flip = true,
            )
        }

        private fun moving(item: PropItem, time: Double, width: Double, unit: Double): PropPose = when (item.prop.motion) {
            Motion.WALK, Motion.SWIM, Motion.FLY, Motion.SWOOP, Motion.PERCH -> travelling(item, time, width, unit)

            Motion.POP, Motion.BURST, Motion.DRIFT, Motion.SWAY, Motion.ROLL, Motion.BOB, Motion.FADE ->
                settling(item, time, width, unit)
        }

        private fun travelling(item: PropItem, time: Double, width: Double, unit: Double): PropPose {
            val phase = (item.seed % 5).toDouble()
            return when (item.prop.motion) {
                Motion.WALK -> walk(time, width * 0.6, unit)

                Motion.SWIM -> walk(time, width * 0.5, unit).copy(
                    frame = (time / 0.3).toInt() % 2 + 1,
                    dy = (sin(time * 2.2 + phase) * 3 * unit).toFloat(),
                )

                Motion.FLY -> fly(item, time, width, unit)

                Motion.SWOOP -> swoop(item, time, width, unit)

                else -> perch(time, width, unit)
            }
        }

        private fun settling(item: PropItem, time: Double, width: Double, unit: Double): PropPose {
            val phase = (item.seed % 5).toDouble()
            return when (item.prop.motion) {
                Motion.POP -> PropPose(scale = popScale(time).toFloat())

                Motion.BURST -> {
                    val fade = ((time - 1.2) / 0.6).coerceIn(0.0, 1.0)
                    PropPose(scale = popScale(time).toFloat(), opacity = (1 - fade).toFloat())
                }

                Motion.DRIFT -> {
                    val arrive = easeOut(min(1.0, time / 3.2))
                    PropPose(
                        dx = ((1 - arrive) * width * 0.5).toFloat(),
                        dy = (sin(time * 1.3 + phase) * 6 * unit).toFloat(),
                        rotation = (sin(time * 0.9 + phase) * 4).toFloat(),
                        pivotsAtBase = false,
                    )
                }

                Motion.SWAY -> PropPose(rotation = (sin(time * 1.1 + phase) * 2.5).toFloat(), scale = popScale(time).toFloat())

                Motion.ROLL -> {
                    val arrive = easeOut(min(1.0, time / 1.8))
                    val dx = (1 - arrive) * width * 0.5
                    val radius = max(item.height * 0.5 * unit, 1.0)
                    PropPose(dx = dx.toFloat(), rotation = (-(dx / radius) * 180 / PI).toFloat(), pivotsAtBase = false)
                }

                Motion.BOB -> PropPose(
                    dy = (sin(time * 1.6 + phase) * 3 * unit).toFloat(),
                    rotation = (sin(time * 1.2 + phase) * 3).toFloat(),
                    scale = popScale(time).toFloat(),
                    pivotsAtBase = false,
                )

                else -> PropPose(opacity = min(1.0, time / 1.2).toFloat())
            }
        }

        private fun walk(time: Double, distance: Double, unit: Double): PropPose {
            val progress = min(1.0, time / 2.4)
            val moving = progress < 1
            val step = (time / 0.16).toInt()
            return PropPose(
                dx = ((1 - easeOut(progress)) * distance).toFloat(),
                dy = if (moving) (-abs(sin(time * PI / 0.16)) * 2 * unit).toFloat() else 0f,
                frame = if (moving) step % 2 + 1 else 1,
            )
        }

        private fun fly(item: PropItem, time: Double, width: Double, unit: Double): PropPose {
            val style = FlightStyle(item.name, item.seed)
            val progress = time / style.duration
            if (progress >= 1) return PropPose(opacity = 0f)
            val start = width - item.anchor + 40 * unit
            val travel = width + 80 * unit
            val curl = style.curl * unit
            val dx = start - travel * progress + curl * cos(time * style.spin)
            val dy = -curl * sin(time * style.spin) + style.wander * unit * sin(time * 1.1 + style.phase)
            val fadeIn = min(1.0, time / 0.4)
            val fadeOut = min(1.0, (style.duration - time) / 0.4)
            var opacity = fadeIn * fadeOut
            if (item.name == "firefly") opacity *= 0.65 + 0.35 * sin(time * 3 + style.phase)
            return PropPose(
                dx = dx.toFloat(),
                dy = dy.toFloat(),
                rotation = (sin(time * style.spin) * style.tilt).toFloat(),
                opacity = opacity.toFloat(),
                frame = (time / style.flap).toInt() % 2 + 1,
                pivotsAtBase = false,
            )
        }

        private fun swoop(item: PropItem, time: Double, width: Double, unit: Double): PropPose {
            val duration = 5.5
            val progress = time / duration
            if (progress >= 1) return PropPose(opacity = 0f)
            val start = width - item.anchor + 60 * unit
            val travel = width + 120 * unit
            return PropPose(
                dx = (start - travel * progress).toFloat(),
                dy = (-46 * unit * sin(PI * progress) + 8 * unit * sin(time * 2)).toFloat(),
                rotation = (-5 * cos(PI * progress)).toFloat(),
                opacity = (min(1.0, time / 0.4) * min(1.0, (duration - time) / 0.4)).toFloat(),
                frame = (time / 0.26).toInt() % 2 + 1,
                pivotsAtBase = false,
            )
        }

        private fun perch(time: Double, width: Double, unit: Double): PropPose {
            val arrive = min(1.0, time / 2.2)
            val eased = arrive * arrive * (3 - 2 * arrive)
            val curve = sin(PI * eased) * 34 * unit
            return PropPose(
                dx = ((1 - eased) * width * 0.45 - curve).toFloat(),
                dy = (-(1 - eased) * 130 * unit - curve * 0.5 + sin(time * 1.6) * 4 * unit).toFloat(),
                opacity = min(1.0, time / 0.3).toFloat(),
                frame = (time / if (arrive < 1) 0.14 else 0.55).toInt() % 2 + 1,
                pivotsAtBase = false,
            )
        }

        private fun popScale(time: Double): Double {
            val progress = min(1.0, time / 0.5)
            val overshoot = 1.70158
            val shifted = progress - 1
            return 1 + (overshoot + 1) * shifted.pow(3) + overshoot * shifted.pow(2)
        }

        private fun easeOut(progress: Double): Double = 1 - (1 - progress) * (1 - progress)
    }
}

class FlightStyle(name: String, seed: Int) {
    val duration: Double
    val curl: Double
    val spin: Double
    val wander: Double
    val flap: Double
    val tilt: Double
    val phase: Double = (seed % 7).toDouble()

    init {
        val style = when (name) {
            "bee" -> listOf(5.0, 10.0, 6.0, 14.0, 0.05, 6.0)
            "dragonfly" -> listOf(4.0, 6.0, 2.2, 22.0, 0.05, 4.0)
            "firefly" -> listOf(8.0, 16.0, 1.8, 18.0, 0.12, 5.0)
            "ladybird" -> listOf(6.0, 12.0, 4.5, 16.0, 0.06, 8.0)
            else -> listOf(7.0, 22.0, 3.4 + (seed % 3) * 0.3, 26.0, 0.09, 10.0)
        }
        duration = style[0]
        curl = style[1]
        spin = style[2]
        wander = style[3]
        flap = style[4]
        tilt = style[5]
    }
}
