package com.hoptales.speech

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ListeningTest {
    @Test fun aPartialThatHoldsForAQuarterSecondIsHeardAgain() {
        val settling = SettledPartial()
        settling.heard(listOf("sat"), now = 0)
        assertNull(settling.settled(now = 200))
        assertEquals(listOf("sat"), settling.settled(now = 250))
    }

    @Test fun aSettledPartialIsRepeatedOnlyOnce() {
        val settling = SettledPartial()
        settling.heard(listOf("sat"), now = 0)
        settling.settled(now = 300)
        settling.heard(listOf("sat"), now = 400)
        assertNull(settling.settled(now = 1_000))
    }

    @Test fun aChangingPartialRestartsTheWait() {
        val settling = SettledPartial()
        settling.heard(listOf("the"), now = 0)
        settling.heard(listOf("the", "cat"), now = 200)
        assertNull(settling.settled(now = 300))
        assertEquals(listOf("the", "cat"), settling.settled(now = 450))
    }

    @Test fun nothingHeardSettlesToNothing() = assertNull(SettledPartial().settled(now = 10_000))

    @Test fun aLoneWordAdvancesOnceItSettles() {
        val debouncer = PartialDebouncer()
        val settling = SettledPartial()
        settling.heard(listOf("sat"), now = 0)
        assertTrue(debouncer.confirm(listOf("sat"), isFinal = false).isEmpty())
        val repeated = settling.settled(now = SettledPartial.SETTLED_AFTER_MILLIS) ?: error("never settled")
        assertEquals(listOf("sat"), debouncer.confirm(repeated, isFinal = false))
    }

    @Test fun aFailureWaitsASecondAndAnEndingDoesNot() {
        assertEquals(1_000L, Relisten.after(ListenEnd.FAILED))
        assertEquals(150L, Relisten.after(ListenEnd.FINISHED))
        assertEquals(150L, Relisten.after(ListenEnd.INTERRUPTED))
    }

    @Test fun theAccentsOwnModelComesFirst() {
        assertEquals("en_gb", OnDeviceSupport.listeningTag("en-GB", listOf("en-US", "en_gb")))
        assertEquals("en-AU", OnDeviceSupport.listeningTag("en-AU", listOf("en-AU")))
    }

    @Test fun americanStandsInForAMissingAccent() =
        assertEquals("en-US", OnDeviceSupport.listeningTag("en-CA", listOf("fr-FR", "en-GB", "en-US")))

    @Test fun anyEnglishStandsInWhenAmericanIsMissingToo() {
        assertEquals("en-GB", OnDeviceSupport.listeningTag("en-CA", listOf("fr-FR", "en-IN", "en-GB")))
        assertEquals("en-AU", OnDeviceSupport.listeningTag("en-US", listOf("en-AU")))
    }

    @Test fun withNoEnglishModelThereIsNothingToListenWith() {
        assertNull(OnDeviceSupport.listeningTag("en-US", emptyList()))
        assertNull(OnDeviceSupport.listeningTag("en-CA", listOf("fr-FR", "de-DE")))
    }

    @Test fun theBestVoiceSpeaksTheAccentAtTheHighestQuality() {
        val voices = listOf(
            VoiceCandidate("us-low", "en-US", quality = 300, latency = 300),
            VoiceCandidate("gb-high", "en-GB", quality = 400, latency = 300),
            VoiceCandidate("gb-best", "en-GB", quality = 500, latency = 300),
            VoiceCandidate("fr-best", "fr-FR", quality = 500, latency = 100),
        )
        assertEquals("gb-best", VoiceChoice.best(voices, "en-GB")?.id)
        assertEquals("us-low", VoiceChoice.best(voices, "en-US")?.id)
    }

    @Test fun anotherEnglishVoiceStandsInWhenTheAccentHasNone() {
        val voices = listOf(
            VoiceCandidate("us-normal", "en-US", quality = 300, latency = 300),
            VoiceCandidate("au-high", "en-AU", quality = 400, latency = 300),
            VoiceCandidate("fr-best", "fr-FR", quality = 500, latency = 100),
        )
        assertEquals("au-high", VoiceChoice.best(voices, "en-CA")?.id)
        assertNull(VoiceChoice.best(voices.takeLast(1), "en-CA"))
    }

    @Test fun equalVoicesPreferTheQuickerOne() {
        val voices = listOf(
            VoiceCandidate("slow", "en-US", quality = 400, latency = 400),
            VoiceCandidate("quick", "en-US", quality = 400, latency = 200),
        )
        assertEquals("quick", VoiceChoice.best(voices, "en-US")?.id)
    }
}
