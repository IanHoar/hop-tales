package com.hoptales.android.world

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class IdlePoseTest {
    @Test
    fun stillFriendRestsWithoutBreathing() {
        for (time in listOf(0.0, 1.9, 4.2, 11.7)) assertEquals(IdlePose.resting, IdlePose.at(time, still = true))
    }

    @Test
    fun movingFriendBreathes() {
        assertNotEquals(1f, IdlePose.at(IdleMotion.BREATH / 2, still = false).scaleY)
    }
}
