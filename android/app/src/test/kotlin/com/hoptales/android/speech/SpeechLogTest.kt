package com.hoptales.android.speech

import com.hoptales.reading.Heard
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.Instant

class SpeechLogTest {
    @Test
    fun theExportIsOneLinePerHearing() {
        val entries = listOf(
            SpeechLogEntry(
                "meadow-walk",
                2,
                "hop",
                listOf("hop", "hop"),
                isFinal = false,
                outcome = Heard.CURRENT,
                level = 41.6f,
                time = Instant.parse("2026-10-20T09:15:00Z"),
            ),
            SpeechLogEntry("meadow-walk", 2, "", emptyList(), isFinal = true, outcome = Heard.WAITING, time = Instant.EPOCH),
        )
        assertEquals(
            "time,story,sentence,word,heard,kind,outcome,level\n" +
                "2026-10-20T09:15:00.000Z,meadow-walk,2,hop,hop hop,partial,current,42\n" +
                "1970-01-01T00:00:00.000Z,meadow-walk,2,,,final,waiting,\n",
            SpeechLog.csv(entries),
        )
    }
}
