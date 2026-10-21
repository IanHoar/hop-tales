package com.hoptales.android.world

import com.hoptales.content.Friend
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class HareSheetTest {
    @Test
    fun everyFriendHasTheirOwnSheets() {
        for (friend in Friend.entries) {
            val sheets = HareSheets.of(friend)
            assertEquals("${friend.key}-idle-frames", sheets.idle.asset)
            assertEquals("${friend.key}-hop", sheets.hop.asset)
            if (friend != Friend.HARE) assertNotEquals(HareSheets.hare, sheets)
        }
    }

    @Test
    fun theFeetSitInsideEveryCell() {
        for (friend in Friend.entries) {
            for (sheet in HareSheet.entries) {
                val art = HareSheets.of(friend).of(sheet)
                assertEquals(sheet.frames, art.frames)
                assertTrue(art.anchorX in 0f..1f)
                assertTrue(art.anchorY in 0.9f..1f)
            }
        }
    }

    @Test
    fun theHopIsScaledToTheRestingHeight() {
        assertEquals(1f, HareSheets.hare.idle.scale)
        assertEquals(345f / 322f, HareSheets.hare.hop.scale, 1e-6f)
        assertEquals(345f / 166f, HareSheets.of(Friend.GRASSHOPPER).hop.scale, 1e-6f)
    }

    @Test
    fun barnacleIsDrawnAtThreeQuarters() {
        val crab = HareSheets.of(Friend.CRAB)
        assertEquals(0.75f, crab.idle.scale)
        assertEquals(345f / 262f * 0.75f, crab.hop.scale, 1e-6f)
    }

    @Test
    fun bobLandsOnHisOwnFeet() {
        val bunny = HareSheets.of(Friend.BUNNY).hop
        assertEquals(175f, bunny.feetX)
        assertEquals(335f, bunny.feetY)
    }

    @Test
    fun buttonAndMarmaladeStandAboveThePath() {
        assertEquals(170f, WorldStyle.of(Friend.CROW).feetAbovePath)
        assertTrue(WorldStyle.of(Friend.CROW).chalk)
        assertEquals(170f, WorldStyle.of(Friend.CAT).feetAbovePath)
        assertEquals(WorldStyle.meadow, WorldStyle.of(Friend.HARE))
    }
}
