package com.hoptales.android.speech

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import java.util.Locale
import java.util.UUID
import kotlin.coroutines.resume

class Speaker(context: Context) {
    private val ready = CompletableDeferred<Boolean>()
    private val pending = mutableMapOf<String, () -> Unit>()

    private val engine: TextToSpeech = TextToSpeech(context.applicationContext) { status ->
        ready.complete(status == TextToSpeech.SUCCESS)
    }

    init {
        engine.setOnUtteranceProgressListener(
            object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String) = Unit
                override fun onDone(utteranceId: String) = finish(utteranceId)

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String) = finish(utteranceId)
                override fun onError(utteranceId: String, errorCode: Int) = finish(utteranceId)
            },
        )
    }

    private fun finish(id: String) {
        synchronized(pending) { pending.remove(id) }?.invoke()
    }

    suspend fun speak(word: String, locale: Locale = Locale.getDefault()) {
        if (!ready.await()) return
        engine.language = locale
        engine.setSpeechRate(RATE)
        val id = UUID.randomUUID().toString()
        withTimeoutOrNull(TIMEOUT_MILLIS) {
            suspendCancellableCoroutine { continuation ->
                synchronized(pending) { pending[id] = { if (continuation.isActive) continuation.resume(Unit) } }
                continuation.invokeOnCancellation {
                    synchronized(pending) { pending.remove(id) }
                    engine.stop()
                }
                engine.speak(word, TextToSpeech.QUEUE_FLUSH, null, id)
            }
        }
    }

    fun shutdown() = engine.shutdown()

    private companion object {
        const val RATE = 0.8f
        const val TIMEOUT_MILLIS = 5_000L
    }
}
