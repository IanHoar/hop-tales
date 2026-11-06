package com.hoptales.android.settings

import android.provider.Settings
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsSelected
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
import com.hoptales.content.Friend
import com.hoptales.content.PlusPlan
import com.hoptales.content.PlusWelcome
import com.hoptales.content.Story
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
    private var finished = 0
    private val read = mutableListOf<Story>()
    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication

    @Before
    fun freezeMotion() {
        Settings.Global.putFloat(app.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
    }

    private fun show(plus: FakePlusSource, welcome: PlusWelcome? = null) {
        compose.setContent {
            HopTalesTheme {
                Paywall(
                    plus,
                    onClose = { closed += 1 },
                    onFinished = { finished += 1 },
                    welcome = welcome,
                    onRead = { read += it },
                    live = false,
                )
            }
        }
    }

    private fun subscribe() {
        compose.onNodeWithText("Subscribe").performScrollTo().performClick()
        compose.waitForIdle()
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
        listOf("Unlock all reading levels", "More characters", "More stories", "More costumes").forEach {
            compose.onNodeWithText(it).assertIsDisplayed()
        }
        compose.onNodeWithText("For grown-ups").assertDoesNotExist()
    }

    @Test
    fun yearlyStartsSelectedAndTappingAPlanOnlySelectsIt() {
        val plus = FakePlusSource()
        show(plus)
        compose.onNodeWithContentDescription("Yearly", substring = true).assertIsSelected()
        compose.onNodeWithContentDescription("Monthly", substring = true).performClick()
        compose.onNodeWithContentDescription("Monthly", substring = true).assertIsSelected()
        compose.onNodeWithContentDescription("Yearly", substring = true).assertIsNotSelected()
        assertTrue(plus.bought.isEmpty())
    }

    @Test
    fun subscribingBuysTheSelectedPlanAndWelcomes() {
        val plus = FakePlusSource(outcome = PurchaseOutcome.PURCHASED)
        show(plus)
        compose.onNodeWithContentDescription("Monthly", substring = true).performClick()
        subscribe()
        assertEquals(PlusPlan.MONTHLY, plus.bought.single().plan)
        assertTrue(plus.isPlus.value)
        assertEquals(1, plus.refreshes)
        compose.onNodeWithText("Welcome to Hop Tales Plus!").assertIsDisplayed()
        compose.onNodeWithText("Every story and every level is open now.").assertIsDisplayed()
        compose.onNodeWithText("Back to stories").performClick()
        assertEquals(1, finished)
        assertEquals(0, closed)
    }

    @Test
    fun theWelcomeOffersTheNextFriendsBigStory() {
        val big = app.library.bigStory(2)!!
        show(FakePlusSource(outcome = PurchaseOutcome.PURCHASED), PlusWelcome(big, Friend.HARE, meetsFriend = true))
        subscribe()
        compose.onNodeWithText("Skip has a big story waiting for you. Read it to reach Level 2.").assertIsDisplayed()
        compose.onNodeWithText("Meet Skip").performClick()
        assertEquals(listOf(big), read)
    }

    @Test
    fun cancellingChangesNothing() {
        val plus = FakePlusSource(outcome = PurchaseOutcome.CANCELLED)
        show(plus)
        subscribe()
        assertFalse(plus.isPlus.value)
        compose.onNodeWithText("Hop Tales Plus").assertIsDisplayed()
        compose.onNodeWithText("Subscribe").assertExists()
    }

    @Test
    fun aPendingPurchaseWaitsAndIsNotPlus() {
        val plus = FakePlusSource(outcome = PurchaseOutcome.PENDING)
        show(plus)
        subscribe()
        compose.onNodeWithText("Waiting for the store").assertIsDisplayed()
        assertFalse(plus.isPlus.value)
        compose.onNodeWithText("Back to stories").performClick()
        assertEquals(1, closed)
    }

    @Test
    fun subscribingShowsItIsWorkingUntilTheStoreAnswers() {
        val state = PaywallState(FakePlusSource())
        state.offers = PaywallOffers.Loaded(PlusOffer.SAMPLES)
        val bought = mutableListOf<PlusOffer>()
        state.subscribe { bought += it }
        assertEquals(PaywallWork.SUBSCRIBING, state.working)
        state.subscribe { bought += it }
        state.choose(PlusPlan.MONTHLY)
        assertEquals(1, bought.size)
        assertEquals(PlusPlan.YEARLY, state.selected)
        state.settle(PurchaseOutcome.CANCELLED)
        assertEquals(null, state.working)
    }

    @Test
    fun restoringRequeriesAndWelcomes() {
        val plus = FakePlusSource(restores = true)
        show(plus)
        compose.onNodeWithText("Restore purchases").performScrollTo().performClick()
        compose.waitForIdle()
        assertEquals(1, plus.refreshes)
        compose.onNodeWithText("Welcome to Hop Tales Plus!").assertIsDisplayed()
    }

    @Test
    fun restoringWithNothingToRestoreSaysSo() {
        val plus = FakePlusSource(restores = false)
        show(plus)
        compose.onNodeWithText("Restore purchases").performScrollTo().performClick()
        compose.onNodeWithText("There's no Hop Tales Plus subscription to restore on this Google account.").assertExists()
        compose.onNodeWithText("Welcome to Hop Tales Plus!").assertDoesNotExist()
    }

    @Test
    fun offersThatFailToLoadShowTheMessage() {
        show(FakePlusSource(offers = null))
        compose.onNodeWithText("The store isn't answering").assertIsDisplayed()
        compose.onNodeWithText("Back to stories").performClick()
        assertEquals(1, closed)
    }

    @Test
    fun aSubscriberOpeningThePaywallIsNotWelcomedAgain() {
        show(FakePlusSource(isPlus = true))
        compose.waitForIdle()
        compose.onNodeWithText("Welcome to Hop Tales Plus!").assertDoesNotExist()
    }
}
