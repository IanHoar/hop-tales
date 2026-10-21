package com.hoptales.android

import android.app.Application
import com.hoptales.android.data.ListeningPreferences
import com.hoptales.android.data.ProfileStore
import com.hoptales.android.data.ProgressStore
import com.hoptales.android.data.SoundPreference
import com.hoptales.android.reading.ChordPlayer
import com.hoptales.android.speech.ReadingAudio
import com.hoptales.android.speech.Speaker
import com.hoptales.android.speech.SpeechListener
import com.hoptales.content.StoryLibrary
import com.hoptales.content.StoryProps
import com.hoptales.content.WardrobeLibrary
import java.io.File

class HopTalesApplication : Application() {
    val library: StoryLibrary by lazy {
        StoryLibrary.decode(assets.open("stories.json").bufferedReader().use { it.readText() })
    }
    val props: StoryProps by lazy {
        StoryProps.decode(assets.open("props.json").bufferedReader().use { it.readText() })
    }
    val wardrobe: WardrobeLibrary by lazy {
        WardrobeLibrary.decode(
            assets.open("wardrobe.json").bufferedReader().use { it.readText() },
            assets.open("looks.json").bufferedReader().use { it.readText() },
        )
    }
    val progressStore: ProgressStore by lazy { ProgressStore(File(filesDir, "progress.json"), library) }
    val profileStore: ProfileStore by lazy { ProfileStore(filesDir) }
    val listeningPreferences: ListeningPreferences by lazy { ListeningPreferences(this) }
    val speaker: Speaker by lazy { Speaker(this) }
    val listener: SpeechListener by lazy { SpeechListener(this) }
    val readingAudio: ReadingAudio by lazy { ReadingAudio(this) }
    val chord: ChordPlayer by lazy { ChordPlayer() }
    val soundPreference: SoundPreference by lazy { SoundPreference(this) }
}
