package com.hoptales.android.speech

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.speech.ModelDownloadListener
import android.speech.RecognitionListener
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import com.hoptales.speech.ListenEnd
import com.hoptales.speech.NoiseMeter
import com.hoptales.speech.OnDeviceSupport
import com.hoptales.speech.SettledPartial
import com.hoptales.speech.WordMatcher
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import java.util.Locale
import kotlin.coroutines.resume

sealed interface SpeechEvent {
    data class Partial(val tokens: List<String>) : SpeechEvent
    data class Final(val tokens: List<String>) : SpeechEvent
    data class Level(val decibels: Float) : SpeechEvent
    data class Ended(val reason: ListenEnd) : SpeechEvent
}

class SpeechListener(private val context: Context, private val audio: ReadingAudio) {
    private val meter = NoiseMeter()

    val isAvailable: Boolean
        get() = SpeechRecognizer.isOnDeviceRecognitionAvailable(context)

    suspend fun listeningLocale(accent: Locale): Locale? {
        if (!isAvailable) return null
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return accent
        val installed = withTimeoutOrNull(SUPPORT_CHECK_TIMEOUT_MILLIS) { installedLanguages(accent) } ?: return accent
        return OnDeviceSupport.listeningTag(accent.toLanguageTag(), installed)?.let { Locale.forLanguageTag(it.replace('_', '-')) }
    }

    suspend fun model(accent: Locale): SpeechModel {
        if (!isAvailable) return SpeechModel.UNAVAILABLE
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return SpeechModel.READY
        val support = withTimeoutOrNull(SUPPORT_CHECK_TIMEOUT_MILLIS) { support(accent) } ?: return SpeechModel.READY
        return SpeechModel.of(
            accent.toLanguageTag(),
            support.installedOnDeviceLanguages,
            support.pendingOnDeviceLanguages,
            support.supportedOnDeviceLanguages,
        )
    }

    suspend fun downloadUntilReady(accent: Locale, progress: (Int) -> Unit = {}): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        val supported = withTimeoutOrNull(SUPPORT_CHECK_TIMEOUT_MILLIS) { support(accent) }?.supportedOnDeviceLanguages.orEmpty()
        val tag = OnDeviceSupport.listeningTag(accent.toLanguageTag(), supported) ?: OnDeviceSupport.FALLBACK_TAG
        val recognizer = runCatching { SpeechRecognizer.createOnDeviceSpeechRecognizer(context) }.getOrNull() ?: return false
        val download = intent(emptyList(), Locale.forLanguageTag(tag.replace('_', '-')))
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                runCatching {
                    recognizer.triggerModelDownload(
                        download,
                        context.mainExecutor,
                        object : ModelDownloadListener {
                            override fun onProgress(completedPercent: Int) = progress(completedPercent)
                            override fun onSuccess() = progress(DONE_PERCENT)
                            override fun onScheduled() = Unit
                            override fun onError(error: Int) = Unit
                        },
                    )
                }
            } else {
                runCatching { recognizer.triggerModelDownload(download) }
            }
            return withTimeoutOrNull(DOWNLOAD_WAIT_MILLIS) {
                while (model(accent) != SpeechModel.READY) delay(DOWNLOAD_POLL_MILLIS)
                true
            } ?: false
        } finally {
            recognizer.destroy()
        }
    }

    private suspend fun installedLanguages(locale: Locale): List<String>? = support(locale)?.installedOnDeviceLanguages

    private suspend fun support(locale: Locale): RecognitionSupport? = suspendCancellableCoroutine { continuation ->
        val recognizer = runCatching { SpeechRecognizer.createOnDeviceSpeechRecognizer(context) }.getOrNull()
        if (recognizer == null) {
            continuation.resume(null)
            return@suspendCancellableCoroutine
        }
        fun answer(support: RecognitionSupport?) {
            recognizer.destroy()
            if (continuation.isActive) continuation.resume(support)
        }
        continuation.invokeOnCancellation { recognizer.destroy() }
        recognizer.checkRecognitionSupport(
            intent(emptyList(), locale),
            context.mainExecutor,
            object : RecognitionSupportCallback {
                override fun onSupportResult(support: RecognitionSupport) = answer(support)

                override fun onError(error: Int) = answer(null)
            },
        )
    }

    fun listen(biasing: List<String>, locale: Locale = Locale.getDefault()): Flow<SpeechEvent> = callbackFlow {
        fun end(reason: ListenEnd) {
            trySend(SpeechEvent.Ended(reason))
            close()
        }

        val recognizer = if (audio.activate()) {
            runCatching {
                SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
            }.getOrNull()
        } else {
            null
        }
        if (recognizer == null) {
            end(ListenEnd.FAILED)
            awaitClose { audio.releaseLater() }
            return@callbackFlow
        }

        val settling = SettledPartial()
        recognizer.setRecognitionListener(
            object : RecognitionListener {
                override fun onPartialResults(partialResults: Bundle) {
                    val heard = tokens(partialResults) ?: return
                    settling.heard(heard, SystemClock.elapsedRealtime())
                    trySend(SpeechEvent.Partial(heard))
                }

                override fun onResults(results: Bundle) {
                    tokens(results)?.let { trySend(SpeechEvent.Final(it)) }
                    end(ListenEnd.FINISHED)
                }

                override fun onError(error: Int) {
                    end(if (error in QUIET_ENDINGS) ListenEnd.FINISHED else ListenEnd.FAILED)
                }

                override fun onRmsChanged(rmsdB: Float) {
                    meter.add(rmsdB, SystemClock.elapsedRealtime())
                }

                override fun onReadyForSpeech(params: Bundle?) = Unit
                override fun onBeginningOfSpeech() = Unit
                override fun onBufferReceived(buffer: ByteArray?) = Unit
                override fun onEndOfSpeech() = Unit
                override fun onEvent(eventType: Int, params: Bundle?) = Unit
            },
        )
        launch {
            while (true) {
                delay(SettledPartial.STABILITY_TICK_MILLIS)
                settling.settled(SystemClock.elapsedRealtime())?.let { send(SpeechEvent.Partial(it)) }
            }
        }
        launch {
            while (true) {
                delay(NoiseMeter.SAMPLE_MILLIS)
                send(SpeechEvent.Level(meter.floor.toFloat()))
            }
        }
        launch {
            audio.interruptions.first()
            end(ListenEnd.INTERRUPTED)
        }
        recognizer.startListening(intent(biasing, locale))
        awaitClose {
            recognizer.cancel()
            recognizer.destroy()
            audio.releaseLater()
        }
    }

    private fun intent(biasing: List<String>, locale: Locale) = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale.toLanguageTag())
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 4_000L)
        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 4_000L)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && biasing.isNotEmpty()) {
            putExtra(RecognizerIntent.EXTRA_BIASING_STRINGS, ArrayList(biasing))
        }
    }

    private fun tokens(bundle: Bundle): List<String>? = bundle.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        ?.firstOrNull()
        ?.let(WordMatcher::normalize)
        ?.takeIf { it.isNotEmpty() }

    private companion object {
        const val SUPPORT_CHECK_TIMEOUT_MILLIS = 2_000L
        const val DOWNLOAD_POLL_MILLIS = 2_000L
        const val DOWNLOAD_WAIT_MILLIS = 10 * 60_000L
        const val DONE_PERCENT = 100
        val QUIET_ENDINGS = setOf(SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT)
    }
}
