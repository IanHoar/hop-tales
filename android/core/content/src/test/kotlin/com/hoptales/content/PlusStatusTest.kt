package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate
import java.util.Locale

class PlusStatusTest {
    private val march3 = LocalDate.of(2026, 3, 3)

    private fun line(status: PlusStatus) = status.line(Locale.forLanguageTag("en-CA"))

    @Test
    fun theStatusIsInPlainWords() {
        assertEquals("Free: the Level 1 stories", line(PlusStatus.Free))
        assertEquals("Plus: every story", line(PlusStatus.Plus))
        assertEquals("Plus, renews 3 March", line(PlusStatus.Renews(march3)))
        assertEquals("Plus, renews automatically", line(PlusStatus.Renews()))
        assertEquals("Plus, ends 3 March", line(PlusStatus.Ends(march3)))
        assertEquals("Plus, ends at the end of this period", line(PlusStatus.Ends()))
        assertEquals("Plus, shared by your family", line(PlusStatus.FamilyShared))
        assertEquals("There's a problem with your payment", line(PlusStatus.PaymentProblem))
        assertEquals("Waiting for your payment to go through", line(PlusStatus.Pending))
    }

    @Test
    fun onlyAFreeReaderIsOfferedSubscribe() {
        assertTrue(PlusStatus.Free.canSubscribe)
        assertFalse(PlusStatus.Free.canManage)
        val kinds = listOf(PlusStatus.Plus, PlusStatus.Renews(), PlusStatus.Ends(), PlusStatus.FamilyShared, PlusStatus.PaymentProblem)
        for (kind in kinds) {
            assertFalse(kind.canSubscribe)
            assertTrue(kind.canManage)
        }
    }

    @Test
    fun aPaymentProblemSaysWhereToFixIt() {
        assertNotNull(PlusStatus.PaymentProblem.detail)
        assertNull(PlusStatus.Renews().detail)
    }

    @Test
    fun aRefundIsOfferedOnlyForAPaidSubscription() {
        assertTrue(PlusStatus.Renews().canRequestRefund)
        assertTrue(PlusStatus.Ends().canRequestRefund)
        assertFalse(PlusStatus.Free.canRequestRefund)
        assertFalse(PlusStatus.Pending.canRequestRefund)
        assertFalse(PlusStatus.FamilyShared.canRequestRefund)
    }

    @Test
    fun theEntitlementStandsInWhenTheStoreSaysNothing() {
        assertEquals(PlusStatus.Free, PlusStatus.resolved(isPlus = false, details = null))
        assertEquals(PlusStatus.Plus, PlusStatus.resolved(isPlus = true, details = null))
        assertEquals(PlusStatus.Plus, PlusStatus.resolved(isPlus = true, details = PlusStatus.Free))
        assertEquals(PlusStatus.PaymentProblem, PlusStatus.resolved(isPlus = false, details = PlusStatus.PaymentProblem))
    }
}
