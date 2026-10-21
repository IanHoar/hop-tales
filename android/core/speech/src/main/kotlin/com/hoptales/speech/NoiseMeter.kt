package com.hoptales.speech

import kotlin.math.log10
import kotlin.math.pow

class NoiseMeter {
    private val levels = ArrayDeque<Double>()
    private var power = 0.0
    private var readings = 0
    private var blockStart: Long? = null

    val floor: Double
        @Synchronized get() = floor(levels.toList())

    @Synchronized
    fun add(decibels: Float, now: Long) {
        val start = blockStart ?: now.also { blockStart = it }
        power += 10.0.pow(decibels / 10.0)
        readings += 1
        if (now - start < BLOCK_MILLIS) return
        levels.addLast(decibels(power / readings))
        if (levels.size > WINDOW) levels.removeFirst()
        power = 0.0
        readings = 0
        blockStart = null
    }

    companion object {
        const val SILENT = -100.0
        const val BLOCK_MILLIS = 100L
        const val WINDOW = 30
        const val FLOOR_RANK = 0.1
        const val SAMPLE_MILLIS = 500L

        fun decibels(meanPower: Double): Double = if (meanPower > 0) maxOf(SILENT, 10 * log10(meanPower)) else SILENT

        fun floor(levels: List<Double>): Double {
            if (levels.isEmpty()) return SILENT
            val sorted = levels.sorted()
            return sorted[((sorted.size - 1) * FLOOR_RANK).toInt()]
        }
    }
}
