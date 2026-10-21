package com.hoptales.android.reading

import com.hoptales.android.world.HareFrame
import com.hoptales.android.world.HareSheet
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class HareMotionTest {
    private fun HareMotion.length() = hop!!.length

    @Test
    fun theHopPlaysEightFramesAtFourteenFramesASecond() {
        val motion = HareMotion().jump(10.0, distance = 80f, carried = false)
        assertEquals(8.0 / 14, motion.length(), 0.0001)
        val frames = (0 until 8).map { step -> motion.pose(10 + (step + 0.5) / 14, reduceMotion = false).frame }
        assertEquals((0 until 8).map { HareFrame(HareSheet.HOP, it) }, frames)
        assertEquals(HareSheet.IDLE, motion.pose(10 + motion.length() + 0.01, reduceMotion = false).frame.sheet)
    }

    @Test
    fun heOnlyTravelsDuringTheSecondToSeventhFrames() {
        val motion = HareMotion().jump(0.0, distance = 80f, carried = false)
        assertEquals(0f, motion.x(0.5 / 14))
        assertEquals(0f, motion.x(1.0 / 14))
        assertTrue(motion.x(4.0 / 14) > 0)
        assertEquals(80f, motion.x(7.0 / 14), 0.0001f)
        assertEquals(80f, motion.x(7.9 / 14), 0.0001f)
    }

    @Test
    fun heLeavesTheCardInAnArcAndLandsOnIt() {
        val motion = HareMotion().jump(0.0, distance = 80f, carried = false)
        assertEquals(0f, motion.lift(1.0 / 14))
        assertEquals(HareMotion.APEX, motion.lift(4.0 / 14), 0.0001f)
        assertEquals(0f, motion.lift(7.0 / 14))
    }

    @Test
    fun aNewSentenceIsABiggerJump() {
        val motion = HareMotion().jump(0.0, distance = 400f, carried = true)
        assertEquals(HareMotion.SENTENCE_APEX, motion.lift(4.0 / 14), 0.0001f)
        assertTrue(HareMotion.SENTENCE_APEX > HareMotion.APEX)
        assertEquals(7.0 / 14, HareMotion.TAKE_OFF + HareMotion.AIR_TIME, 0.0001)
    }

    @Test
    fun aWordReadMidHopLandsOnThatWordWithoutOvershooting() {
        val motion = HareMotion().jump(0.0, distance = 80f, carried = false).jump(4.0 / 14, distance = 150f, carried = false)
        val landing = 4.0 / 14 + motion.length()
        assertEquals(150f, motion.x(landing - 0.001), 0.5f)
    }

    @Test
    fun fastReadingSpeedsTheHopsUpAndCalmsDownAfter() {
        var motion = HareMotion().jump(0.0, distance = 80f, carried = false)
        val first = motion.length()
        motion = motion.jump(0.1, distance = 160f, carried = false)
        val second = motion.length()
        motion = motion.jump(0.2, distance = 240f, carried = false)
        val third = motion.length()
        assertTrue(second < first)
        assertTrue(third < second)
        for (step in 1..10) motion = motion.jump(0.2 + step * 0.05, distance = 300f, carried = false)
        assertEquals(HareMotion.FASTEST_RATE, motion.hop!!.rate, 0.0)
        val calm = motion.jump(10.0, distance = 60f, carried = false).length()
        assertEquals(first, calm, 0.0001)
    }

    @Test
    fun afterLandingHeRidesTheWordsBackToTheCentre() {
        val motion = HareMotion().jump(0.0, distance = 80f, carried = false)
        val landing = motion.length()
        assertTrue(motion.x(landing + HareMotion.RIDE / 2) < 80)
        assertEquals(0f, motion.x(landing + HareMotion.RIDE))
    }

    @Test
    fun aWordReadMidHopSetsOffFromWhereHeIs() {
        val motion = HareMotion().jump(0.0, distance = 80f, carried = false)
        val midway = motion.x(4.0 / 14)
        assertEquals(midway, motion.jump(4.0 / 14, distance = 60f, carried = false).hop!!.fromX)
    }

    @Test
    fun aNewSentenceCarriesHimWithTheCards() {
        val motion = HareMotion().jump(0.0, distance = 400f, carried = true)
        assertEquals(0f, motion.x(4.0 / 14))
        assertEquals(HareSheet.HOP, motion.pose(4.0 / 14, reduceMotion = false).frame.sheet)
    }

    @Test
    fun reduceMotionHoldsTheRestingPose() {
        val motion = HareMotion().jump(0.0, distance = 80f, carried = false)
        assertEquals(HareMotion.Pose.resting, motion.pose(0.2, reduceMotion = true))
        assertEquals(HareMotion.Pose.resting, motion.pose(30.0, reduceMotion = true))
    }
}
