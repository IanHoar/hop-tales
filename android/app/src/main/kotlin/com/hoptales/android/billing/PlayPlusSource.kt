package com.hoptales.android.billing

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.BillingClient.ProductType
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.android.billingclient.api.acknowledgePurchase
import com.android.billingclient.api.queryProductDetails
import com.android.billingclient.api.queryPurchasesAsync
import com.hoptales.content.PlusPlan
import com.hoptales.content.PlusStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull

class PlayPlusSource(context: Context, private val verifier: PurchaseVerifier, private val scope: CoroutineScope = MainScope()) :
    PlusSource {
    private val plus = MutableStateFlow(false)
    override val isPlus: StateFlow<Boolean> = plus.asStateFlow()

    private val plusStatus = MutableStateFlow<PlusStatus>(PlusStatus.Free)
    override val status: StateFlow<PlusStatus> = plusStatus.asStateFlow()

    private val outcomeFlow = MutableSharedFlow<PurchaseOutcome>(extraBufferCapacity = 4)
    override val outcomes: SharedFlow<PurchaseOutcome> = outcomeFlow.asSharedFlow()

    private val ready = MutableStateFlow(false)
    private var details: ProductDetails? = null

    private val client = BillingClient.newBuilder(context.applicationContext)
        .setListener { result, purchases ->
            val outcome = PlayPurchase.outcome(result.responseCode, purchases.orEmpty().map(::playPurchase))
            scope.launch { outcomeFlow.emit(outcome) }
            if (outcome == PurchaseOutcome.PURCHASED || outcome == PurchaseOutcome.PENDING) refresh()
        }
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().enablePrepaidPlans().build())
        .build()

    private var connecting = false
    private var reconnect: Job? = null
    private var retryMillis = FIRST_RETRY_MILLIS

    override fun refresh() {
        if (client.isReady) scope.launch { query() } else connect()
    }

    override suspend fun offers(): List<PlusOffer> {
        if (!client.isReady) {
            connect()
            withTimeoutOrNull(CONNECT_WAIT_MILLIS) { ready.first { it } } ?: return emptyList()
        }
        val product = QueryProductDetailsParams.Product.newBuilder()
            .setProductId(PlusPlan.PLAY_PRODUCT_ID)
            .setProductType(ProductType.SUBS)
            .build()
        val result = runCatching {
            client.queryProductDetails(QueryProductDetailsParams.newBuilder().setProductList(listOf(product)).build())
        }.getOrNull() ?: return emptyList()
        if (result.billingResult.responseCode != BillingResponseCode.OK) return emptyList()
        val found = result.productDetailsList.orEmpty().firstOrNull { it.productId == PlusPlan.PLAY_PRODUCT_ID } ?: return emptyList()
        details = found
        return PlusOffer.inPaywallOrder(found.subscriptionOfferDetails.orEmpty().mapNotNull(::offer))
    }

    override fun buy(activity: Activity?, offer: PlusOffer) {
        val product = details
        if (activity == null || product == null || !client.isReady) {
            outcomeFlow.tryEmit(PurchaseOutcome.FAILED)
            return
        }
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(product)
                        .setOfferToken(offer.offerToken)
                        .build(),
                ),
            ).build()
        val result = client.launchBillingFlow(activity, params)
        if (result.responseCode != BillingResponseCode.OK) {
            outcomeFlow.tryEmit(PlayPurchase.outcome(result.responseCode, emptyList()))
        }
    }

    override suspend fun restore(): Boolean {
        if (!client.isReady) {
            connect()
            withTimeoutOrNull(CONNECT_WAIT_MILLIS) { ready.first { it } } ?: return plus.value
        }
        query()
        return plus.value
    }

    private fun offer(details: ProductDetails.SubscriptionOfferDetails): PlusOffer? {
        if (details.offerId != null) return null
        val plan = PlusPlan.fromPlay(PlusPlan.PLAY_PRODUCT_ID, details.basePlanId) ?: return null
        val phase = details.pricingPhases.pricingPhaseList.lastOrNull() ?: return null
        return PlusOffer(
            plan = plan,
            price = phase.formattedPrice,
            monthlyPrice = PlusOffer.monthlyPrice(phase.priceAmountMicros, phase.priceCurrencyCode, plan),
            offerToken = details.offerToken,
        )
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
                            ready.value = true
                            query()
                        }
                    }
                }

                override fun onBillingServiceDisconnected() {
                    scope.launch {
                        connecting = false
                        ready.value = false
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
        plusStatus.value = PlayPurchase.status(purchases, verifier)
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
        isAutoRenewing = purchase.isAutoRenewing,
    )

    private companion object {
        const val FIRST_RETRY_MILLIS = 1_000L
        const val LAST_RETRY_MILLIS = 60_000L
        const val CONNECT_WAIT_MILLIS = 10_000L
    }
}
