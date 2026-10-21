package com.hoptales.android.reading

import org.junit.Assert.assertEquals
import org.junit.Test

class FriendRevealTest {
    @Test
    fun theRevealWaitsShakesThenSettles() {
        assertEquals(RevealStage.HIDDEN, FriendReveal.stage(0))
        assertEquals(RevealStage.SHAKING, FriendReveal.stage(300))
        assertEquals(RevealStage.REVEALED, FriendReveal.stage(1_300))
        assertEquals(RevealStage.SETTLED, FriendReveal.stage(2_200))
    }

    @Test
    fun theSilhouetteSwingsWiderEachTimeThenComesHome() {
        assertEquals(0f, FriendReveal.keyframes(FriendReveal.swings, 0.0), 0.0001f)
        assertEquals(3f, FriendReveal.keyframes(FriendReveal.swings, 0.11), 0.0001f)
        assertEquals(-9f, FriendReveal.keyframes(FriendReveal.swings, 0.88), 0.0001f)
        assertEquals(0f, FriendReveal.keyframes(FriendReveal.swings, 0.98), 0.0001f)
    }

    @Test
    fun theFriendBouncesTwiceAsItLands() {
        assertEquals(16f, FriendReveal.keyframes(FriendReveal.lifts, 0.18), 0.0001f)
        assertEquals(0f, FriendReveal.keyframes(FriendReveal.lifts, 0.36), 0.0001f)
        assertEquals(6f, FriendReveal.keyframes(FriendReveal.lifts, 0.50), 0.0001f)
        assertEquals(0f, FriendReveal.keyframes(FriendReveal.lifts, 1.0), 0.0001f)
    }
}
