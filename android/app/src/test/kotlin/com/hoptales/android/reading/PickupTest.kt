package com.hoptales.android.reading

import androidx.compose.ui.geometry.Offset
import com.hoptales.content.Friend
import com.hoptales.content.StoryTreat
import com.hoptales.content.WordRef
import com.hoptales.reading.HopTarget
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PickupTest {
    @Test
    fun theTreatIsPickedUpSixHopFramesIn() {
        assertEquals(6 / 14.0, PathMarks.PICKUP_DELAY, 0.0001)
        assertEquals(1.8, PathMarks.HIDE_AFTER, 0.0001)
    }

    @Test
    fun theStickerSwingsFromTheHareToTheChip() {
        val start = Offset(108f, 674f)
        val chip = Offset(298f, 96f)
        assertEquals(PickupFrame(108f, 674f, -24f, 1f, 1f), Pickup.frame(start, chip, 0f))
        assertEquals(PickupFrame(298f, 96f, 0f, 0.6f, 0f), Pickup.frame(start, chip, 1f))
        assertEquals(-12f, Pickup.frame(start, chip, 0.5f).rotation, 0.0001f)
        assertEquals(0f, Pickup.frame(start, chip, 1.1f).alpha, 0.0001f)
    }

    @Test
    fun theChipSitsWhereIOSPutsIt() {
        val geometry = PathGeometry(390f, 844f, 1f)
        assertEquals(Offset(108f, 640f + 34f), Pickup.start(geometry))
        assertEquals(Offset(390f - 92f, 96f), Pickup.chip(geometry))
    }

    @Test
    fun onlyHoppingForwardOffTheTreatWordPicksItUp() {
        val treat = StoryTreat(WordRef(1, 2), Friend.HARE, isTrail = false)
        assertEquals(treat, Pickup.passed(treat, HopTarget(1, 2), HopTarget(1, 3)))
        assertEquals(treat, Pickup.passed(treat, HopTarget(1, 2), HopTarget(2, 0)))
        assertNull(Pickup.passed(treat, HopTarget(1, 1), HopTarget(1, 2)))
        assertNull(Pickup.passed(treat, HopTarget(1, 3), HopTarget(1, 2)))
        assertNull(Pickup.passed(null, HopTarget(1, 2), HopTarget(1, 3)))
    }
}
