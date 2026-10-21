package com.hoptales.android.settings

import com.hoptales.android.HopTalesApplication
import com.hoptales.android.speech.SpeechLogEntry
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Profile
import com.hoptales.content.Progress
import com.hoptales.content.greeting
import com.hoptales.reading.Heard
import com.hoptales.speech.Strictness
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class SettingsViewModelTest {
    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication
    private val maya = Profile("Maya", Friend.HARE)

    @Before
    fun saveAProfile() = app.profileStore.save(maya)

    @After
    fun forget() = app.profileStore.erase()

    @Test
    fun everySettingIsSavedAsItChanges() {
        val model = SettingsViewModel(app)
        model.accentPicked(Profile.Accent.BRITISH)
        model.soundButtonsToggled(true)
        model.strictnessPicked(Strictness.STANDARD)
        model.soundToggled(false)

        assertEquals(maya.copy(accent = Profile.Accent.BRITISH, soundButtons = true), app.profileStore.load())
        assertEquals(Strictness.STANDARD, app.listeningPreferences.strictness)
        assertFalse(app.soundPreference.isOn)
        assertEquals(Strictness.STANDARD, SettingsViewModel(app).state.value.strictness)
    }

    @Test
    fun theThemeIsSavedOnTheProfileAsItIsPicked() {
        val model = SettingsViewModel(app)
        assertEquals(Profile.Theme.DEVICE, model.state.value.profile.theme)
        model.themePicked(Profile.Theme.DARK)
        assertEquals(Profile.Theme.DARK, app.profileStore.load()?.theme)
        assertEquals(Profile.Theme.DARK, app.profileStore.profile.value?.theme)
        model.themePicked(Profile.Theme.LIGHT)
        assertEquals(Profile.Theme.LIGHT, SettingsViewModel(app).state.value.profile.theme)
    }

    @Test
    fun theSpeechLogKeepsWhatIsHeardOnlyWhileItIsOn() {
        val model = SettingsViewModel(app)
        val heard = SpeechLogEntry("meadow-walk", 0, "The", listOf("the"), isFinal = true, outcome = Heard.CURRENT)
        app.speechLog.record(heard)
        assertEquals(0, model.state.value.speechLogLines)
        model.speechLogToggled(true)
        app.speechLog.record(heard)
        app.speechLog.record(heard)
        assertTrue(SettingsViewModel(app).state.value.speechLogOn)
        assertEquals(2, SettingsViewModel(app).state.value.speechLogLines)
        model.speechLogCleared()
        assertEquals(0, model.state.value.speechLogLines)
        model.speechLogToggled(false)
        assertFalse(model.state.value.speechLogOn)
    }

    @Test
    fun unlockingEverythingMeetsEveryFriendAndFillsTheirBaskets() {
        val model = SettingsViewModel(app)
        model.unlockEverything()
        val progress = app.progressStore.load()
        assertEquals(Friend.entries.toSet(), progress.journey.met)
        assertEquals(Friend.entries.toSet(), model.state.value.readingFriends.toSet())
        for (friend in Friend.entries) assertEquals(app.wardrobe.items(friend).size, progress.baskets[friend]?.filled)

        model.resetJourney()
        val reset = app.progressStore.load()
        assertEquals(Journey.starting(maya.startingFriend), reset.journey)
        assertTrue(reset.baskets.isEmpty())
        assertEquals(reset.journey, model.state.value.journey)
        app.progressStore.save(Progress())
    }

    @Test
    fun theNameIsSavedWhenTheGrownUpIsDone() {
        val model = SettingsViewModel(app)
        model.nameChanged("  Mia ")
        assertEquals("Maya", app.profileStore.load()?.childName)
        model.done()
        assertEquals("Mia", app.profileStore.load()?.childName)
    }

    @Test
    fun anEmptyNameClearsTheName() {
        val model = SettingsViewModel(app)
        model.nameChanged("   ")
        model.done()
        assertEquals("", app.profileStore.load()?.childName)
        assertEquals("Good morning!", greeting(9, app.profileStore.load()?.childName))
    }

    @Test
    fun aLongNameIsCutShort() {
        val model = SettingsViewModel(app)
        model.nameChanged("A".repeat(40))
        assertEquals(24, model.state.value.childName.length)
    }

    @Test
    fun backupIsOffUntilTheGrownUpTurnsItOn() {
        val model = SettingsViewModel(app)
        assertFalse(model.state.value.backupOn)
        model.backupToggled(true)
        assertTrue(app.backupChoice.isOn)
        assertTrue(SettingsViewModel(app).state.value.backupOn)
        model.backupToggled(false)
        assertFalse(app.backupChoice.isOn)
        assertTrue(model.state.value.backupWasOn)
    }

    @Test
    fun resettingOnboardingForgetsTheProfile() {
        SettingsViewModel(app).resetOnboarding()
        assertNull(app.profileStore.profile.value)
    }
}
