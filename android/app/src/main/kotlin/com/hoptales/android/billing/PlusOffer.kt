package com.hoptales.android.billing

import com.hoptales.content.PlusPlan
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.NumberFormat
import java.util.Currency
import java.util.Locale

data class PlusOffer(val plan: PlusPlan, val price: String, val monthlyPrice: String? = null, val offerToken: String = "") {
    companion object {
        val SAMPLES = listOf(
            PlusOffer(PlusPlan.YEARLY, "$29.99", monthlyPrice = "$2.50"),
            PlusOffer(PlusPlan.MONTHLY, "$4.99"),
        )

        fun inPaywallOrder(offers: List<PlusOffer>): List<PlusOffer> =
            PlusPlan.PAYWALL_ORDER.mapNotNull { plan -> offers.firstOrNull { it.plan == plan } }

        fun monthlyPrice(micros: Long, currencyCode: String, plan: PlusPlan, locale: Locale = Locale.getDefault()): String? {
            if (plan.months <= 1) return null
            val currency = runCatching { Currency.getInstance(currencyCode) }.getOrNull() ?: return null
            val format = NumberFormat.getCurrencyInstance(locale).apply { this.currency = currency }
            val digits = currency.defaultFractionDigits.coerceAtLeast(0)
            val amount = BigDecimal.valueOf(micros).divide(BigDecimal.valueOf(MICROS * plan.months), digits, RoundingMode.HALF_UP)
            return format.format(amount)
        }

        private const val MICROS = 1_000_000L
    }
}

enum class PurchaseOutcome { PURCHASED, PENDING, CANCELLED, FAILED }
