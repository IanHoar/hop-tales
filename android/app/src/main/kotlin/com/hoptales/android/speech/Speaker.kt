package com.hoptales.android.speech

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import com.hoptales.speech.VoiceCandidate
import com.hoptales.speech.VoiceChoice
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import java.util.Locale
import java.util.UUID
import kotlin.coroutines.resume

data class VoiceOption(val id: String, val name: String, val region: String) {
    val label: String get() = "$name · $region"
}

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

    suspend fun voices(): List<VoiceOption> {
        if (!isReady()) return emptyList()
        return offlineVoices()
            .groupBy { it.locale.displayCountry.ifEmpty { it.locale.displayLanguage } }
            .toSortedMap()
            .flatMap { (region, voices) ->
                voices.sortedWith(compareByDescending<Voice> { it.quality }.thenBy { it.name })
                    .mapIndexed { index, voice -> VoiceOption(voice.name, "Voice ${index + 1}", region) }
            }
    }

    private fun offlineVoices(): List<Voice> = engine.voices.orEmpty().filter { voice ->
        voice.locale.language == "en" &&
            !voice.isNetworkConnectionRequired &&
            TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED !in voice.features.orEmpty() &&
            TextToSpeech.Engine.KEY_FEATURE_NETWORK_SYNTHESIS !in voice.features.orEmpty()
    }

    private fun bestVoice(voices: List<Voice>, locale: Locale): Voice? {
        val candidates = voices.map { VoiceCandidate(it.name, it.locale.toLanguageTag(), it.quality, it.latency) }
        val best = VoiceChoice.best(candidates, locale.toLanguageTag()) ?: return null
        return voices.firstOrNull { it.name == best.id }
    }

    suspend fun speak(word: String, locale: Locale = Locale.getDefault(), voiceID: String? = null) {
        if (!isReady()) return
        val voices = offlineVoices()
        val voice = voiceID?.let { id -> voices.firstOrNull { it.name == id } } ?: bestVoice(voices, locale)
        if (voice != null) engine.voice = voice else engine.language = locale
        engine.setSpeechRate(RATE)
        val id = UUID.randomUUID().toString()
        withTimeoutOrNull(fallbackMillis(word)) {
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

    private suspend fun isReady(): Boolean = withTimeoutOrNull(READY_TIMEOUT_MILLIS) { ready.await() } ?: false

    fun shutdown() = engine.shutdown()

    companion object {
        private const val RATE = 0.8f
        const val READY_TIMEOUT_MILLIS = 2_000L
        const val FALLBACK_BASE_MILLIS = 1_500L
        const val FALLBACK_PER_LETTER_MILLIS = 150L
        const val FALLBACK_MAX_MILLIS = 5_000L

        fun fallbackMillis(word: String): Long =
            (FALLBACK_BASE_MILLIS + FALLBACK_PER_LETTER_MILLIS * word.length).coerceAtMost(FALLBACK_MAX_MILLIS)
    }
}
