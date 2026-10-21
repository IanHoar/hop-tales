package com.hoptales.android.speech

import android.media.AudioManager
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class ReadingAudioTest {
    private val context = RuntimeEnvironment.getApplication()
    private val audio = ReadingAudio(context)
    private val manager = context.getSystemService(AudioManager::class.java)

    @Test
    fun focusIsHeldForThreeSecondsBetweenSentences() {
        assertTrue(audio.activate())
        audio.releaseLater()
        ShadowLooper.idleMainLooper(2_900, TimeUnit.MILLISECONDS)
        assertTrue(audio.isActive)
        ShadowLooper.idleMainLooper(100, TimeUnit.MILLISECONDS)
        assertFalse(audio.isActive)
    }

    @Test
    fun listeningAgainKeepsTheFocus() {
        audio.activate()
        audio.releaseLater()
        ShadowLooper.idleMainLooper(2_000, TimeUnit.MILLISECONDS)
        audio.activate()
        ShadowLooper.idleMainLooper(5_000, TimeUnit.MILLISECONDS)
        assertTrue(audio.isActive)
    }

    @Test
    fun losingFocusInterruptsListening() = runBlocking {
        audio.activate()
        val interrupted = async(start = CoroutineStart.UNDISPATCHED) { audio.interruptions.first() }
        shadowOf(manager).lastAudioFocusRequest.listener.onAudioFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        withTimeout(1_000) { interrupted.await() }
        assertFalse(audio.isActive)
    }
}
