package com.hoptales.android.billing

import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.hoptales.content.PlusPlan
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.X509EncodedKeySpec
import java.util.Base64

data class PlayPurchase(
    val products: List<String>,
    val state: State,
    val isAcknowledged: Boolean,
    val isSuspended: Boolean,
    val token: String,
    val json: String,
    val signature: String,
) {
    enum class State { PURCHASED, PENDING, UNSPECIFIED }

    val isPlusProduct: Boolean get() = PlusPlan.PLAY_PRODUCT_ID in products

    fun entitles(verifier: PurchaseVerifier): Boolean =
        isPlusProduct && state == State.PURCHASED && !isSuspended && verifier.verify(json, signature)

    fun needsAcknowledging(verifier: PurchaseVerifier): Boolean = !isAcknowledged && entitles(verifier)

    companion object {
        fun isPlus(purchases: List<PlayPurchase>, verifier: PurchaseVerifier): Boolean = purchases.any { it.entitles(verifier) }

        fun outcome(responseCode: Int, purchases: List<PlayPurchase>): PurchaseOutcome = when (responseCode) {
            BillingResponseCode.OK, BillingResponseCode.ITEM_ALREADY_OWNED -> {
                val plus = purchases.filter { it.isPlusProduct }
                when {
                    plus.any { it.state == State.PURCHASED } -> PurchaseOutcome.PURCHASED
                    plus.any { it.state == State.PENDING } -> PurchaseOutcome.PENDING
                    responseCode == BillingResponseCode.ITEM_ALREADY_OWNED -> PurchaseOutcome.PURCHASED
                    else -> PurchaseOutcome.FAILED
                }
            }

            BillingResponseCode.USER_CANCELED -> PurchaseOutcome.CANCELLED

            else -> PurchaseOutcome.FAILED
        }

        fun toAcknowledge(purchases: List<PlayPurchase>, verifier: PurchaseVerifier): List<PlayPurchase> =
            purchases.filter { it.needsAcknowledging(verifier) }
    }
}

fun interface PurchaseVerifier {
    fun verify(json: String, signature: String): Boolean
}

class PlayKeyVerifier(base64Key: String) : PurchaseVerifier {
    private val key = runCatching {
        KeyFactory.getInstance("RSA").generatePublic(X509EncodedKeySpec(Base64.getDecoder().decode(base64Key)))
    }.getOrNull()

    override fun verify(json: String, signature: String): Boolean {
        val key = key ?: return false
        return runCatching {
            Signature.getInstance(ALGORITHM).run {
                initVerify(key)
                update(json.toByteArray())
                verify(Base64.getDecoder().decode(signature))
            }
        }.getOrDefault(false)
    }

    private companion object {
        const val ALGORITHM = "SHA1withRSA"
    }
}
