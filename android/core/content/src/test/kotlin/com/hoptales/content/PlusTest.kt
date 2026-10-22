package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PlusTest {
    private val library = Fixtures.library

    @Test
    fun everyLevelOneStoryIsFree() {
        val free = library.all.filter { it.isFree }.map { it.id }
        assertEquals(listOf("meadow-walk", "bob-bug", "big-nap", "mud-and-jam"), free)
        assertTrue(library.all.all { it.isFree == (it.level == 1) })
    }

    @Test
    fun storiesAboveLevelOneLockWithoutPlus() {
        val locked = library.all.filter { Plus.isLocked(it, isPlus = false, locksStories = true) }
        assertFalse(locked.isEmpty())
        assertTrue(locked.all { it.level > 1 })
        assertEquals(library.all.count { it.level > 1 }, locked.size)
    }

    @Test
    fun levelOneNeverLocks() {
        val free = library.all.filter { it.level == 1 }
        assertTrue(free.none { Plus.isLocked(it, isPlus = false, locksStories = true) })
    }

    @Test
    fun plusOpensEveryStory() {
        assertTrue(library.all.none { Plus.isLocked(it, isPlus = true, locksStories = true) })
    }

    @Test
    fun theSwitchOffLocksNothing() {
        assertTrue(library.all.none { Plus.isLocked(it, isPlus = false, locksStories = false) })
    }

    @Test
    fun appStoreProductsMapOntoPlans() {
        assertEquals(PlusPlan.MONTHLY, PlusPlan.fromAppStore("com.hoptales.plus.monthly"))
        assertEquals(PlusPlan.YEARLY, PlusPlan.fromAppStore("com.hoptales.plus.yearly"))
        assertNull(PlusPlan.fromAppStore("com.hoptales.plus.weekly"))
        assertEquals("hop_tales_plus", PlusPlan.APP_STORE_GROUP)
        assertTrue(PlusPlan.entries.all { PlusPlan.fromAppStore(it.appStoreProductId) == it })
    }

    @Test
    fun playBasePlansMapOntoPlans() {
        assertEquals(PlusPlan.MONTHLY, PlusPlan.fromPlay("hop_tales_plus", "monthly"))
        assertEquals(PlusPlan.YEARLY, PlusPlan.fromPlay("hop_tales_plus", "yearly"))
        assertNull(PlusPlan.fromPlay("hop_tales_plus", "weekly"))
        assertNull(PlusPlan.fromPlay("com.hoptales.plus.monthly", "monthly"))
        assertTrue(PlusPlan.entries.all { PlusPlan.fromPlay(PlusPlan.PLAY_PRODUCT_ID, it.playBasePlanId) == it })
    }

    @Test
    fun thePaywallLeadsWithTheYearlyPlan() {
        assertEquals(listOf(PlusPlan.YEARLY, PlusPlan.MONTHLY), PlusPlan.PAYWALL_ORDER)
        assertEquals(12, PlusPlan.YEARLY.months)
        assertEquals(1, PlusPlan.MONTHLY.months)
    }
}
