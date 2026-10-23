package com.hoptales.android.billing

import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.hoptales.android.BuildConfig
import com.hoptales.content.PlusPlan
import com.hoptales.content.PlusStatus
import com.hoptales.content.Story
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.KeyPairGenerator
import java.security.Signature
import java.util.Base64
import java.util.Locale

class PlayPurchaseTest {
    private val trusting = PurchaseVerifier { _, _ -> true }

    private fun purchase(
        products: List<String> = listOf("hop_tales_plus"),
        state: PlayPurchase.State = PlayPurchase.State.PURCHASED,
        isAcknowledged: Boolean = true,
        isSuspended: Boolean = false,
        token: String = "token",
        isAutoRenewing: Boolean = true,
    ) = PlayPurchase(products, state, isAcknowledged, isSuspended, token, json = "{}", signature = "", isAutoRenewing = isAutoRenewing)

    @Test
    fun aRenewingSubscriptionRenews() {
        assertEquals(PlusStatus.Renews(), PlayPurchase.status(listOf(purchase()), trusting))
    }

    @Test
    fun aCancelledSubscriptionEnds() {
        assertEquals(PlusStatus.Ends(), PlayPurchase.status(listOf(purchase(isAutoRenewing = false)), trusting))
    }

    @Test
    fun aPendingPurchaseIsWaiting() {
        assertEquals(PlusStatus.Pending, PlayPurchase.status(listOf(purchase(state = PlayPurchase.State.PENDING)), trusting))
    }

    @Test
    fun noPurchaseOrALapsedOneIsFree() {
        assertEquals(PlusStatus.Free, PlayPurchase.status(emptyList(), trusting))
        assertEquals(PlusStatus.Free, PlayPurchase.status(listOf(purchase(isSuspended = true)), trusting))
        assertEquals(PlusStatus.Free, PlayPurchase.status(listOf(purchase()), PurchaseVerifier { _, _ -> false }))
    }

    @Test
    fun aPurchasedPlusSubscriptionIsPlus() {
        assertTrue(PlayPurchase.isPlus(listOf(purchase()), trusting))
    }

    @Test
    fun noPurchasesIsNotPlus() {
        assertFalse(PlayPurchase.isPlus(emptyList(), trusting))
    }

    @Test
    fun aPendingPurchaseIsNotPlus() {
        assertFalse(PlayPurchase.isPlus(listOf(purchase(state = PlayPurchase.State.PENDING)), trusting))
    }

    @Test
    fun aSuspendedPurchaseIsNotPlus() {
        assertFalse(PlayPurchase.isPlus(listOf(purchase(isSuspended = true)), trusting))
    }

    @Test
    fun anotherProductIsNotPlus() {
        assertFalse(PlayPurchase.isPlus(listOf(purchase(products = listOf("tip"))), trusting))
    }

    @Test
    fun aPurchaseThatFailsVerificationIsNotPlus() {
        assertFalse(PlayPurchase.isPlus(listOf(purchase()), PurchaseVerifier { _, _ -> false }))
    }

    @Test
    fun onlyEntitlingPurchasesAreAcknowledged() {
        val purchases = listOf(
            purchase(isAcknowledged = false, token = "new"),
            purchase(isAcknowledged = true, token = "old"),
            purchase(isAcknowledged = false, state = PlayPurchase.State.PENDING, token = "pending"),
        )
        assertEquals(listOf("new"), PlayPurchase.toAcknowledge(purchases, trusting).map { it.token })
    }

    @Test
    fun thePlayKeyChecksTheSignature() {
        val keys = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
        val json = """{"productId":"hop_tales_plus","purchaseState":0}"""
        val signature = Signature.getInstance("SHA1withRSA").run {
            initSign(keys.private)
            update(json.toByteArray())
            Base64.getEncoder().encodeToString(sign())
        }
        val verifier = PlayKeyVerifier(Base64.getEncoder().encodeToString(keys.public.encoded))
        assertTrue(verifier.verify(json, signature))
        assertFalse(verifier.verify(json.replace("0", "1"), signature))
        assertFalse(verifier.verify(json, "not a signature"))
    }

    @Test
    fun withoutAPlayKeyNothingVerifies() {
        assertFalse(PlayKeyVerifier("").verify("{}", ""))
    }

    @Test
    fun onlyLevelOneIsOpenWithoutPlus() {
        assertTrue(BuildConfig.PLUS_LOCKS_STORIES)
        val stories = (1..7).map { Story(id = "level-$it", title = "Level $it", sentences = emptyList(), level = it) }
        val free = FakePlusSource(isPlus = false)
        assertEquals(stories.filter { it.level != 1 }, stories.filter(free::isLocked))
        val plus = FakePlusSource(isPlus = true)
        assertTrue(stories.none(plus::isLocked))
    }

    @Test
    fun aBoughtPlanIsPurchased() {
        assertEquals(PurchaseOutcome.PURCHASED, PlayPurchase.outcome(BillingResponseCode.OK, listOf(purchase())))
    }

    @Test
    fun aSlowPaymentIsPending() {
        val pending = purchase(state = PlayPurchase.State.PENDING)
        assertEquals(PurchaseOutcome.PENDING, PlayPurchase.outcome(BillingResponseCode.OK, listOf(pending)))
    }

    @Test
    fun backingOutIsCancelled() {
        assertEquals(PurchaseOutcome.CANCELLED, PlayPurchase.outcome(BillingResponseCode.USER_CANCELED, emptyList()))
    }

    @Test
    fun anAlreadyOwnedPlanCountsAsPurchased() {
        assertEquals(PurchaseOutcome.PURCHASED, PlayPurchase.outcome(BillingResponseCode.ITEM_ALREADY_OWNED, emptyList()))
    }

    @Test
    fun anythingElseFailsQuietly() {
        assertEquals(PurchaseOutcome.FAILED, PlayPurchase.outcome(BillingResponseCode.SERVICE_UNAVAILABLE, emptyList()))
        assertEquals(PurchaseOutcome.FAILED, PlayPurchase.outcome(BillingResponseCode.OK, listOf(purchase(products = listOf("other")))))
    }

    @Test
    fun theYearlyPlanShowsItsMonthlyPrice() {
        assertEquals("$2.50", PlusOffer.monthlyPrice(29_990_000, "USD", PlusPlan.YEARLY, Locale.US))
        assertEquals(null, PlusOffer.monthlyPrice(4_990_000, "USD", PlusPlan.MONTHLY, Locale.US))
    }

    @Test
    fun offersSortYearlyFirst() {
        assertEquals(PlusOffer.SAMPLES, PlusOffer.inPaywallOrder(PlusOffer.SAMPLES.reversed()))
    }
}
