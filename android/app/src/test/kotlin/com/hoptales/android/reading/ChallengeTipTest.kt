package com.hoptales.android.reading

import androidx.compose.ui.geometry.Offset
import com.hoptales.reading.HopTarget
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ChallengeTipTest {
    private val current = HopTarget(1, 2)
    private val later = HopTarget(1, 4)

    @Test
    fun theTipReadsAsOnIOSAndHoldsForFourSeconds() {
        assertEquals("Challenge word", ChallengeTip.TITLE)
        assertEquals("A word from a level or two ahead, worth 5 steps instead of 1.", ChallengeTip.DETAIL)
        assertEquals(4_000L, ChallengeTip.HOLD_MILLIS)
        assertEquals(500L, ChallengeTip.LONG_PRESS_MILLIS)
    }

    @Test
    fun aLongPressOnTheCurrentChallengeWordExplainsIt() {
        assertEquals(WordResponse.Explain(current), ChallengeTip.respond(WordPress.LONG_PRESS, current, current, isChallenge = true))
        assertEquals(WordResponse.Hear, ChallengeTip.respond(WordPress.TAP, current, current, isChallenge = true))
        assertEquals(WordResponse.Hear, ChallengeTip.respond(WordPress.LONG_PRESS, current, current, isChallenge = false))
    }

    @Test
    fun aTapOnAnotherChallengeWordExplainsIt() {
        assertEquals(WordResponse.Explain(later), ChallengeTip.respond(WordPress.TAP, later, current, isChallenge = true))
        assertNull(ChallengeTip.respond(WordPress.LONG_PRESS, later, current, isChallenge = true))
        assertNull(ChallengeTip.respond(WordPress.TAP, later, current, isChallenge = false))
    }

    @Test
    fun targetsAreAtLeastFortyFourPointsAcross() {
        val centre = Offset(100f, 100f)
        assertTrue(ChallengeTip.hits(Offset(121f, 121f), centre, width = 10f, height = 10f, minimum = 44f, isCurrent = true))
        assertFalse(ChallengeTip.hits(Offset(123f, 100f), centre, width = 10f, height = 10f, minimum = 44f, isCurrent = true))
        assertTrue(ChallengeTip.hits(Offset(121f, 104f), centre, width = 10f, height = 10f, minimum = 44f, isCurrent = false))
        assertFalse(ChallengeTip.hits(Offset(100f, 106f), centre, width = 10f, height = 10f, minimum = 44f, isCurrent = false))
    }

    @Test
    fun theTipStaysOnScreen() {
        val geometry = PathGeometry(390f, 844f, 1f)
        assertEquals(141f, ChallengeTip.x(0f, 390f, geometry), 0.001f)
        assertEquals(200f, ChallengeTip.x(200f, 390f, geometry), 0.001f)
        assertEquals(249f, ChallengeTip.x(400f, 390f, geometry), 0.001f)
    }
}
