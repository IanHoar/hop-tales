package com.hoptales.android.speech

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import com.hoptales.speech.ListenEnd
import com.hoptales.speech.WordMatcher
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.json.JSONArray
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import java.io.File
import kotlin.math.sqrt

class VoskListener(private val context: Context, private val audio: ReadingAudio) {
    private val loaded = CompletableDeferred<Model?>()

    fun prepare(scope: CoroutineScope) {
        if (loaded.isCompleted) return
        scope.launch(Dispatchers.IO) {
            val model = runCatching { Model(unpacked().absolutePath) }
                .onFailure { SpeechTrace.log("vosk model failed $it") }
                .getOrNull()
            SpeechTrace.log("vosk model ${if (model != null) "loaded" else "unavailable"}")
            loaded.complete(model)
        }
    }

    suspend fun isReady(): Boolean = loaded.await() != null

    private fun unpacked(): File {
        val target = File(context.noBackupFilesDir, MODEL)
        val version = context.assets.open("$MODEL/$VERSION").bufferedReader().use { it.readText() }
        val marker = File(target, VERSION)
        if (marker.exists() && marker.readText() == version) return target
        target.deleteRecursively()
        copy(MODEL, target)
        marker.writeText(version)
        return target
    }

    private fun copy(path: String, into: File) {
        val children = context.assets.list(path).orEmpty()
        if (children.isEmpty()) {
            into.parentFile?.mkdirs()
            context.assets.open(path).use { input -> into.outputStream().use { input.copyTo(it) } }
            return
        }
        children.filterNot { path == MODEL && it == VERSION }.forEach { copy("$path/$it", File(into, it)) }
    }

    @SuppressLint("MissingPermission")
    fun listen(words: List<String>, decoys: List<String> = emptyList()): Flow<SpeechEvent> = callbackFlow {
        val model = loaded.await()
        if (model == null || !audio.activate()) {
            trySend(SpeechEvent.Ended(ListenEnd.FAILED))
            close()
            awaitClose { audio.releaseLater() }
            return@callbackFlow
        }
        val grammar = Grammar.of(words.flatMap(WordMatcher::normalize), decoys.flatMap(WordMatcher::normalize))
        val recognizer = Recognizer(model, SAMPLE_RATE.toFloat(), JSONArray(grammar + UNKNOWN).toString())
        val stream = WordStream()
        SpeechTrace.started("vosk listen words=$words grammar=${grammar.size}")
        val reader = launch(Dispatchers.IO) {
            val record = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT), CHUNK * 4),
            )
            val buffer = ShortArray(CHUNK)
            var loudest = 0
            var chunks = 0
            try {
                record.startRecording()
                while (isActive) {
                    val count = record.read(buffer, 0, buffer.size)
                    if (count <= 0) continue
                    loudest = maxOf(loudest, rms(buffer, count))
                    if (++chunks % LEVEL_CHUNKS == 0) {
                        SpeechTrace.log("vosk level $loudest")
                        loudest = 0
                    }
                    val words = if (recognizer.acceptWaveForm(buffer, count)) {
                        val text = JSONObject(recognizer.result).optString("text")
                        SpeechTrace.log("vosk result '$text'")
                        stream.result(tokens(text))
                    } else {
                        val text = JSONObject(recognizer.partialResult).optString("partial")
                        if (text.isNotBlank()) SpeechTrace.log("vosk partial '$text'")
                        stream.partial(tokens(text))
                    }
                    if (words.isNotEmpty()) trySend(SpeechEvent.Final(words))
                }
            } catch (error: IllegalStateException) {
                SpeechTrace.log("vosk error $error")
                trySend(SpeechEvent.Ended(ListenEnd.FAILED))
                close()
            } finally {
                record.stop()
                record.release()
            }
        }
        awaitClose {
            SpeechTrace.log("vosk closed")
            reader.cancel()
            runBlocking { reader.join() }
            recognizer.close()
            audio.releaseLater()
        }
    }

    private fun rms(buffer: ShortArray, count: Int): Int {
        var energy = 0.0
        for (index in 0 until count) energy += buffer[index].toDouble() * buffer[index]
        return sqrt(energy / count).toInt()
    }

    private fun tokens(text: String): List<String> = WordMatcher.normalize(text).filter { it != "unk" }

    private companion object {
        const val MODEL = "vosk-model"
        const val VERSION = "version"
        const val SAMPLE_RATE = 16_000
        const val CHUNK = 1_600
        const val LEVEL_CHUNKS = 5
        const val UNKNOWN = "[unk]"
    }
}
