package com.hoptales.content

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

sealed interface PlusStatus {
    data object Free : PlusStatus

    data object Plus : PlusStatus

    data class Renews(val date: LocalDate? = null) : PlusStatus

    data class Ends(val date: LocalDate? = null) : PlusStatus

    data object FamilyShared : PlusStatus

    data object PaymentProblem : PlusStatus

    data object Pending : PlusStatus

    val canSubscribe: Boolean get() = this == Free

    val canManage: Boolean get() = this != Free

    val canRequestRefund: Boolean get() = this == Plus || this is Renews || this is Ends || this == PaymentProblem

    val detail: String?
        get() = when (this) {
            PaymentProblem -> "Check your payment details under Manage subscription."
            Pending -> "Every story opens as soon as it does."
            else -> null
        }

    fun line(locale: Locale = Locale.getDefault()): String = when (this) {
        Free -> "Free: the Level 1 stories"
        Plus -> "Plus: every story"
        is Renews -> date?.let { "Plus, renews ${day(it, locale)}" } ?: "Plus, renews automatically"
        is Ends -> date?.let { "Plus, ends ${day(it, locale)}" } ?: "Plus, ends at the end of this period"
        FamilyShared -> "Plus, shared by your family"
        PaymentProblem -> "There's a problem with your payment"
        Pending -> "Waiting for your payment to go through"
    }

    companion object {
        const val GIVES = "Plus opens every story above Level 1."
        const val RHYTHM = "A new story every month, and something new each season."

        fun resolved(isPlus: Boolean, details: PlusStatus?): PlusStatus = when {
            details == null || details == Free -> if (isPlus) Plus else Free
            else -> details
        }

        private fun day(date: LocalDate, locale: Locale): String = date.format(DateTimeFormatter.ofPattern("d MMMM", locale))
    }
}
