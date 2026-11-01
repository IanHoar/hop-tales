package com.hoptales.android.speech

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SpeechModelTest {
    @Test
    fun anInstalledEnglishModelIsReady() {
        assertEquals(SpeechModel.READY, SpeechModel.of("en-CA", listOf("en-US"), emptyList(), listOf("en-US", "fr-FR")))
    }

    @Test
    fun aDownloadingEnglishModelIsDownloading() {
        assertEquals(SpeechModel.DOWNLOADING, SpeechModel.of("en-GB", emptyList(), listOf("en_GB"), listOf("en-GB")))
    }

    @Test
    fun aSupportedButMissingEnglishModelCanBeDownloaded() {
        val model = SpeechModel.of("en-CA", listOf("fr-FR"), emptyList(), listOf("en-US", "fr-FR"))
        assertEquals(SpeechModel.MISSING, model)
        assertTrue(model.canDownload)
    }

    @Test
    fun noEnglishAnywhereIsUnavailable() {
        val model = SpeechModel.of("en-US", listOf("fr-FR"), emptyList(), listOf("fr-FR"))
        assertEquals(SpeechModel.UNAVAILABLE, model)
        assertFalse(model.canDownload)
    }
}
