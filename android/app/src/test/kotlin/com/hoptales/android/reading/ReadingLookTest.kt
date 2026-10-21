package com.hoptales.android.reading

import android.os.Looper
import com.hoptales.android.HopTalesApplication
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Progress
import com.hoptales.content.undressing
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class ReadingLookTest {
    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication

    @Test
    fun theOpenStoryWearsWhatTheWardrobeChanged() {
        app.progressStore.save(Progress(journey = Journey.starting(Friend.HARE)))
        val story = app.library.stories(Friend.HARE.level).first()
        val model = ReadingViewModel(story, app)
        assertEquals("scarf", model.look.value)

        app.progressStore.update { it.undressing(Friend.HARE) }
        shadowOf(Looper.getMainLooper()).idle()

        assertNull(model.look.value)
    }
}
