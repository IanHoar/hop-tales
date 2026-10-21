package com.hoptales.android.world

import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Easing
import androidx.compose.animation.core.LinearEasing
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

object IntroTimeline {
    const val SUNRISE = 0.6
    const val SUNRISE_LENGTH = 4.0
    const val HARE_POPS = 3.9
    const val TITLE_IN = 4.2
    const val HARE_TURNS = 5.6
    const val HARE_RUNS = 6.0
    const val RUN_LENGTH = 1.15
    const val TITLE_OUT = 6.2
    const val ROUTE = 6.7
    const val REDUCED_ROUTE = 0.3
    const val TITLE_FADE = 0.6
    const val HANDOVER_MILLIS = 700
    const val REDUCED_HANDOVER_MILLIS = 300
    const val HANDOVER_RISE = 80f
    const val HOP_FPS = 14.0

    val easeIn: Easing = CubicBezierEasing(0.42f, 0f, 1f, 1f)
    val easeOut: Easing = CubicBezierEasing(0f, 0f, 0.58f, 1f)
    val easeInOut: Easing = CubicBezierEasing(0.42f, 0f, 0.58f, 1f)
    val handover: Easing = CubicBezierEasing(0.2f, 0.8f, 0.2f, 1f)

    fun route(reduceMotion: Boolean) = if (reduceMotion) REDUCED_ROUTE else ROUTE
}

data class Step(val duration: Double, val to: Float? = null, val easing: Easing = LinearEasing)

class Track(private val start: Double, private val from: Float, private vararg val steps: Step) {
    fun at(time: Double): Float {
        var value = from
        var at = start
        if (time < at) return from
        for (step in steps) {
            val target = step.to ?: value
            if (time < at + step.duration) {
                val fraction = step.easing.transform(((time - at) / step.duration).toFloat())
                return value + (target - value) * fraction
            }
            value = target
            at += step.duration
        }
        return value
    }
}

data class HarePose(val alpha: Float, val scaleX: Float, val scaleY: Float)

data class IntroFrame(
    val dawn: Float,
    val day: Float,
    val stars: Float,
    val sunRise: Float,
    val glow: Float,
    val glowScale: Float,
    val clouds: Float,
    val cloudDrift: Float,
    val landDrop: Float,
    val saturation: Float,
    val landTints: List<Float>,
    val front: HarePose,
    val side: HarePose,
    val run: Float,
    val runTravel: Float,
    val runFrame: Int,
    val title: Float,
    val titleOffset: Float,
) {
    companion object {
        private const val START = IntroTimeline.SUNRISE
        private const val LENGTH = IntroTimeline.SUNRISE_LENGTH
        private const val LAYER_STAGGER = 0.12

        private val dawnTrack = Track(START, 0f, Step(LENGTH * 0.45, 1f))
        private val dayTrack = Track(START + LENGTH * 0.4, 0f, Step(LENGTH * 0.6, 1f))
        private val starsTrack = Track(START, 1f, Step(LENGTH * 0.55, 0f))
        private val riseTrack = Track(START, 0f, Step(LENGTH, 1f, IntroTimeline.easeInOut))
        private val glowTrack = Track(START, 0f, Step(LENGTH / 2, 1f), Step(LENGTH / 2, 0.5f))
        private val glowScaleTrack = Track(START, 0.8f, Step(LENGTH, 1.1f))
        private val cloudsTrack = Track(START, 0f, Step(1.9, 1f))
        private val driftTrack = Track(START, 0f, Step(6.0, 1f, IntroTimeline.easeOut))
        private val dropTrack = Track(START, 1f, Step(LENGTH, 0f, IntroTimeline.easeInOut))
        private val saturationTrack = Track(START, IntroLayout.NIGHT_SATURATION, Step(LENGTH, 1f))
        private val tintTracks = MeadowLayer.entries.map { layer ->
            Track(START + LAYER_STAGGER * layer.ordinal, IntroLayout.DIM_LAND, Step(LENGTH, 1f))
        }

        private const val POPS = IntroTimeline.HARE_POPS
        private const val SETTLED = IntroTimeline.HARE_TURNS - IntroTimeline.HARE_POPS - 0.8
        private val frontAlpha = Track(POPS, 0f, Step(0.2, 1f), Step(0.3 + 0.2 + SETTLED + 0.06), Step(0.04, 0f))
        private val frontX = Track(
            POPS, 1f, Step(0.0, 0.9f), Step(0.2), Step(0.3, 1.02f), Step(0.2, 1f), Step(SETTLED), Step(0.06, 0.82f), Step(0.04, 0.7f),
        )
        private val frontY = Track(
            POPS, 1f, Step(0.0, 1.08f), Step(0.2), Step(0.3, 0.98f), Step(0.2, 1f), Step(SETTLED), Step(0.06, 1.03f), Step(0.04, 1.03f),
        )

        private const val TURNS = IntroTimeline.HARE_TURNS
        private val sideAlpha = Track(TURNS, 0f, Step(0.09, 1f), Step(0.16 + 0.13), Step(0.02, 0f))
        private val sideX = Track(TURNS, 0.75f, Step(0.09, 1.03f), Step(0.16, 0.97f), Step(0.13, 1.06f))
        private val sideY = Track(TURNS, 1f, Step(0.09, 0.97f), Step(0.16, 1.03f), Step(0.13, 0.9f))

        private val runTrack = Track(IntroTimeline.HARE_RUNS, 0f, Step(IntroTimeline.RUN_LENGTH, 1f, IntroTimeline.easeIn))

        private const val TITLE_GONE = IntroTimeline.ROUTE - IntroTimeline.TITLE_OUT
        private val titleTrack = Track(
            IntroTimeline.TITLE_IN,
            0f,
            Step(IntroTimeline.TITLE_FADE, 1f, IntroTimeline.easeInOut),
            Step(IntroTimeline.TITLE_OUT - IntroTimeline.TITLE_IN - IntroTimeline.TITLE_FADE),
            Step(TITLE_GONE, 0f, IntroTimeline.easeInOut),
        )
        private val titleOffsetTrack = Track(
            IntroTimeline.TITLE_IN,
            10f,
            Step(IntroTimeline.TITLE_FADE, 0f, IntroTimeline.easeInOut),
            Step(IntroTimeline.TITLE_OUT - IntroTimeline.TITLE_IN - IntroTimeline.TITLE_FADE),
            Step(TITLE_GONE, -24f, IntroTimeline.easeInOut),
        )

        fun at(time: Double): IntroFrame {
            val running = time - IntroTimeline.HARE_RUNS
            val isRunning = running >= 0 && running < IntroTimeline.RUN_LENGTH
            val frames = HareSheet.HOP.frames
            return IntroFrame(
                dawn = dawnTrack.at(time),
                day = dayTrack.at(time),
                stars = starsTrack.at(time),
                sunRise = riseTrack.at(time),
                glow = glowTrack.at(time),
                glowScale = glowScaleTrack.at(time),
                clouds = cloudsTrack.at(time),
                cloudDrift = driftTrack.at(time),
                landDrop = dropTrack.at(time),
                saturation = saturationTrack.at(time),
                landTints = tintTracks.map { it.at(time) },
                front = HarePose(frontAlpha.at(time), frontX.at(time), frontY.at(time)),
                side = HarePose(sideAlpha.at(time), sideX.at(time), sideY.at(time)),
                run = if (isRunning) 1f else 0f,
                runTravel = runTrack.at(time),
                runFrame = min((max(running, 0.0) * IntroTimeline.HOP_FPS).toInt(), frames * 2 - 1) % frames,
                title = titleTrack.at(time),
                titleOffset = titleOffsetTrack.at(time),
            )
        }
    }
}

data class IntroSpot(val x: Float, val top: Float, val width: Float)

data class IntroSprite(val asset: String, val x: Float, val y: Float, val width: Float)

data class IntroLayout(val width: Float, val height: Float, val density: Float) {
    val k: Float get() = max(1f, min(width, height) / density / 390f * 0.62f) * density
    val scale: Float get() = BASE_SCALE * k
    val titleK: Float get() = min(1.6f, k / density)

    fun tileWidth(layer: MeadowLayer) = layer.pixelWidth * scale

    fun tileHeight(layer: MeadowLayer) = layer.pixelHeight * scale

    fun top(layer: MeadowLayer) = height - anchors.getValue(layer) * scale

    fun offset(layer: MeadowLayer): Float {
        val tile = tileWidth(layer)
        if (tile <= 0f) return 0f
        return -((offsets.getValue(layer) * scale) % tile)
    }

    fun tileCount(layer: MeadowLayer): Int {
        val tile = tileWidth(layer)
        return if (tile <= 0f) 1 else ceil(width / tile).toInt() + 1
    }

    val landDrop: Float get() = 26 * k
    val pathY: Float get() = top(MeadowLayer.NEAR) + 430 * scale
    val ground: Float get() = pathY + 8 * k
    val sunWidth: Float get() = 295 * scale
    val sunTop: Float get() = top(MeadowLayer.FAR) - 238 * scale
    val glowWidth: Float get() = sunWidth * 2.3f

    fun sunCentreY(sunHeight: Float, rise: Float) = sunTop + (170 + (-40 - 170) * rise) * k + sunHeight / 2

    val hareFrontHeight: Float get() = 132 * k
    val hareSideHeight: Float get() = 138 * k
    val hareRunHeight: Float get() = hareSideHeight * HOP_FRAME_HEIGHT / HOP_UPRIGHT
    val hareRunWidth: Float get() = hareRunHeight * HOP_FRAME_WIDTH / HOP_FRAME_HEIGHT
    val hareRunFeet: Float get() = hareRunHeight * (HOP_FRAME_HEIGHT - HOP_FEET) / HOP_FRAME_HEIGHT
    val runDistance: Float get() = width / 2 + hareRunWidth

    val stars: List<IntroSprite>
        get() = starSpots.mapIndexed { index, spot ->
            val size = spot.width * k
            IntroSprite("sky-star-${index % 3 + 1}", spot.x * width + size / 2, spot.top * height + size / 2, size)
        }

    val clouds: List<IntroCloud>
        get() {
            val farTop = top(MeadowLayer.FAR)
            return listOf(
                IntroCloud("sky-cloud-2", -0.08f * width + 65 * k - 24 * k, farTop - 180 * k, 130 * k, 34 * k),
                IntroCloud("sky-cloud-3", 0.72f * width + 55 * k + 20 * k, farTop - 250 * k, 110 * k, -26 * k),
            )
        }

    companion object {
        const val BASE_SCALE = 0.42f
        const val NIGHT_SATURATION = 0.55f
        const val DIM_LAND = 0.42f
        const val HOP_FRAME_WIDTH = 363f
        const val HOP_FRAME_HEIGHT = 346f
        const val HOP_UPRIGHT = 322f
        const val HOP_FEET = 334f
        const val NIGHT = 0xFF1E2A4E

        val night = listOf(0xFF1E2A4E, 0xFF3B4776, 0xFF6E6D92)
        val dawn = listOf(0xFF8FA6CF, 0xFFE7B6A2, 0xFFF6D6A6)
        val day = listOf(0xFFBCDCEE, 0xFFDCEBEF, 0xFFEEF2E6)

        val starSpots = listOf(
            IntroSpot(0.10f, 0.11f, 16f),
            IntroSpot(0.28f, 0.21f, 11f),
            IntroSpot(0.77f, 0.08f, 14f),
            IntroSpot(0.64f, 0.18f, 10f),
            IntroSpot(0.88f, 0.27f, 12f),
            IntroSpot(0.18f, 0.35f, 9f),
            IntroSpot(0.47f, 0.06f, 10f),
            IntroSpot(0.55f, 0.30f, 8f),
        )

        private val anchors = mapOf(MeadowLayer.FAR to 986f, MeadowLayer.MID to 848f, MeadowLayer.NEAR to 705f)
        private val offsets = mapOf(MeadowLayer.FAR to 900f, MeadowLayer.MID to 1400f, MeadowLayer.NEAR to 600f)

        private const val RED = 0.2125f
        private const val GREEN = 0.7154f
        private const val BLUE = 0.0721f

        fun landMatrix(saturation: Float, tint: Float): FloatArray? {
            if (saturation >= 1f && tint >= 1f) return null
            val grey = 1 - saturation
            val weights = floatArrayOf(RED * grey, GREEN * grey, BLUE * grey)
            val matrix = FloatArray(20)
            for (row in 0 until 3) {
                for (column in 0 until 3) {
                    matrix[row * 5 + column] = tint * (weights[column] + if (row == column) saturation else 0f)
                }
            }
            matrix[18] = 1f
            return matrix
        }
    }
}

data class IntroCloud(val asset: String, val x: Float, val top: Float, val width: Float, val drift: Float)
