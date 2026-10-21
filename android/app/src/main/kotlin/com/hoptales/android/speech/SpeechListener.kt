package com.hoptales.android.speech

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import com.hoptales.speech.WordMatcher
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import java.util.Locale

sealed interface SpeechEvent {
    data class Partial(val tokens: List<String>) : SpeechEvent
    data class Final(val tokens: List<String>) : SpeechEvent
    data class Level(val decibels: Float) : SpeechEvent
}

class SpeechListener(private val context: Context) {
    val isAvailable: Boolean
        get() = SpeechRecognizer.isOnDeviceRecognitionAvailable(context)

    fun listen(biasing: List<String>, locale: Locale = Locale.getDefault()): Flow<SpeechEvent> = callbackFlow {
        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
        recognizer.setRecognitionListener(
            object : RecognitionListener {
                override fun onPartialResults(partialResults: Bundle) {
                    tokens(partialResults)?.let { trySend(SpeechEvent.Partial(it)) }
                }

                override fun onResults(results: Bundle) {
                    tokens(results)?.let { trySend(SpeechEvent.Final(it)) }
                    close()
                }

                override fun onError(error: Int) {
                    close()
                }

                override fun onRmsChanged(rmsdB: Float) {
                    trySend(SpeechEvent.Level(rmsdB))
                }

                override fun onReadyForSpeech(params: Bundle?) = Unit
                override fun onBeginningOfSpeech() = Unit
                override fun onBufferReceived(buffer: ByteArray?) = Unit
                override fun onEndOfSpeech() = Unit
                override fun onEvent(eventType: Int, params: Bundle?) = Unit
            },
        )
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale.toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 4_000L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 4_000L)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                putExtra(RecognizerIntent.EXTRA_BIASING_STRINGS, ArrayList(biasing))
            }
        }
        recognizer.startListening(intent)
        awaitClose {
            recognizer.cancel()
            recognizer.destroy()
        }
    }

    private fun tokens(bundle: Bundle): List<String>? = bundle.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        ?.firstOrNull()
        ?.let(WordMatcher::normalize)
        ?.takeIf { it.isNotEmpty() }
}
