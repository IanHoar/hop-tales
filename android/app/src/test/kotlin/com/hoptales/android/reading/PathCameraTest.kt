package com.hoptales.android.reading

import com.hoptales.reading.HopTarget
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PathCameraTest {
    @Test
    fun theCameraPansOnlyForwardAlongThePath() {
        assertTrue(PathCamera.pans(HopTarget(0, 2), HopTarget(0, 3)))
        assertTrue(PathCamera.pans(HopTarget(0, 5), HopTarget(1, 0)))
    }

    @Test
    fun readingAgainSnapsBackToTheStart() {
        assertFalse(PathCamera.pans(HopTarget(4, 0), HopTarget(0, 0)))
        assertFalse(PathCamera.pans(HopTarget(0, 3), HopTarget(0, 3)))
    }
}
