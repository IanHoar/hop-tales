package com.hoptales.android.data

import com.hoptales.content.Profile
import com.hoptales.content.ProfileDraft
import com.hoptales.content.StoryLibrary
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.File

class ProfileStore(private val database: HopTalesDatabase, directory: File) {
    private val draftFile = File(directory, DRAFT)
    private val state = MutableStateFlow(runCatching { ProfileTable.read(database.readableDatabase) }.getOrNull())

    val profile: StateFlow<Profile?> = state.asStateFlow()

    fun load(): Profile? = state.value

    fun save(profile: Profile) {
        state.value = profile
        runCatching { database.writableDatabase.inTransaction { ProfileTable.write(this, profile) } }
        draftFile.delete()
    }

    fun loadDraft(): ProfileDraft? = runCatching {
        StoryLibrary.json.decodeFromString(ProfileDraft.serializer(), draftFile.readText())
    }.getOrNull()

    fun saveDraft(draft: ProfileDraft?) {
        if (draft == null) {
            draftFile.delete()
            return
        }
        val scratch = File(draftFile.parentFile, "$DRAFT.tmp")
        scratch.writeText(StoryLibrary.json.encodeToString(ProfileDraft.serializer(), draft))
        scratch.renameTo(draftFile)
    }

    fun erase() {
        state.value = null
        runCatching { database.writableDatabase.inTransaction { ProfileTable.delete(this) } }
        draftFile.delete()
    }

    private companion object {
        const val DRAFT = "profile-draft.json"
    }
}
