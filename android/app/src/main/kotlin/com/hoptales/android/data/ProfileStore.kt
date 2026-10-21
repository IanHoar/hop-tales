package com.hoptales.android.data

import com.hoptales.content.Profile
import com.hoptales.content.ProfileDraft
import com.hoptales.content.StoryLibrary
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.KSerializer
import java.io.File

class ProfileStore(private val directory: File) {
    private val file = File(directory, "profile.json")
    private val draftFile = File(directory, "profile-draft.json")
    private val state = MutableStateFlow(read(file, Profile.serializer()))

    val profile: StateFlow<Profile?> = state.asStateFlow()

    fun load(): Profile? = state.value

    fun save(profile: Profile) {
        state.value = profile
        write(file, Profile.serializer(), profile)
        draftFile.delete()
    }

    fun loadDraft(): ProfileDraft? = read(draftFile, ProfileDraft.serializer())

    fun saveDraft(draft: ProfileDraft?) {
        if (draft == null) draftFile.delete() else write(draftFile, ProfileDraft.serializer(), draft)
    }

    fun erase() {
        state.value = null
        file.delete()
        draftFile.delete()
    }

    private fun <T> read(from: File, serializer: KSerializer<T>): T? = runCatching {
        StoryLibrary.json.decodeFromString(serializer, from.readText())
    }.getOrNull()

    private fun <T> write(to: File, serializer: KSerializer<T>, value: T) {
        val scratch = File(to.parentFile, "${to.name}.tmp")
        scratch.writeText(StoryLibrary.json.encodeToString(serializer, value))
        scratch.renameTo(to)
    }
}
