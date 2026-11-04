package com.hoptales.android.settings

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class LicencesTest {
    @Test fun theApacheLicenceShipsWithTheApp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val text = context.assets.open(Licences.APACHE).bufferedReader().use { it.readText() }
        assertTrue(text.contains("Apache License"))
        assertTrue(text.contains("Version 2.0, January 2004"))
    }

    @Test fun everyBundledSpeechComponentIsListed() {
        val names = Licences.all.map { it.name }
        listOf("Vosk speech recognition", "Vosk small English model", "Kaldi", "OpenFst", "Java Native Access").forEach {
            assertTrue(it, it in names)
        }
    }
}
