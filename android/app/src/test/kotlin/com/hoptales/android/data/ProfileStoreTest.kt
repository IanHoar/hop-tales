package com.hoptales.android.data

import com.hoptales.content.Friend
import com.hoptales.content.Profile
import com.hoptales.content.ProfileDraft
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class ProfileStoreTest {
    @get:Rule
    val folder = TemporaryFolder()

    private val maya = Profile("Maya", Friend.FROG, Profile.Accent.AMERICAN, soundButtons = true)

    @Test
    fun aFirstRunHasNoProfile() {
        val store = ProfileStore(folder.root)
        assertNull(store.load())
        assertNull(store.profile.value)
        assertNull(store.loadDraft())
    }

    @Test
    fun aSavedProfileIsThereNextLaunch() {
        ProfileStore(folder.root).save(maya)
        assertEquals(maya, ProfileStore(folder.root).load())
    }

    @Test
    fun aDraftIsKeptUntilTheProfileIsSaved() {
        val store = ProfileStore(folder.root)
        val draft = ProfileDraft(childName = "Maya", step = 2)
        store.saveDraft(draft)
        assertEquals(draft, ProfileStore(folder.root).loadDraft())
        store.save(maya)
        assertNull(store.loadDraft())
    }

    @Test
    fun erasingForgetsTheProfileAndTheDraft() {
        val store = ProfileStore(folder.root)
        store.save(maya)
        store.saveDraft(ProfileDraft(childName = "Maya", step = 1))
        store.erase()
        assertNull(store.profile.value)
        assertNull(ProfileStore(folder.root).load())
        assertNull(store.loadDraft())
    }

    @Test
    fun aDamagedFileReadsAsNoProfile() {
        folder.newFile("profile.json").writeText("{not json")
        assertNull(ProfileStore(folder.root).load())
    }
}
