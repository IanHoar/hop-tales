package com.hoptales.android.reading

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import com.hoptales.reading.Chord
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class ChordPlayer {
    private val track: AudioTrack? by lazy { runCatching(::build).getOrNull() }

    suspend fun play() = withContext(Dispatchers.Default) {
        val track = track ?: return@withContext
        synchronized(track) {
            runCatching {
                if (track.playState != AudioTrack.PLAYSTATE_STOPPED) track.stop()
                track.reloadStaticData()
                track.play()
            }
        }
    }

    private fun build(): AudioTrack {
        val samples = Chord.samples()
        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
                    .setSampleRate(Chord.SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
            )
            .setTransferMode(AudioTrack.MODE_STATIC)
            .setBufferSizeInBytes(samples.size * Float.SIZE_BYTES)
            .build()
        track.write(samples, 0, samples.size, AudioTrack.WRITE_BLOCKING)
        return track
    }
}
