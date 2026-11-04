package com.hoptales.android.speech

import android.os.SystemClock
import android.util.Log
import com.hoptales.android.BuildConfig

object SpeechTrace {
    private const val TAG = "HopSpeech"
    private var startedAt = 0L

    fun started(note: String) {
        startedAt = SystemClock.elapsedRealtime()
        log("start $note")
    }

    fun log(message: String) {
        if (!BuildConfig.DEBUG) return
        Log.d(TAG, "+${SystemClock.elapsedRealtime() - startedAt}ms $message")
    }
}
