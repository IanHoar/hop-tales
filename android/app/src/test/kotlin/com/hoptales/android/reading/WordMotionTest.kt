package com.hoptales.android.reading

import com.hoptales.reading.HopTarget
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WordMotionTest {
    private val first = HopTarget(0, 0)
    private val second = HopTarget(0, 1)
    private val quiet = WordSpeech(speaking = false, at = Double.NEGATIVE_INFINITY)
    private val hop = WordMove(first, second, at = 10.0)

    @Test
    fun theNewWordGrowsOverThreeTenthsOfASecond() {
        assertEquals(PathGeometry.SIDE_SCALE, WordMotion.look(second, false, hop, quiet, 10.0).scale, 0.0001f)
        val midway = WordMotion.look(second, false, hop, quiet, 10.15).scale
        assertTrue(midway > PathGeometry.SIDE_SCALE && midway < 1f)
        assertEquals(1f, WordMotion.look(second, false, hop, quiet, 10.3).scale, 0.0001f)
        assertEquals(PathGeometry.SIDE_SCALE, WordMotion.look(first, false, hop, quiet, 10.3).scale, 0.0001f)
    }

    @Test
    fun theReadWashWaitsAQuarterSecondThenFadesInOverPointThreeFive() {
        assertEquals(0f, WordMotion.look(first, false, hop, quiet, 10.25).wash, 0.0001f)
        val fading = WordMotion.look(first, false, hop, quiet, 10.4).wash
        assertTrue(fading > 0f && fading < 1f)
        assertEquals(1f, WordMotion.look(first, false, hop, quiet, 10.6).wash, 0.0001f)
        assertEquals(0f, WordMotion.look(second, false, hop, quiet, 10.6).wash, 0.0001f)
    }

    @Test
    fun theInkFollowsTheScale() {
        assertEquals(WordState.UPCOMING.ink, WordMotion.look(second, false, hop, quiet, 10.0).ink)
        assertEquals(WordState.CURRENT.ink, WordMotion.look(second, false, hop, quiet, 10.3).ink)
    }

    @Test
    fun reducedMotionSettlesAtOnce() {
        val still = WordMotion.look(second, true, hop, quiet, null)
        assertEquals(WordMotion.BIG_WORD_SCALE, still.scale, 0.0001f)
        assertEquals(WordState.CURRENT, still.state)
        assertEquals(1f, WordMotion.look(first, false, hop, quiet, null).wash, 0.0001f)
        assertTrue(WordMotion.look(first, true, hop, quiet, null).solidUnderline)
        assertEquals(0f, WordMotion.look(first, true, hop, quiet, null).pop, 0.0001f)
    }

    @Test
    fun theHintPulsesTheCurrentWordThreeTimesThenHolds() {
        val settled = WordMove(second, second, Double.NEGATIVE_INFINITY)
        val speaking = WordSpeech(speaking = true, at = 20.0)
        fun scale(at: Double) = WordMotion.look(second, false, settled, speaking, at).scale
        assertEquals(1f, scale(20.0), 0.0001f)
        assertEquals(WordMotion.PULSE_SCALE, scale(20.28), 0.0001f)
        assertEquals(1f, scale(20.56), 0.0001f)
        assertEquals(WordMotion.PULSE_SCALE, scale(20.84), 0.0001f)
        assertEquals(WordMotion.PULSE_SCALE, scale(25.0), 0.0001f)
        assertEquals(PathGeometry.SIDE_SCALE, WordMotion.look(first, false, settled, speaking, 20.28).scale, 0.0001f)
        val done = WordSpeech(speaking = false, at = 30.0)
        assertEquals(WordMotion.PULSE_SCALE, WordMotion.look(second, false, settled, done, 30.0).scale, 0.0001f)
        assertEquals(1f, WordMotion.look(second, false, settled, done, 30.84).scale, 0.0001f)
    }

    @Test
    fun aBigWordIsLargerAndPopsAPlusFiveWhenRead() {
        assertEquals(PathGeometry.SIDE_SCALE * 1.08f, WordMotion.look(HopTarget(0, 2), true, hop, quiet, 11.0).scale, 0.0001f)
        val popping = WordMotion.look(first, true, hop, quiet, 10.3)
        assertTrue(popping.pop > 0.5f)
        assertEquals(0f, popping.star, 0.0001f)
        assertTrue(popping.rise > WordMotion.POP_FROM)
        assertEquals(0f, WordMotion.look(first, true, hop, quiet, 11.0).pop, 0.0001f)
        assertEquals(WordMotion.POP_TO, WordMotion.look(first, true, hop, quiet, 11.0).rise, 0.0001f)
        assertFalse(WordMotion.look(first, true, hop, quiet, 11.0).solidUnderline)
        assertEquals(1f, WordMotion.look(second, true, hop, quiet, 11.0).star, 0.0001f)
    }

    @Test
    fun aReadBigWordsStarShrinksAndFadesOverThreeTenthsOfASecond() {
        val start = WordMotion.look(first, true, hop, quiet, 10.0)
        assertEquals(1f, start.star, 0.0001f)
        assertEquals(1f, start.starScale, 0.0001f)
        val midway = WordMotion.look(first, true, hop, quiet, 10.15)
        assertTrue(midway.star > 0f && midway.star < 1f)
        assertEquals(midway.star, midway.starScale, 0.0001f)
        assertTrue(midway.pop > 0f)
        assertEquals(0f, WordMotion.look(first, true, hop, quiet, 10.3).star, 0.0001f)
        assertEquals(0f, WordMotion.look(first, true, hop, quiet, null).star, 0.0001f)
    }

    @Test
    fun movesAndSpeechAreRecordedOnlyWhenTheyChange() {
        val moves = WordMoves(first, speaking = false)
        val move = moves.moved(second, 5.0)
        assertEquals(WordMove(first, second, 5.0), move)
        assertEquals(move, moves.moved(second, 6.0))
        assertEquals(WordSpeech(true, 7.0), moves.spoke(true, 7.0))
        assertEquals(WordSpeech(true, 7.0), moves.spoke(true, 8.0))
        assertFalse(WordMotion.isSettled(move, WordSpeech(true, 7.0), 7.5))
        assertTrue(WordMotion.isSettled(move, WordSpeech(true, 7.0), 8.0))
    }
}
