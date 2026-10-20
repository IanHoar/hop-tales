package com.hoptales.android

import android.app.Application
import com.hoptales.android.data.ProgressStore
import com.hoptales.android.speech.Speaker
import com.hoptales.android.speech.SpeechListener
import com.hoptales.content.StoryLibrary
import java.io.File

class HopTalesApplication : Application() {
    val library: StoryLibrary by lazy {
        StoryLibrary.decode(assets.open("stories.json").bufferedReader().use { it.readText() })
    }
    val progressStore: ProgressStore by lazy { ProgressStore(File(filesDir, "progress.json")) }
    val speaker: Speaker by lazy { Speaker(this) }
    val listener: SpeechListener by lazy { SpeechListener(this) }
}
