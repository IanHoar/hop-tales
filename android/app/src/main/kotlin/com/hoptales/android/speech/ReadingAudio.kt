package com.hoptales.android.speech

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import com.hoptales.speech.Relisten
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

class ReadingAudio(context: Context) {
    private val audioManager = context.getSystemService(AudioManager::class.java)
    private val handler = Handler(Looper.getMainLooper())
    private val release = Runnable { deactivate() }
    private val mutableInterruptions = MutableSharedFlow<Unit>(extraBufferCapacity = 1, onBufferOverflow = BufferOverflow.DROP_OLDEST)
    private val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANT)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build(),
        )
        .setOnAudioFocusChangeListener(::focusChanged, handler)
        .build()

    var isActive = false
        private set

    val interruptions: SharedFlow<Unit> = mutableInterruptions.asSharedFlow()

    fun activate(): Boolean {
        handler.removeCallbacks(release)
        if (!isActive) {
            isActive = audioManager.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
        return isActive
    }

    fun releaseLater() {
        handler.removeCallbacks(release)
        handler.postDelayed(release, Relisten.RELEASE_AUDIO_AFTER_MILLIS)
    }

    fun deactivate() {
        handler.removeCallbacks(release)
        if (!isActive) return
        audioManager.abandonAudioFocusRequest(request)
        isActive = false
    }

    private fun focusChanged(change: Int) {
        when (change) {
            AudioManager.AUDIOFOCUS_LOSS, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                deactivate()
                mutableInterruptions.tryEmit(Unit)
            }
        }
    }
}
