package com.hoptales.android.speech

import android.os.SystemClock
import android.util.Log
import com.hoptales.android.BuildConfig
import java.io.File

object SpeechTrace {
    private const val TAG = "HopSpeech"
    private var startedAt = 0L

    fun started(note: String) {
        startedAt = SystemClock.elapsedRealtime()
        log("start $note")
    }

    var folder: File? = null

    fun experiment(): Map<String, String> {
        if (!BuildConfig.DEBUG) return emptyMap()
        val file = folder?.let { File(it, "speech-exp") }?.takeIf { it.exists() } ?: return emptyMap()
        return file.readLines().mapNotNull { line ->
            line.split('=', limit = 2).takeIf { it.size == 2 }?.let { it[0].trim() to it[1].trim() }
        }.toMap()
    }

    fun log(message: String) {
        if (!BuildConfig.DEBUG) return
        Log.d(TAG, "+${SystemClock.elapsedRealtime() - startedAt}ms $message")
    }
}
