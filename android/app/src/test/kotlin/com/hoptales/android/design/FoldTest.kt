package com.hoptales.android.design

import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FoldTest {
    private val screen = Size(669f, 951f)

    @Test
    fun aFoldAcrossTheScreenLeavesTheHalfBelowIt() {
        val fold = Fold(Rect(0f, 455f, 669f, 495f))
        assertTrue(fold.runsAcross)
        assertEquals(Rect(0f, 495f, 669f, 951f), fold.room(screen))
    }

    @Test
    fun aFoldDownTheScreenLeavesTheHalfAfterIt() {
        val fold = Fold(Rect(314f, 0f, 354f, 951f))
        assertFalse(fold.runsAcross)
        assertEquals(Rect(354f, 0f, 669f, 951f), fold.room(screen))
    }

    @Test
    fun theStageIsTheSideAwayFromTheSheet() {
        assertEquals(Rect(0f, 0f, 669f, 455f), Fold(Rect(0f, 455f, 669f, 495f)).stage(screen))
        assertEquals(Rect(0f, 0f, 314f, 951f), Fold(Rect(314f, 0f, 354f, 951f)).stage(screen))
    }

    @Test
    fun aHairlineFoldStillSplitsTheScreen() {
        val book = Fold(Rect(420f, 0f, 420f, 701f))
        assertFalse(book.runsAcross)
        assertEquals(Rect(420f, 0f, 841f, 701f), book.room(Size(841f, 701f)))
        val tabletop = Fold(Rect(0f, 420f, 701f, 420f))
        assertTrue(tabletop.runsAcross)
        assertEquals(Rect(0f, 0f, 701f, 420f), tabletop.stage(Size(701f, 841f)))
    }
}
