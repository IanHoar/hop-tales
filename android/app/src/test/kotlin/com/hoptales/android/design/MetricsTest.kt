package com.hoptales.android.design

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MetricsTest {
    @Test
    fun phonesUseThePhoneLayout() {
        for ((width, height) in listOf(375f to 667f, 390f to 844f, 440f to 956f, 412f to 915f)) {
            assertEquals(Metrics.PHONE, Metrics.forScreen(width, height, regular = false))
        }
    }

    @Test
    fun theFoldedDuoGetsItsOwnLayout() {
        assertEquals(Metrics.DUO, Metrics.forScreen(466f, 678f, regular = false))
    }

    @Test
    fun aRegularScreenUsesThePadLayout() {
        for ((width, height) in listOf(1032f to 1376f, 951f to 669f, 669f to 951f)) {
            assertEquals(Metrics.PAD, Metrics.forScreen(width, height, regular = true))
        }
    }

    @Test
    fun tabletsAndOpenFoldablesAreRegular() {
        for ((width, height) in listOf(800f to 1280f, 1280f to 800f, 841f to 701f, 701f to 841f, 600f to 480f)) {
            assertTrue("$width x $height", Metrics.isRegular(width, height))
            assertEquals(Metrics.PAD, Metrics.forScreen(width, height))
        }
    }

    @Test
    fun phonesAndOuterScreensAreNot() {
        for ((width, height) in listOf(412f to 915f, 411f to 797f, 915f to 412f, 599f to 900f, 900f to 479f)) {
            assertFalse("$width x $height", Metrics.isRegular(width, height))
        }
        assertEquals(Metrics.PHONE, Metrics.forScreen(411f, 797f))
    }

    @Test
    fun aSquatCompactWindowGetsTheDuoLayout() {
        assertEquals(Metrics.DUO, Metrics.forScreen(915f, 412f))
        assertEquals(Metrics.DUO, Metrics.forScreen(500f, 700f))
    }

    @Test
    fun anEmptyScreenFallsBackToThePhone() {
        assertEquals(Metrics.PHONE, Metrics.forScreen(0f, 0f))
    }
}
