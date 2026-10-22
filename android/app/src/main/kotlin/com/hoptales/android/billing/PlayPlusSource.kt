package com.hoptales.android.billing

import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.BillingClient.ProductType
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryPurchasesParams
import com.android.billingclient.api.acknowledgePurchase
import com.android.billingclient.api.queryPurchasesAsync
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class PlayPlusSource(context: Context, private val verifier: PurchaseVerifier, private val scope: CoroutineScope = MainScope()) :
    PlusSource {
    private val plus = MutableStateFlow(false)
    override val isPlus: StateFlow<Boolean> = plus.asStateFlow()

    private val client = BillingClient.newBuilder(context.applicationContext)
        .setListener { result, _ -> if (result.responseCode == BillingResponseCode.OK) refresh() }
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().enablePrepaidPlans().build())
        .build()

    private var connecting = false
    private var reconnect: Job? = null
    private var retryMillis = FIRST_RETRY_MILLIS

    override fun refresh() {
        if (client.isReady) scope.launch { query() } else connect()
    }

    private fun connect() {
        if (connecting) return
        connecting = true
        client.startConnection(
            object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    scope.launch {
                        connecting = false
                        if (result.responseCode == BillingResponseCode.OK) {
                            retryMillis = FIRST_RETRY_MILLIS
                            query()
                        }
                    }
                }

                override fun onBillingServiceDisconnected() {
                    scope.launch {
                        connecting = false
                        scheduleReconnect()
                    }
                }
            },
        )
    }

    private fun scheduleReconnect() {
        if (reconnect?.isActive == true) return
        val wait = retryMillis
        retryMillis = (retryMillis * 2).coerceAtMost(LAST_RETRY_MILLIS)
        reconnect = scope.launch {
            delay(wait)
            connect()
        }
    }

    private suspend fun query() {
        val params = QueryPurchasesParams.newBuilder().setProductType(ProductType.SUBS).build()
        val result = client.queryPurchasesAsync(params)
        if (result.billingResult.responseCode != BillingResponseCode.OK) return
        val purchases = result.purchasesList.map(::playPurchase)
        plus.value = PlayPurchase.isPlus(purchases, verifier)
        PlayPurchase.toAcknowledge(purchases, verifier).forEach { purchase ->
            client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.token).build())
        }
    }

    private fun playPurchase(purchase: Purchase) = PlayPurchase(
        products = purchase.products,
        state = when (purchase.purchaseState) {
            Purchase.PurchaseState.PURCHASED -> PlayPurchase.State.PURCHASED
            Purchase.PurchaseState.PENDING -> PlayPurchase.State.PENDING
            else -> PlayPurchase.State.UNSPECIFIED
        },
        isAcknowledged = purchase.isAcknowledged,
        isSuspended = purchase.isSuspended,
        token = purchase.purchaseToken,
        json = purchase.originalJson,
        signature = purchase.signature,
    )

    private companion object {
        const val FIRST_RETRY_MILLIS = 1_000L
        const val LAST_RETRY_MILLIS = 60_000L
    }
}
