package com.hoptales.android.billing

import com.hoptales.android.BuildConfig
import com.hoptales.content.Story
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.KeyPairGenerator
import java.security.Signature
import java.util.Base64

class PlayPurchaseTest {
    private val trusting = PurchaseVerifier { _, _ -> true }

    private fun purchase(
        products: List<String> = listOf("hop_tales_plus"),
        state: PlayPurchase.State = PlayPurchase.State.PURCHASED,
        isAcknowledged: Boolean = true,
        isSuspended: Boolean = false,
        token: String = "token",
    ) = PlayPurchase(products, state, isAcknowledged, isSuspended, token, json = "{}", signature = "")

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
    fun everyStoryStaysOpenUntilTheStoresAreLive() {
        assertFalse(BuildConfig.PLUS_LOCKS_STORIES)
        val source = FakePlusSource(isPlus = false)
        val stories = (1..7).map { Story(id = "level-$it", title = "Level $it", sentences = emptyList(), level = it) }
        assertTrue(stories.none(source::isLocked))
    }
}
