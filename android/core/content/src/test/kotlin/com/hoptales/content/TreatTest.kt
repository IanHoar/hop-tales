package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TreatTest {
    private val library = Fixtures.library

    @Test
    fun aStoryHasOneTreatInItsLastSentence() {
        val story = library["bob-bug"]!!
        val treat = Journey.starting(Friend.BUNNY).treat(story)!!
        assertEquals(story.sentences.size - 1, treat.word.sentence)
        assertEquals(Friend.BUNNY, treat.friend)
        assertFalse(treat.isTrail)
    }

    @Test
    fun stretchStoriesAtYourLevelCarryTheNextFriendsTreat() {
        val stretch = Journey.starting(Friend.BUNNY).treat(library["big-nap"]!!)!!
        assertTrue(stretch.isTrail)
        assertEquals(Friend.HARE, stretch.friend)
        val easier = Journey.starting(Friend.HARE).treat(library["big-nap"]!!)!!
        assertFalse(easier.isTrail)
    }

    @Test
    fun bigStoriesHaveNoTreat() {
        assertNull(Journey.starting(Friend.BUNNY).treat(library["skip-big-story"]!!))
    }

    @Test
    fun basketsNeedThreePlusTheirNumber() {
        var progress = Progress()
        val plain = CollectedTreat(Friend.BUNNY, isTrail = false, isGolden = false)
        val moments = mutableListOf<JourneyMoment>()
        repeat(4) {
            val collected = progress.collecting(plain)
            progress = collected.value
            moments += collected.moments
        }
        assertEquals(listOf(JourneyMoment.BasketFull(Friend.BUNNY, number = 1)), moments)
        assertEquals(5, progress.baskets[Friend.BUNNY]?.goal)
    }

    @Test
    fun aGoldenTreatCountsThree() {
        val golden = CollectedTreat(Friend.HARE, isTrail = false, isGolden = true)
        val progress = Progress().collecting(golden).value
        assertEquals(3, progress.baskets[Friend.HARE]?.inBasket)
        assertEquals(1, progress.baskets[Friend.HARE]?.golden)
    }

    @Test
    fun trailTreatsNeverGoInABasket() {
        val trail = CollectedTreat(Friend.FROG, isTrail = true, isGolden = false)
        val collected = Progress().collecting(trail)
        assertTrue(collected.moments.isEmpty())
        assertTrue(collected.value.baskets.isEmpty())
    }
}
