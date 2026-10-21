package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ShelfTest {
    private val library = Fixtures.library
    private val wardrobe = Fixtures.everyLookPainted

    @Test
    fun theShelfStartsWithTheActiveFriendThenGoesBackDownTheLevels() {
        val progress = Progress(journey = Journey.starting(Friend.FROG))
        val levels = progress.shelf(library).map { it.story.level }.distinct()
        assertEquals(listOf(3, 2, 1), levels)
        assertTrue(progress.shelf(library).none { it.story.isBigStory })
    }

    @Test
    fun aStoryIsUnreadInProgressOrFinished() {
        val story = library["golden-hour"]!!
        assertEquals(StoryStanding.Standing.Unread, StoryStanding.of(story, Progress()).standing)
        val midway = StoryStanding.of(story, Progress(completedSentences = mapOf(story.id to 3)))
        assertEquals(StoryStanding.Standing.InProgress(story.sentences.size - 3), midway.standing)
        assertEquals("6 sentences · 3 to go", midway.subtitle)
        val read = StoryStanding.of(story, Progress(completedSentences = mapOf(story.id to story.sentences.size)))
        assertEquals("6 sentences · finished", read.subtitle)
    }

    @Test
    fun keepGoingPicksTheStoryInProgressThenTheFriendsFirstUnread() {
        val fresh = Progress(journey = Journey.starting(Friend.HARE))
        val start = Friend.HARE.startingStoryID(library)
        assertEquals(start, fresh.shelf(library).keepGoing(start)?.story?.id)
        val midway = fresh.copy(completedSentences = mapOf(start to 6, "crunchy-carrot" to 3))
        assertEquals("crunchy-carrot", midway.shelf(library).keepGoing(start)?.story?.id)
        val finished = fresh.copy(completedSentences = mapOf(start to 6))
        assertEquals(library.stories(2)[1].id, finished.shelf(library).keepGoing(start)?.story?.id)
    }

    @Test
    fun eachFriendShowsWhereTheyAreOnTheJourney() {
        var journey = Journey.starting(Friend.HARE)
        assertEquals(JourneyStop.Met, journey.stop(Friend.BUNNY, library))
        assertEquals(JourneyStop.Reading, journey.stop(Friend.HARE, library))
        assertEquals(JourneyStop.Next(bigStoryWaiting = false), journey.stop(Friend.FROG, library))
        assertEquals(JourneyStop.Later, journey.stop(Friend.CROW, library))
        journey = journey.copy(steps = journey.goal(library))
        assertEquals(JourneyStop.Next(bigStoryWaiting = false), journey.stop(Friend.FROG, library))
        journey = journey.copy(storiesRead = library.stories(2).map { it.id }.toSet())
        assertEquals(JourneyStop.Next(bigStoryWaiting = true), journey.stop(Friend.FROG, library))
    }

    @Test
    fun everyItemIsInOneGridAndTappingSwapsTheLook() {
        var progress = Progress(journey = Journey.starting(Friend.GRASSHOPPER), baskets = mapOf(Friend.GRASSHOPPER to Basket(filled = 4)))
        val items = wardrobe.unlockable(Friend.GRASSHOPPER)
        progress = progress.tapping(items[0], Friend.GRASSHOPPER, wardrobe)
        assertEquals(mapOf(items[0].slot to items[0].id), progress.outfits[Friend.GRASSHOPPER])
        progress = progress.tapping(items[1], Friend.GRASSHOPPER, wardrobe)
        assertEquals(listOf(items[1]), progress.outfit(Friend.GRASSHOPPER, wardrobe))
    }

    @Test
    fun tappingTheWornItemOrJustMeTakesTheLookOff() {
        var progress = Progress(journey = Journey.starting(Friend.GRASSHOPPER), baskets = mapOf(Friend.GRASSHOPPER to Basket(filled = 4)))
        val item = wardrobe.unlockable(Friend.GRASSHOPPER)[0]
        progress = progress.tapping(item, Friend.GRASSHOPPER, wardrobe)
        progress = progress.tapping(item, Friend.GRASSHOPPER, wardrobe)
        assertEquals(emptyMap<Slot, String>(), progress.outfits[Friend.GRASSHOPPER])
        progress = progress.tapping(item, Friend.GRASSHOPPER, wardrobe).undressing(Friend.GRASSHOPPER)
        assertTrue(progress.outfit(Friend.GRASSHOPPER, wardrobe).isEmpty())
    }

    @Test
    fun everyFriendWearsTheirFirstItemUntilSomethingElseIsChosen() {
        val firstUnlocks = mapOf(
            Friend.BUNNY to "bluebell-crown",
            Friend.HARE to "straw",
            Friend.FROG to "lilypad-hat",
            Friend.CROW to "flat-cap",
            Friend.CAT to "garden-hat",
            Friend.CRAB to "sailor-cap",
            Friend.GRASSHOPPER to "acorn-cap",
        )
        for ((friend, id) in firstUnlocks) {
            var progress = Progress(journey = Journey.starting(friend))
            val starting = wardrobe.startingItem(friend)!!
            val next = wardrobe.items(friend).first { it.id == id }
            assertEquals(listOf(starting), progress.outfit(friend, wardrobe))
            progress = progress.tapping(next, friend, wardrobe)
            assertEquals(listOf(next), progress.outfit(friend, wardrobe))
            progress = progress.undressing(friend)
            assertTrue(progress.outfit(friend, wardrobe).isEmpty())
        }
    }

    @Test
    fun bobsBowComesOffWhenTappedTwice() {
        val bow = wardrobe.startingItem(Friend.BUNNY)!!
        val crown = wardrobe.items(Friend.BUNNY).first { it.id == "bluebell-crown" }
        var progress = Progress().tapping(crown, Friend.BUNNY, wardrobe)
        progress = progress.tapping(bow, Friend.BUNNY, wardrobe)
        assertEquals(mapOf(Slot.HEAD to bow.id), progress.outfits[Friend.BUNNY])
        progress = progress.tapping(bow, Friend.BUNNY, wardrobe)
        assertTrue(progress.outfit(Friend.BUNNY, wardrobe).isEmpty())
    }
}
