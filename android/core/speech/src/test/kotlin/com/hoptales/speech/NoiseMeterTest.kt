package com.hoptales.speech

import org.junit.Assert.assertEquals
import org.junit.Test
import kotlin.math.log10

class NoiseMeterTest {
    private var now = 0L

    private fun block(meter: NoiseMeter, decibels: Float) {
        meter.add(decibels, now)
        now += NoiseMeter.BLOCK_MILLIS
        meter.add(decibels, now)
        now += 1
    }

    @Test fun silenceReadsAsTheFloorOfTheScale() {
        assertEquals(NoiseMeter.SILENT, NoiseMeter().floor, 0.0)
    }

    @Test fun theFloorIsTheSteadyBackgroundNotTheSpeech() {
        val meter = NoiseMeter()
        repeat(NoiseMeter.WINDOW) { block(meter, if (it % 3 == 0) 8f else -1f) }
        assertEquals(-1.0, meter.floor, 0.5)
    }

    @Test fun aSteadyNoisyRoomRaisesTheFloor() {
        val meter = NoiseMeter()
        repeat(NoiseMeter.WINDOW) { block(meter, 4f) }
        assertEquals(4.0, meter.floor, 0.5)
    }

    @Test fun onlyTheLastFewSecondsCount() {
        val meter = NoiseMeter()
        repeat(NoiseMeter.WINDOW) { block(meter, 6f) }
        repeat(NoiseMeter.WINDOW) { block(meter, -2f) }
        assertEquals(-2.0, meter.floor, 0.5)
    }

    @Test fun aBlockAveragesThePowerOfItsReadings() {
        val meter = NoiseMeter()
        meter.add(0f, 0)
        meter.add(10f, NoiseMeter.BLOCK_MILLIS)
        assertEquals(10 * log10(5.5), meter.floor, 0.01)
    }
}
