package com.hoptales.android

import android.app.Application
import com.hoptales.android.data.BackupChoice
import com.hoptales.android.data.HopTalesDatabase
import com.hoptales.android.data.ListeningPreferences
import com.hoptales.android.data.ProfileStore
import com.hoptales.android.data.ProgressStore
import com.hoptales.android.data.SoundPreference
import com.hoptales.android.reading.ChordPlayer
import com.hoptales.android.speech.ReadingAudio
import com.hoptales.android.speech.Speaker
import com.hoptales.android.speech.SpeechListener
import com.hoptales.content.Phonics
import com.hoptales.content.StoryLibrary
import com.hoptales.content.StoryProps
import com.hoptales.content.WardrobeLibrary

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
    val phonics: Phonics by lazy {
        Phonics.decode(assets.open("phonics.json").bufferedReader().use { it.readText() })
    }
    val database: HopTalesDatabase by lazy { HopTalesDatabase(this) }
    val progressStore: ProgressStore by lazy { ProgressStore(database, library) }
    val profileStore: ProfileStore by lazy { ProfileStore(database, filesDir) }
    val backupChoice: BackupChoice by lazy { BackupChoice(this) }
    val listeningPreferences: ListeningPreferences by lazy { ListeningPreferences(this) }
    val speaker: Speaker by lazy { Speaker(this) }
    val listener: SpeechListener by lazy { SpeechListener(this, readingAudio) }
    val readingAudio: ReadingAudio by lazy { ReadingAudio(this) }
    val chord: ChordPlayer by lazy { ChordPlayer() }
    val soundPreference: SoundPreference by lazy { SoundPreference(this) }
}
