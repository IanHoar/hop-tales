package com.hoptales.android.settings

import android.provider.Settings
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.billing.FakePlusSource
import com.hoptales.android.billing.PlusOffer
import com.hoptales.android.billing.PurchaseOutcome
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.content.PlusPlan
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
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
class PaywallTest {
    @get:Rule
    val compose = createComposeRule()

    private var closed = 0
    private var subscribed = 0

    @Before
    fun freezeMotion() {
        val app = RuntimeEnvironment.getApplication() as HopTalesApplication
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
    }

    private fun show(plus: FakePlusSource) {
        compose.setContent {
            HopTalesTheme {
                Paywall(
                    plus,
                    onClose = { closed += 1 },
                    onSubscribed = { subscribed += 1 },
                    live = false,
                )
            }
        }
    }

    @Test
    fun thePlansListYearlyFirstWithStorePrices() {
        show(FakePlusSource(offers = PlusOffer.SAMPLES.reversed()))
        compose.onNodeWithContentDescription("Yearly, $29.99 a year. Just $2.50 a month, the better value.").assertIsDisplayed()
        compose.onNodeWithContentDescription("Monthly, $4.99 a month. The flexible option.").assertIsDisplayed()
    }

    @Test
    fun thePitchListsWhatPlusUnlocks() {
        show(FakePlusSource())
        listOf("Unlock all reading levels", "More characters", "More settings", "More costumes").forEach {
            compose.onNodeWithText(it).assertIsDisplayed()
        }
        compose.onNodeWithText("For grown-ups").assertDoesNotExist()
    }

    @Test
    fun buyingFlipsTheEntitlement() {
        val plus = FakePlusSource(outcome = PurchaseOutcome.PURCHASED)
        show(plus)
        compose.onNodeWithContentDescription("Yearly", substring = true).performClick()
        compose.waitForIdle()
        assertEquals(PlusPlan.YEARLY, plus.bought.single().plan)
        assertTrue(plus.isPlus.value)
        assertEquals(1, subscribed)
        assertEquals(1, plus.refreshes)
    }

    @Test
    fun cancellingChangesNothing() {
        val plus = FakePlusSource(outcome = PurchaseOutcome.CANCELLED)
        show(plus)
        compose.onNodeWithContentDescription("Monthly", substring = true).performClick()
        compose.waitForIdle()
        assertFalse(plus.isPlus.value)
        assertEquals(0, subscribed)
        compose.onNodeWithText("Hop Tales Plus").assertIsDisplayed()
    }

    @Test
    fun aPendingPurchaseWaitsAndIsNotPlus() {
        val plus = FakePlusSource(outcome = PurchaseOutcome.PENDING)
        show(plus)
        compose.onNodeWithContentDescription("Yearly", substring = true).performClick()
        compose.onNodeWithText("Waiting for the store").assertIsDisplayed()
        assertFalse(plus.isPlus.value)
        assertEquals(0, subscribed)
        compose.onNodeWithText("Back to stories").performClick()
        assertEquals(1, closed)
    }

    @Test
    fun restoringRequeriesAndFindsPlus() {
        val plus = FakePlusSource(restores = true)
        show(plus)
        compose.onNodeWithText("Restore purchases").performScrollTo().performClick()
        compose.waitForIdle()
        assertEquals(1, plus.refreshes)
        assertEquals(1, subscribed)
    }

    @Test
    fun restoringWithNothingToRestoreSaysSo() {
        val plus = FakePlusSource(restores = false)
        show(plus)
        compose.onNodeWithText("Restore purchases").performScrollTo().performClick()
        compose.onNodeWithText("There's no Hop Tales Plus subscription to restore on this Google account.").assertExists()
        assertEquals(0, subscribed)
    }

    @Test
    fun offersThatFailToLoadShowTheMessage() {
        show(FakePlusSource(offers = null))
        compose.onNodeWithText("The store isn't answering").assertIsDisplayed()
        compose.onNodeWithText("Back to stories").performClick()
        assertEquals(1, closed)
    }

    @Test
    fun aSubscriberOpeningThePaywallIsNotSentAway() {
        show(FakePlusSource(isPlus = true))
        compose.waitForIdle()
        assertEquals(0, subscribed)
    }
}
