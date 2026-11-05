package com.hoptales.android.speech

import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import com.hoptales.reading.Heard
import java.io.File
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import kotlin.math.roundToInt

data class SpeechLogEntry(
    val story: String,
    val sentence: Int,
    val word: String,
    val heard: List<String>,
    val isFinal: Boolean,
    val outcome: Heard,
    val level: Float? = null,
    val time: Instant = Instant.now(),
)

class SpeechLog(private val recording: Boolean) {
    private val lines = ArrayDeque<SpeechLogEntry>()

    val entries: List<SpeechLogEntry> get() = synchronized(lines) { lines.toList() }

    fun record(entry: SpeechLogEntry) {
        if (!recording) return
        synchronized(lines) {
            lines.addLast(entry)
            while (lines.size > CAPACITY) lines.removeFirst()
        }
    }

    fun clear() = synchronized(lines) { lines.clear() }

    fun shareIntent(context: Context): Intent? {
        val entries = entries
        val folder = File(context.cacheDir, "speech-log").apply { mkdirs() }
        val file = File(folder, "hop-tales-speech-log.csv").apply { writeText(csv(entries)) }
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
        val send = Intent(Intent.ACTION_SEND)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_STREAM, uri)
            .putExtra(Intent.EXTRA_SUBJECT, "Hop Tales speech log")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return Intent.createChooser(send, "Export speech log")
    }

    companion object {
        const val CAPACITY = 5000
        private const val HEADER = "time,story,sentence,word,heard,kind,outcome,level"
        private val time = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC)

        fun csv(entries: List<SpeechLogEntry>): String {
            val rows = entries.map { entry ->
                listOf(
                    time.format(entry.time),
                    entry.story,
                    entry.sentence.toString(),
                    entry.word,
                    entry.heard.joinToString(" "),
                    if (entry.isFinal) "final" else "partial",
                    entry.outcome.label,
                    entry.level?.roundToInt()?.toString().orEmpty(),
                ).joinToString(",")
            }
            return (listOf(HEADER) + rows).joinToString("\n") + "\n"
        }
    }
}
