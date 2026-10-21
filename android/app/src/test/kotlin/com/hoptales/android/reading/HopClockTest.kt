package com.hoptales.android.reading

import org.junit.Assert.assertEquals
import org.junit.Test

class HopClockTest {
    @Test
    fun aClockThatNeverBeganKeepsTime() {
        assertEquals(5.0, HopClock().time(5.0), 1e-9)
    }

    @Test
    fun aPromptFirstFrameLosesNothing() {
        val clock = HopClock()
        clock.began(10.0)
        assertEquals(10.02, clock.time(10.02), 1e-9)
        assertEquals(10.5, clock.time(10.5), 1e-9)
    }

    @Test
    fun aLateFirstFrameStartsTheHopOneFrameIn() {
        val clock = HopClock()
        clock.began(10.0)
        assertEquals(10.0 + HopClock.FRAME_BUDGET, clock.time(10.4), 1e-9)
        assertEquals(10.1 + HopClock.FRAME_BUDGET, clock.time(10.5), 1e-9)
    }

    @Test
    fun theNextHopForgetsTheLastDelay() {
        val clock = HopClock()
        clock.began(10.0)
        clock.time(10.4)
        clock.began(20.0)
        assertEquals(20.01, clock.time(20.01), 1e-9)
    }
}
