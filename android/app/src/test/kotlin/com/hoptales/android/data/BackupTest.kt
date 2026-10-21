package com.hoptales.android.data

import com.hoptales.android.HopTalesApplication
import com.hoptales.android.onboarding.OnboardingViewModel
import com.hoptales.onboarding.OnboardingNext
import com.hoptales.onboarding.OnboardingStep
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.w3c.dom.Element
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class BackupTest {
    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication

    @After
    fun forget() = app.profileStore.saveDraft(null)

    @Test
    fun nothingLeavesTheDeviceUntilAGrownUpOptsIn() {
        assertFalse(app.backupChoice.isOn)
        assertFalse(app.backupChoice.wasEverOn)
        assertEquals(BackupPlan.NOTHING, BackupPlan.of(isDeviceTransfer = false, isOn = false, wasEverOn = false))
    }

    @Test
    fun optingInBacksUpTheReader() {
        assertEquals(BackupPlan.EVERYTHING, BackupPlan.of(isDeviceTransfer = false, isOn = true, wasEverOn = true))
    }

    @Test
    fun optingOutLeavesOnlyTheChoiceInTheNextBackup() {
        app.backupChoice.isOn = true
        app.backupChoice.isOn = false
        assertFalse(app.backupChoice.isOn)
        assertTrue(app.backupChoice.wasEverOn)
        assertEquals(BackupPlan.CHOICE_ONLY, BackupPlan.of(isDeviceTransfer = false, isOn = false, wasEverOn = true))
        assertTrue(app.backupChoice.file.exists())
        assertEquals("backup.xml", app.backupChoice.file.name)
    }

    @Test
    fun aNewPhoneSetUpFromTheOldOneStillGetsTheProgress() {
        assertEquals(BackupPlan.EVERYTHING, BackupPlan.of(isDeviceTransfer = true, isOn = false, wasEverOn = false))
    }

    @Test
    fun theRulesCarryOnlyTheDatabaseAndTheChoice() {
        val rules = DocumentBuilderFactory.newInstance().newDocumentBuilder()
            .parse(File("src/main/res/xml/data_extraction_rules.xml")).documentElement
        val expected = listOf("include database ${HopTalesDatabase.NAME}", "include sharedpref backup.xml")
        assertEquals(expected, entries(rules, "cloud-backup"))
        assertEquals(expected, entries(rules, "device-transfer"))
    }

    @Test
    fun choosingYesInOnboardingTurnsBackupOn() {
        val model = OnboardingViewModel(app, hasMicrophone = true)
        assertEquals(OnboardingStep.BACKUP, model.state.value.step)
        model.backupPicked(true)
        assertFalse(app.backupChoice.isOn)
        assertEquals(OnboardingNext.Advanced, model.primaryTapped())
        assertTrue(app.backupChoice.isOn)
    }

    @Test
    fun choosingNotNowLeavesBackupOff() {
        val model = OnboardingViewModel(app, hasMicrophone = true)
        model.backupPicked(false)
        model.primaryTapped()
        assertFalse(app.backupChoice.isOn)
        assertFalse(app.backupChoice.wasEverOn)
    }

    private fun entries(rules: Element, section: String): List<String> {
        val element = rules.getElementsByTagName(section).item(0) as Element
        val children = element.childNodes
        return (0 until children.length).mapNotNull { children.item(it) as? Element }.map {
            "${it.tagName} ${it.getAttribute("domain")} ${it.getAttribute("path")}"
        }
    }
}
