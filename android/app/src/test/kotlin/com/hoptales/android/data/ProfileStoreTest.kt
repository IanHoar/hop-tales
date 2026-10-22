package com.hoptales.android.data

import com.hoptales.content.Friend
import com.hoptales.content.Profile
import com.hoptales.content.ProfileDraft
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class ProfileStoreTest {
    @get:Rule
    val folder = TemporaryFolder()

    private val maya = Profile("Maya", Friend.FROG, Profile.Accent.AMERICAN, voiceID = "v1", soundButtons = true)
    private val database by lazy {
        HopTalesDatabase(RuntimeEnvironment.getApplication(), File(folder.root, "hoptales.db").path, legacy = null)
    }

    private fun store() = ProfileStore(database, folder.root)

    @Test
    fun aFirstRunHasNoProfile() {
        val store = store()
        assertNull(store.load())
        assertNull(store.profile.value)
        assertNull(store.loadDraft())
    }

    @Test
    fun aSavedProfileIsThereNextLaunch() {
        store().save(maya)
        assertEquals(maya, store().load())
    }

    @Test
    fun theOnboardingOfferIsRememberedWithTheProfile() {
        store().save(maya)
        assertEquals(false, store().load()?.plusOffered)
        store().save(maya.copy(plusOffered = true))
        assertEquals(true, store().load()?.plusOffered)
    }

    @Test
    fun aDraftIsKeptUntilTheProfileIsSaved() {
        val store = store()
        val draft = ProfileDraft(childName = "Maya", backup = true, step = 2)
        store.saveDraft(draft)
        assertEquals(draft, store().loadDraft())
        store.save(maya)
        assertNull(store.loadDraft())
    }

    @Test
    fun erasingForgetsTheProfileAndTheDraft() {
        val store = store()
        store.save(maya)
        store.saveDraft(ProfileDraft(childName = "Maya", step = 1))
        store.erase()
        assertNull(store.profile.value)
        assertNull(store().load())
        assertNull(store.loadDraft())
    }

    @Test
    fun aDamagedDraftReadsAsNoDraft() {
        folder.newFile("profile-draft.json").writeText("{not json")
        assertNull(store().loadDraft())
    }
}
