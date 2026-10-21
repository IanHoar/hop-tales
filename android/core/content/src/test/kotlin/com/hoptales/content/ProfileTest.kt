package com.hoptales.content

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File

class ProfileTest {
    @Test
    fun theAccentFollowsTheDeviceRegion() {
        assertEquals(Profile.Accent.AMERICAN, Profile.Accent.of("US"))
        assertEquals(Profile.Accent.BRITISH, Profile.Accent.of("gb"))
        assertEquals(Profile.Accent.AUSTRALIAN, Profile.Accent.of("AU"))
        assertEquals(Profile.Accent.CANADIAN, Profile.Accent.of("CA"))
        assertEquals(Profile.Accent.CANADIAN, Profile.Accent.of("FR"))
        assertEquals(Profile.Accent.CANADIAN, Profile.Accent.of(null))
    }

    @Test
    fun theAccentNamesTheRecogniserLocale() {
        assertEquals(listOf("en-CA", "en-US", "en-GB", "en-AU"), Profile.Accent.entries.map { it.tag })
    }

    @Test
    fun aProfileRoundTripsThroughJson() {
        val profile = Profile("Maya", Friend.FROG, Profile.Accent.BRITISH, voiceID = "en-gb-x-rjs-local", soundButtons = true)
        val json = StoryLibrary.json.encodeToString(Profile.serializer(), profile)
        assertEquals(profile, StoryLibrary.json.decodeFromString(Profile.serializer(), json))
        assertEquals(true, json.contains("\"en-GB\""))
    }

    @Test
    fun anOlderProfileFillsInWhatItLacks() {
        val profile = StoryLibrary.json.decodeFromString(Profile.serializer(), """{"childName":"Maya"}""")
        assertEquals(Profile(childName = "Maya"), profile)
    }

    @Test
    fun theThemeKeepsTheIOSRawValuesAndFollowsTheDeviceUntilChosen() {
        assertEquals(listOf("device", "light", "dark"), Profile.Theme.entries.map { it.raw })
        assertEquals(listOf("Match device", "Light", "Dark"), Profile.Theme.entries.map { it.themeName })
        assertEquals(Profile.Theme.DEVICE, Profile().theme)
        assertEquals(Profile.Theme.DEVICE, Profile.Theme.of("sepia"))
        assertEquals(true, Profile.Theme.DEVICE.isDark(deviceIsDark = true))
        assertEquals(false, Profile.Theme.DEVICE.isDark(deviceIsDark = false))
        assertEquals(false, Profile.Theme.LIGHT.isDark(deviceIsDark = true))
        assertEquals(true, Profile.Theme.DARK.isDark(deviceIsDark = false))
        val json = StoryLibrary.json.encodeToString(Profile.serializer(), Profile(theme = Profile.Theme.DARK))
        assertEquals(true, json.contains("\"dark\""))
    }

    @Test
    fun aLongNameIsCutShort() {
        assertEquals(24, Profile.trimmedName("A".repeat(40)).length)
    }

    @Test
    fun everyFriendsStageMatchesThePhonicsTable() {
        val table = Json.parseToJsonElement(File(System.getProperty("hoptales.resources"), "phonics.json").readText())
        val phases = table.jsonObject.getValue("levels").jsonArray.associate {
            it.jsonObject.getValue("level").jsonPrimitive.int to it.jsonObject.getValue("phase").jsonPrimitive.content
        }
        for (friend in Friend.entries) assertEquals(phases[friend.level], friend.stage)
    }

    @Test
    fun theGreetingFollowsTheClockAndTheName() {
        assertEquals("Good morning, Maya!", greeting(9, "Maya"))
        assertEquals("Good afternoon, Maya!", greeting(12, "Maya"))
        assertEquals("Good evening, Maya!", greeting(17, "Maya"))
        assertEquals("Good evening, Maya!", greeting(3, "Maya"))
        assertEquals("Good morning!", greeting(4, null))
        assertEquals("Good morning!", greeting(4, " "))
    }
}
