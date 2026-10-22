package com.hoptales.android.settings

import android.provider.Settings
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.billing.FakePlusSource
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.content.PlusLinks
import com.hoptales.content.PlusStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w412dp-h915dp-xhdpi")
class PlusSettingsTest {
    @get:Rule
    val compose = createComposeRule()

    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication
    private var restores = 0
    private val links = mutableListOf<String>()

    @Before
    fun freezeMotion() {
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
    }

    private fun show(status: PlusStatus, plus: FakePlusSource = FakePlusSource(status = status)) {
        compose.setContent {
            HopTalesTheme {
                SettingsSheet(
                    SettingsState(plusStatus = status),
                    SettingsActions(),
                    plus,
                    onRestore = { restores += 1 },
                    openLink = { links += it },
                    gate = ParentGateState(seed = 1),
                )
            }
        }
    }

    private fun answerTheGate() {
        compose.onNodeWithText("What is five times three?").assertIsDisplayed()
        compose.onNodeWithContentDescription("1").performClick()
        compose.onNodeWithContentDescription("5").performClick()
        compose.onNodeWithContentDescription("Check answer").performClick()
    }

    @Test
    fun theStatusIsShownInPlainWords() {
        show(PlusStatus.Free)
        compose.onNodeWithText("Free: the Level 1 stories").assertIsDisplayed()
        compose.onNodeWithText(PlusStatus.RHYTHM).assertIsDisplayed()
    }

    @Test
    fun aPendingPurchaseIsWaiting() {
        show(PlusStatus.Pending)
        compose.onNodeWithText("Waiting for your payment to go through").assertIsDisplayed()
        compose.onNodeWithText("Subscribe").assertDoesNotExist()
        compose.onNodeWithText("Request a refund").assertDoesNotExist()
    }

    @Test
    fun subscribeGoesThroughTheGateToThePaywall() {
        show(PlusStatus.Free)
        compose.onNodeWithText("Subscribe").performClick()
        answerTheGate()
        compose.onNodeWithText("Hop Tales Plus").assertIsDisplayed()
        compose.onNodeWithContentDescription("Yearly", substring = true).assertIsDisplayed()
        compose.onNodeWithText("Close").performClick()
        compose.onNodeWithText("Free: the Level 1 stories").assertIsDisplayed()
    }

    @Test
    fun restoreGoesThroughTheGate() {
        show(PlusStatus.Free)
        compose.onNodeWithText("Restore purchases").performClick()
        assertEquals(0, restores)
        answerTheGate()
        assertEquals(1, restores)
        compose.onNodeWithText("Free: the Level 1 stories").assertIsDisplayed()
    }

    @Test
    fun manageGoesThroughTheGateToPlay() {
        show(PlusStatus.Renews())
        compose.onNodeWithText("Manage subscription").performClick()
        assertTrue(links.isEmpty())
        answerTheGate()
        assertEquals(listOf(PlusLinks.playSubscriptions(app.packageName)), links)
    }

    @Test
    fun aRefundGoesThroughTheGateToPlay() {
        show(PlusStatus.Ends())
        compose.onNodeWithText("Request a refund").performClick()
        assertTrue(links.isEmpty())
        answerTheGate()
        assertEquals(listOf(PlusLinks.PLAY_REFUNDS), links)
    }

    @Test
    fun leavingTheGateDoesNothing() {
        show(PlusStatus.Renews())
        compose.onNodeWithText("Manage subscription").performClick()
        compose.onNodeWithText("Close").performClick()
        compose.onNodeWithText("Plus, renews automatically").assertIsDisplayed()
        assertTrue(links.isEmpty())
    }
}
