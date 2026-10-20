package com.hoptales.android.world

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.floor

object IdleMotion {
    private data class Beat(val index: Int, val hold: Double)

    private data class Event(val start: Double, val gesture: List<Beat>)

    const val BREATH = 3.8
    private const val BREATH_Y = 0.014f
    private const val BREATH_X = 0.006f
    const val CYCLE = 18.0
    private const val FIRST_BEAT = 2.4
    private const val GAP_VARIANCE = 0.3
    const val REST = 0

    private val blink = listOf(Beat(5, 0.05), Beat(3, 0.09), Beat(5, 0.06))
    private val ear = listOf(Beat(6, 0.09), Beat(7, 0.09), Beat(2, 1.1), Beat(7, 0.1), Beat(6, 0.1))
    private val tilt = listOf(Beat(8, 0.14), Beat(9, 0.14), Beat(4, 2.6), Beat(9, 0.16), Beat(8, 0.16))
    private val sniff = listOf(Beat(1, 0.5))
    private val gestures = listOf(blink, ear, tilt, blink, blink, sniff)
    private val gaps = listOf(2.4, 2.0, 1.4, 2.0, 1.6, 0.0)

    private fun length(gesture: List<Beat>) = gesture.sumOf { it.hold }

    private fun schedule(cycle: Long): List<Event> {
        val random = Scatter(cycle)
        val order = gestures.indices.toMutableList()
        for (slot in order.indices.reversed()) {
            val other = random.below(slot + 1)
            order[slot] = order[other].also { order[other] = order[slot] }
        }
        var start = FIRST_BEAT * (1 + GAP_VARIANCE * random.signed())
        val events = mutableListOf<Event>()
        for ((slot, gesture) in order.withIndex()) {
            val beats = gestures[gesture]
            if (start + length(beats) >= CYCLE) break
            events += Event(start, beats)
            start += length(beats) + gaps[slot] * (1 + GAP_VARIANCE * random.signed())
        }
        return events
    }

    fun frame(time: Double): Int {
        val cycle = floor(time / CYCLE).toLong()
        val local = time - cycle * CYCLE
        for (event in schedule(cycle)) {
            if (local < event.start) continue
            var cursor = event.start
            for (beat in event.gesture) {
                if (local < cursor + beat.hold) return beat.index
                cursor += beat.hold
            }
        }
        return REST
    }

    fun breathing(time: Double): Pair<Float, Float> {
        val swell = ((1 - cos(2 * PI * time / BREATH)) / 2).toFloat()
        return (1 + BREATH_X * swell) to (1 + BREATH_Y * swell)
    }

    private class Scatter(seed: Long) {
        private var state: ULong = seed.toULong() * 0x9E3779B97F4A7C15uL + 0x2545F4914F6CDD1DuL

        fun next(): ULong {
            state += 0x9E3779B97F4A7C15uL
            var value = state
            value = (value xor (value shr 30)) * 0xBF58476D1CE4E5B9uL
            value = (value xor (value shr 27)) * 0x94D049BB133111EBuL
            return value xor (value shr 31)
        }

        fun below(bound: Int): Int = (next() % bound.toULong()).toInt()

        fun signed(): Double = (next() % 20_001uL).toDouble() / 10_000 - 1
    }
}
