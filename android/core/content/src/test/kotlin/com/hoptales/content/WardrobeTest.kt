package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WardrobeTest {
    private val wardrobe = Fixtures.everyLookPainted

    private fun item(friend: Friend, id: String) = wardrobe.items(friend).first { it.id == id }

    private fun Progress.filling(friend: Friend, baskets: Int) = copy(baskets = this.baskets + (friend to Basket(filled = baskets)))

    @Test
    fun onlyFullyPaintedLooksAreOffered() {
        for (friend in Friend.entries) {
            assertTrue(friend.key, Fixtures.noLooksPainted.items(friend).isEmpty())
        }
    }

    @Test
    fun theSharedLooksArePainted() {
        for (friend in Friend.entries) {
            assertEquals(friend.key, 6, Fixtures.wardrobe.items(friend).size)
        }
    }

    @Test
    fun everyFriendStartsWithOneItemAndUnlocksFiveMore() {
        assertEquals(13, wardrobe.all[Friend.HARE]?.size)
        for (friend in Friend.entries.filter { it != Friend.HARE }) {
            assertEquals(friend.key, 9, wardrobe.all[friend]?.size)
        }
        for (friend in Friend.entries) {
            assertNotNull(friend.key, WardrobeLibrary.starting[friend])
            assertEquals(friend.key, 6, wardrobe.items(friend).size)
            assertEquals(friend.key, 5, wardrobe.unlockable(friend).size)
        }
    }

    @Test
    fun meetingAFriendGivesTheirFirstItemAndEachBasketTheNext() {
        var progress = Progress(journey = Journey.starting(Friend.HARE))
        assertEquals(1, progress.unlockedCount(Friend.HARE, wardrobe))
        assertEquals(0, progress.unlockedCount(Friend.FROG, wardrobe))
        assertEquals("straw", progress.newestItem(Friend.HARE, wardrobe)?.id)
        progress = progress.filling(Friend.HARE, 2)
        assertEquals(3, progress.unlockedCount(Friend.HARE, wardrobe))
        assertEquals("crown", progress.newestItem(Friend.HARE, wardrobe)?.id)
    }

    @Test
    fun onlyUnlockedItemsCanBeWornAndOneItemPerSlot() {
        var progress = Progress(journey = Journey.starting(Friend.GRASSHOPPER))
        val satchel = wardrobe.startingItem(Friend.GRASSHOPPER)!!
        val items = wardrobe.unlockable(Friend.GRASSHOPPER)
        progress = progress.wearing(items[1], Friend.GRASSHOPPER, wardrobe)
        assertEquals(listOf(satchel), progress.outfit(Friend.GRASSHOPPER, wardrobe))
        progress = progress.wearing(items[0], Friend.GRASSHOPPER, wardrobe)
        assertEquals(listOf(items[0]), progress.outfit(Friend.GRASSHOPPER, wardrobe))
        progress = progress.filling(Friend.GRASSHOPPER, 1).wearing(items[1], Friend.GRASSHOPPER, wardrobe)
        assertEquals(listOf(items[1]), progress.outfit(Friend.GRASSHOPPER, wardrobe))
        progress = progress.takingOff(items[1].slot, Friend.GRASSHOPPER, wardrobe)
        assertTrue(progress.outfit(Friend.GRASSHOPPER, wardrobe).isEmpty())
    }

    @Test
    fun startingItemsAreWornUntilSomethingElseIsChosen() {
        val cases = listOf(
            Triple(Friend.BUNNY, "bow", Slot.HEAD),
            Triple(Friend.HARE, "scarf", Slot.NECK),
            Triple(Friend.FROG, "neckerchief", Slot.NECK),
            Triple(Friend.CROW, "knit-cap", Slot.HEAD),
            Triple(Friend.CAT, "sage-collar", Slot.NECK),
            Triple(Friend.CRAB, "sailor-kerchief", Slot.NECK),
            Triple(Friend.GRASSHOPPER, "satchel", Slot.BACK),
        )
        for ((friend, id, slot) in cases) {
            val item = wardrobe.startingItem(friend)!!
            assertEquals(id, item.id)
            assertEquals(slot, item.slot)
            assertEquals(item, wardrobe.items(friend).first())
            assertFalse(item in wardrobe.unlockable(friend))
            val fresh = Progress()
            assertTrue(fresh.isUnlocked(item, friend, wardrobe))
            assertEquals(listOf(item), fresh.outfit(friend, wardrobe))
        }
    }

    @Test
    fun startingItemsLeaveTheUnlockOrderAlone() {
        val bow = wardrobe.startingItem(Friend.BUNNY)!!
        var progress = Progress()
        assertEquals("bluebell-crown", progress.newestItem(Friend.BUNNY, wardrobe)?.id)
        assertEquals(1, progress.unlockedCount(Friend.BUNNY, wardrobe))
        progress = progress.filling(Friend.BUNNY, 1)
        assertEquals("bonnet", progress.newestItem(Friend.BUNNY, wardrobe)?.id)
        assertTrue(progress.isUnlocked(bow, Friend.BUNNY, wardrobe))
    }

    @Test
    fun anotherHatReplacesBobsBow() {
        val crown = item(Friend.BUNNY, "bluebell-crown")
        var progress = Progress().wearing(crown, Friend.BUNNY, wardrobe)
        assertEquals(listOf(crown), progress.outfit(Friend.BUNNY, wardrobe))
        progress = progress.takingOff(Slot.HEAD, Friend.BUNNY, wardrobe)
        assertTrue(progress.outfit(Friend.BUNNY, wardrobe).isEmpty())
    }

    @Test
    fun anythingElseReplacesSkipsScarf() {
        val straw = item(Friend.HARE, "straw")
        val progress = Progress(journey = Journey.starting(Friend.HARE)).wearing(straw, Friend.HARE, wardrobe)
        assertEquals(listOf(straw), progress.outfit(Friend.HARE, wardrobe))
    }

    @Test
    fun takingOffAStartingItemLeavesThemBare() {
        for ((friend, slot) in listOf(Friend.BUNNY to Slot.HEAD, Friend.HARE to Slot.NECK)) {
            val itemOff = Progress().takingOff(slot, friend, wardrobe)
            assertEquals(emptyMap<Slot, String>(), itemOff.outfits[friend])
            assertTrue(itemOff.outfit(friend, wardrobe).isEmpty())

            val justMe = Progress().undressing(friend)
            assertEquals(emptyMap<Slot, String>(), justMe.outfits[friend])
            assertTrue(justMe.outfit(friend, wardrobe).isEmpty())
        }
    }

    @Test
    fun aFriendWearsOneLookAtATime() {
        val items = wardrobe.items(Friend.HARE)
        var progress = Progress(journey = Journey.starting(Friend.HARE)).filling(Friend.HARE, items.size)
        val first = items.first()
        val other = items.first { it.slot != first.slot }
        progress = progress.wearing(first, Friend.HARE, wardrobe).wearing(other, Friend.HARE, wardrobe)
        assertEquals(listOf(other), progress.outfit(Friend.HARE, wardrobe))
    }

    @Test
    fun aFullBasketNamesTheItemItUnlocks() {
        assertEquals("bonnet", JourneyMoment.BasketFull(Friend.BUNNY, number = 1).unlockedItem(wardrobe)?.id)
    }

    @Test
    fun pairedItemsHaveTwoParts() {
        val mittens = item(Friend.CRAB, "claw-mittens")
        assertEquals(2, mittens.parts.size)
        assertEquals(Slot.CLAWS, mittens.slot)
    }
}
