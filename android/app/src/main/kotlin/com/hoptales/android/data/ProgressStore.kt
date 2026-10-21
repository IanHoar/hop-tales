package com.hoptales.android.data

import com.hoptales.content.Friend
import com.hoptales.content.Progress
import com.hoptales.content.StoryLibrary
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class ProgressStore(private val database: HopTalesDatabase, private val library: StoryLibrary) {
    private val state = MutableStateFlow(read())

    val progress: StateFlow<Progress> = state.asStateFlow()

    fun load(): Progress = state.value

    fun update(change: (Progress) -> Progress) = save(change(load()))

    fun startJourney(friend: Friend) {
        val progress = load()
        val journey = progress.journey.startedWith(friend)
        if (journey != progress.journey) save(progress.copy(journey = journey))
    }

    fun save(progress: Progress) {
        state.value = progress
        runCatching {
            database.writableDatabase.inTransaction { ProgressTable.write(this, progress, existing = ProgressTable.read(this)) }
        }
    }

    private fun read(): Progress = runCatching {
        ProgressTable.read(database.readableDatabase, library)
    }.getOrDefault(Progress())
}
