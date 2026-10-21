package com.hoptales.reading

import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.min
import kotlin.math.sin

object Chord {
    val NOTES = doubleArrayOf(523.25, 659.25, 783.99, 1046.5)
    const val STAGGER = 0.045
    const val DECAY = 0.38
    const val LENGTH = 1.1
    const val LEVEL = 0.2f
    const val RELEASE = 0.2
    const val SAMPLE_RATE = 44_100

    fun sample(time: Double): Float {
        var value = 0.0
        NOTES.forEachIndexed { index, frequency ->
            val local = time - index * STAGGER
            if (local < 0) return@forEachIndexed
            val attack = min(local / 0.004, 1.0)
            val fundamental = sin(2 * PI * frequency * local)
            val overtone = 0.25 * sin(2 * PI * frequency * 3.93 * local) * exp(-local / 0.06)
            value += attack * exp(-local / DECAY) * (fundamental + overtone)
        }
        val fade = ((LENGTH - time) / RELEASE).coerceIn(0.0, 1.0)
        return (value * fade).toFloat() * LEVEL
    }

    fun samples(): FloatArray = FloatArray((LENGTH * SAMPLE_RATE).toInt()) { sample(it.toDouble() / SAMPLE_RATE) }
}
