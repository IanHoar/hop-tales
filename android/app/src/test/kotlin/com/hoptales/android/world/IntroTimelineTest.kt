package com.hoptales.android.world

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class IntroTimelineTest {
    private val phone = IntroLayout(390f, 844f, 1f)

    @Test
    fun frameZeroIsTheNightMeadow() {
        val frame = IntroFrame.at(0.0)
        assertEquals(0f, frame.dawn)
        assertEquals(0f, frame.day)
        assertEquals(1f, frame.stars)
        assertEquals(0f, frame.sunRise)
        assertEquals(0f, frame.glow)
        assertEquals(0f, frame.clouds)
        assertEquals(1f, frame.landDrop)
        assertEquals(IntroLayout.NIGHT_SATURATION, frame.saturation)
        assertEquals(List(3) { IntroLayout.DIM_LAND }, frame.landTints)
        assertEquals(0f, frame.front.alpha)
        assertEquals(0f, frame.side.alpha)
        assertEquals(0f, frame.run)
        assertEquals(0f, frame.title)
    }

    @Test
    fun nothingMovesBeforeTheSunrise() {
        assertEquals(IntroFrame.at(0.0), IntroFrame.at(IntroTimeline.SUNRISE - 0.01))
    }

    @Test
    fun theSkyTurnsFromNightToDay() {
        val mid = IntroFrame.at(IntroTimeline.SUNRISE + 1.8)
        assertEquals(1f, mid.dawn, 1e-4f)
        assertEquals(0.08333f, mid.day, 1e-4f)
        assertEquals(0.1818f, mid.stars, 1e-3f)
        assertEquals(0.9f, mid.glow, 1e-4f)
        val risen = IntroFrame.at(IntroTimeline.SUNRISE + IntroTimeline.SUNRISE_LENGTH)
        assertEquals(1f, risen.day)
        assertEquals(0f, risen.stars)
        assertEquals(1f, risen.sunRise)
        assertEquals(0.5f, risen.glow)
        assertEquals(1.1f, risen.glowScale, 1e-5f)
        assertEquals(0f, risen.landDrop)
        assertEquals(1f, risen.saturation)
    }

    @Test
    fun theLandBrightensFarToNear() {
        val tints = IntroFrame.at(IntroTimeline.SUNRISE + 2.0).landTints
        assertEquals(0.71f, tints[0], 1e-4f)
        assertEquals(0.6926f, tints[1], 1e-4f)
        assertEquals(0.6752f, tints[2], 1e-4f)
        assertEquals(List(3) { 1f }, IntroFrame.at(5.0).landTints)
    }

    @Test
    fun theHarePopsUpThenTurnsAndRunsOff() {
        val popping = IntroFrame.at(IntroTimeline.HARE_POPS + 0.1)
        assertEquals(0.5f, popping.front.alpha, 1e-4f)
        assertEquals(HarePose(1f, 1f, 1f), IntroFrame.at(5.0).front)
        assertEquals(0f, IntroFrame.at(IntroTimeline.HARE_TURNS).front.alpha, 1e-3f)
        assertEquals(0.75f, IntroFrame.at(IntroTimeline.HARE_TURNS).side.scaleX)
        assertEquals(1f, IntroFrame.at(IntroTimeline.HARE_TURNS + 0.09).side.alpha, 1e-3f)
        assertEquals(0f, IntroFrame.at(IntroTimeline.HARE_TURNS + 0.5).side.alpha)
        val running = IntroFrame.at(IntroTimeline.HARE_RUNS + 0.3)
        assertEquals(1f, running.run)
        assertEquals(4, running.runFrame)
        assertEquals(1, IntroFrame.at(IntroTimeline.HARE_RUNS + 9.5 / 14).runFrame)
        assertEquals(0f, IntroFrame.at(IntroTimeline.HARE_RUNS + IntroTimeline.RUN_LENGTH).run)
    }

    @Test
    fun theTitleRisesInAndLiftsAway() {
        assertEquals(0f, IntroFrame.at(IntroTimeline.TITLE_IN).title)
        assertEquals(10f, IntroFrame.at(IntroTimeline.TITLE_IN).titleOffset)
        val shown = IntroFrame.at(IntroTimeline.TITLE_OUT)
        assertEquals(1f, shown.title, 1e-3f)
        assertEquals(0f, shown.titleOffset, 1e-2f)
        val gone = IntroFrame.at(IntroTimeline.ROUTE)
        assertEquals(0f, gone.title, 1e-3f)
        assertEquals(-24f, gone.titleOffset, 1e-2f)
    }

    @Test
    fun aTrackHoldsAndJumps() {
        val track = Track(1.0, 0f, Step(0.0, 2f), Step(1.0), Step(2.0, 4f))
        assertEquals(0f, track.at(0.5))
        assertEquals(2f, track.at(1.0))
        assertEquals(2f, track.at(1.9))
        assertEquals(3f, track.at(3.0))
        assertEquals(4f, track.at(10.0))
    }

    @Test
    fun theLayoutMatchesSwiftOnAPhone() {
        assertEquals(1f, phone.k)
        assertEquals(844f - 705 * 0.42f, phone.top(MeadowLayer.NEAR))
        assertEquals(844f - 986 * 0.42f, phone.top(MeadowLayer.FAR))
        assertEquals(-378f, phone.offset(MeadowLayer.FAR), 1e-3f)
        assertEquals(-588f, phone.offset(MeadowLayer.MID), 1e-3f)
        assertEquals(-252f, phone.offset(MeadowLayer.NEAR), 1e-3f)
        assertEquals(844f - 705 * 0.42f + 430 * 0.42f + 8, phone.ground, 1e-3f)
        assertEquals(26f, phone.landDrop)
        assertEquals(148.2857f, phone.hareRunHeight, 1e-3f)
        assertEquals(5.1429f, phone.hareRunFeet, 1e-3f)
        assertEquals(IntroSprite("sky-star-1", 47f, 100.84f, 16f), phone.stars[0])
    }

    @Test
    fun theLayoutGrowsOnATablet() {
        val tablet = IntroLayout(1668f, 2388f, 2f)
        assertEquals(1.3258f * 2, tablet.k, 1e-3f)
        assertEquals(1.3258f, tablet.titleK, 1e-3f)
        assertEquals(1.6f, IntroLayout(2732f, 2048f, 1f).titleK)
    }

    @Test
    fun theLandMatrixDesaturatesAndDims() {
        assertNull(IntroLayout.landMatrix(1f, 1f))
        val grey = IntroLayout.landMatrix(0f, 0.5f)!!
        assertArrayEquals(floatArrayOf(0.10625f, 0.3577f, 0.03605f, 0f, 0f), grey.copyOfRange(0, 5), 1e-5f)
        assertArrayEquals(grey.copyOfRange(0, 3), grey.copyOfRange(5, 8), 1e-6f)
        assertEquals(1f, grey[18])
        val dim = IntroLayout.landMatrix(1f, 0.42f)!!
        assertArrayEquals(floatArrayOf(0.42f, 0f, 0f, 0f, 0f, 0f, 0.42f, 0f), dim.copyOfRange(0, 8), 1e-6f)
    }
}
