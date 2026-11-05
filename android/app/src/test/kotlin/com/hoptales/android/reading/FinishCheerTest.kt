package com.hoptales.android.reading

import androidx.compose.ui.geometry.Offset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FinishCheerTest {
    private val word = Offset(200f, 600f)
    private val chip = Offset(300f, 1500f)

    @Test fun nothingMovesUntilThePanHasSettled() {
        assertEquals(1f, FinishCheer.wordScale(0.0))
        assertNull(FinishCheer.star(0, FinishCheer.START - 0.01, word, chip, 40f))
        assertEquals(1f, FinishCheer.chipScale(FinishCheer.START))
    }

    @Test fun theWordPopsInPlaceAndSettles() {
        assertTrue(FinishCheer.wordScale(FinishCheer.START + FinishCheer.POP_SECONDS / 2) > 1.2f)
        assertEquals(1f, FinishCheer.wordScale(FinishCheer.START + FinishCheer.POP_SECONDS))
    }

    @Test fun starsBurstOutOfTheWord() {
        val start = FinishCheer.star(0, FinishCheer.START, word, chip, 40f)
        assertEquals(word, start?.centre)
        val burst = FinishCheer.star(2, FinishCheer.START + FinishCheer.BURST_SECONDS, word, chip, 40f)
        assertTrue((burst!!.centre - word).getDistance() > 39f)
        assertTrue(burst.centre.y < word.y)
    }

    @Test fun starsLandOnTheChipThenDisappear() {
        val landing = FinishCheer.firstLanding - 0.0001
        val star = FinishCheer.star(0, landing, word, chip, 40f)
        assertTrue((star!!.centre - chip).getDistance() < 2f)
        assertNull(FinishCheer.star(0, FinishCheer.firstLanding + 0.01, word, chip, 40f))
        assertNull(FinishCheer.star(FinishCheer.STARS - 1, FinishCheer.lastLanding + 0.01, word, chip, 40f))
    }

    @Test fun theChipBumpsWhileTheStarsLand() {
        assertEquals(1f, FinishCheer.chipScale(FinishCheer.firstLanding))
        assertTrue(FinishCheer.chipScale((FinishCheer.firstLanding + FinishCheer.end) / 2) > 1.1f)
        assertEquals(1f, FinishCheer.chipScale(FinishCheer.end))
    }

    @Test fun theStarCountClimbsAsEachStarLands() {
        assertEquals(0, FinishCheer.shownStars(86, FinishCheer.START))
        assertEquals(14, FinishCheer.shownStars(86, FinishCheer.firstLanding))
        assertEquals(86, FinishCheer.shownStars(86, FinishCheer.lastLanding + 0.001))
        assertEquals(86, FinishCheer.shownStars(86, null))
    }
}
