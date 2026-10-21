package com.hoptales.android.reading

import android.speech.tts.TextToSpeech
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.speech.Speaker
import com.hoptales.content.Friend
import com.hoptales.reading.ReadingState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper
import org.robolectric.shadows.ShadowTextToSpeech
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class SpokenHintTest {
    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication

    @Test
    fun theFallbackGrowsWithTheWordAndStopsAtFiveSeconds() {
        assertEquals(1_950L, Speaker.fallbackMillis("hop"))
        assertEquals(3_150L, Speaker.fallbackMillis("caterpillar"))
        assertEquals(5_000L, Speaker.fallbackMillis("a".repeat(40)))
    }

    @Test
    fun readingCarriesOnWhenTheVoiceNeverSaysItFinished() {
        val story = app.library.stories(Friend.HARE.level).first()
        val model = ReadingViewModel(story, app)
        app.speaker
        val engine = ShadowTextToSpeech.getLastTextToSpeechInstance()
        shadowOf(engine).onInitListener.onInit(TextToSpeech.SUCCESS)
        engine.setOnUtteranceProgressListener(null)
        val word = model.state.value.currentWord!!.text

        model.help()
        assertTrue(model.state.value.isSpeaking)

        val wait = Speaker.READY_TIMEOUT_MILLIS + Speaker.fallbackMillis(word) + ReadingState.SETTLE_AFTER_SPEAKING_MILLIS
        ShadowLooper.idleMainLooper(wait, TimeUnit.MILLISECONDS)
        assertFalse(model.state.value.isSpeaking)

        assertEquals(word, shadowOf(engine).lastSpokenText)
        model.skipWord()
        assertEquals(1, model.state.value.wordIndex)
    }
}
