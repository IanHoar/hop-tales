package com.hoptales.android.design

import androidx.compose.ui.geometry.Rect
import androidx.window.layout.FoldingFeature
import androidx.window.testing.layout.FoldingFeature
import androidx.window.testing.layout.TestWindowLayoutInfo
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import android.graphics.Rect as WindowRect

@RunWith(RobolectricTestRunner::class)
class FoldLayoutTest {
    private val window = WindowRect(0, 0, 1682, 1402)

    private fun info(state: FoldingFeature.State, orientation: FoldingFeature.Orientation) =
        TestWindowLayoutInfo(listOf(FoldingFeature(window, size = 0, state = state, orientation = orientation)))

    @Test
    fun aHalfOpenedBookFoldRunsDownTheMiddle() {
        val fold = Fold.of(info(FoldingFeature.State.HALF_OPENED, FoldingFeature.Orientation.VERTICAL), density = 2f)
        assertEquals(Fold(Rect(420.5f, 0f, 420.5f, 701f)), fold)
    }

    @Test
    fun aHalfOpenedTabletopFoldRunsAcross() {
        val fold = Fold.of(info(FoldingFeature.State.HALF_OPENED, FoldingFeature.Orientation.HORIZONTAL), density = 2f)
        assertEquals(Fold(Rect(0f, 350.5f, 841f, 350.5f)), fold)
    }

    @Test
    fun aFlatScreenHasNoFold() {
        assertNull(Fold.of(info(FoldingFeature.State.FLAT, FoldingFeature.Orientation.VERTICAL), density = 2f))
        assertNull(Fold.of(TestWindowLayoutInfo(emptyList()), density = 2f))
    }
}
