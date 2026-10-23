package com.hoptales.reading

import com.hoptales.content.Basket
import com.hoptales.content.CollectedTreat
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.JourneyMoment
import com.hoptales.content.Levels
import com.hoptales.content.Progress
import com.hoptales.content.StoryLibrary
import com.hoptales.content.treat
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class FinishingTest {
    private val library = StoryLibrary.decode(File(System.getProperty("hoptales.resources"), "stories.json").readText())
    private val journey = Journey.starting(Friend.BUNNY)
    private val story = library["bob-bug"]!!

    private fun reading() = Reading(story, bigWords = journey.bigWords(story, library), treat = journey.treat(story))

    private fun Reading.readToTheEnd(helping: Int = 0) {
        repeat(helping) {
            helpRequested()
            speechFinished()
            skipWord()
        }
        while (!state.isFinished) skipWord()
    }

    @Test
    fun aStoryReadAloneTalliesStepsAndAGoldenTreat() {
        val reading = reading()
        reading.readToTheEnd()
        val progress = reading.finishing(Progress(journey = journey), library)
        val tally = reading.state.tally!!
        assertEquals(Friend.HARE, tally.next)
        assertEquals(progress.journey.steps, tally.total, 0.0)
        assertTrue(tally.steps > story.wordCount)
        assertEquals(CollectedTreat(Friend.BUNNY, isTrail = false, isGolden = true), reading.state.collectedTreat?.treat)
        assertEquals(3, progress.baskets[Friend.BUNNY]?.inBasket)
        assertTrue(story.id in progress.journey.storiesRead)
    }

    @Test
    fun helpKeepsTheTreatPlain() {
        val reading = reading()
        reading.readToTheEnd(helping = story.wordCount / 2)
        val progress = reading.finishing(Progress(journey = journey), library)
        assertEquals(CollectedTreat(Friend.BUNNY, isTrail = false, isGolden = false), reading.state.collectedTreat?.treat)
        assertEquals(1, progress.baskets[Friend.BUNNY]?.total)
    }

    @Test
    fun aFullBasketIsACalloutThatCanBeDismissed() {
        val reading = reading()
        reading.readToTheEnd()
        reading.finishing(Progress(journey = journey, baskets = mapOf(Friend.BUNNY to Basket(inBasket = 3))), library)
        assertEquals(JourneyMoment.BasketFull(Friend.BUNNY, number = 1), reading.state.callout)
        reading.momentDismissed()
        assertNull(reading.state.callout)
        assertTrue(reading.state.tally != null)
    }

    @Test
    fun readingAgainForgetsTheMomentsButKeepsTheTreat() {
        val reading = reading()
        reading.readToTheEnd()
        reading.finishing(Progress(journey = journey), library)
        reading.readAgain()
        assertTrue(reading.state.journeyMoments.isEmpty())
        assertEquals(journey.treat(story), reading.state.treat)
    }

    @Test
    fun tryingTheItemOnLeavesTheBasketForDoneThenTheTally() {
        val reading = reading()
        reading.readToTheEnd()
        reading.finishing(Progress(journey = journey, baskets = mapOf(Friend.BUNNY to Basket(inBasket = 3))), library)
        reading.tryItOn()
        assertTrue(reading.state.hasTriedItOn)
        assertEquals(JourneyMoment.BasketFull(Friend.BUNNY, number = 1), reading.state.callout)
        reading.momentDismissed()
        assertFalse(reading.state.hasTriedItOn)
        assertNull(reading.state.callout)
        assertTrue(reading.state.tally != null)
    }

    private val levelOneRead = Progress(
        journey = journey,
        completedSentences = library.stories(Friend.BUNNY.level).associate { it.id to it.sentences.size },
    )

    @Test
    fun finishingLevelOneWhileStoriesLockCelebratesThenGoesBackToTheStories() {
        val reading = reading()
        reading.readToTheEnd()
        val progress = reading.finishing(levelOneRead, library, isPlus = false, locksStories = true)
        assertEquals(JourneyMoment.LevelOneFinished, reading.state.callout)
        assertTrue(progress.levelOneCelebrated)
        assertTrue(reading.backToMyStories())
        assertNull(reading.state.callout)
    }

    @Test
    fun finishingLevelOneWithEveryStoryOpenDoesNotCelebrate() {
        val reading = reading()
        reading.readToTheEnd()
        val progress = reading.finishing(levelOneRead, library, isPlus = false, locksStories = false)
        assertFalse(reading.state.journeyMoments.contains(JourneyMoment.LevelOneFinished))
        assertFalse(progress.levelOneCelebrated)
    }

    @Test
    fun aNewFriendEarnedOnTheSameReadFollowsLevelOne() {
        val trailFull = journey.copy(
            trail = Levels.trailGoal(journey.level),
            storiesRead = library.stories(journey.level).map { it.id }.toSet(),
        )
        val reading = Reading(story, bigWords = trailFull.bigWords(story, library), treat = trailFull.treat(story))
        reading.readToTheEnd()
        reading.finishing(levelOneRead.copy(journey = trailFull), library, isPlus = false, locksStories = true)
        assertEquals(JourneyMoment.LevelOneFinished, reading.state.callout)
        assertFalse(reading.backToMyStories())
        assertTrue(reading.state.callout is JourneyMoment.NewFriend)
        assertTrue(reading.backToMyStories())
        assertNull(reading.state.callout)
    }

    @Test
    fun aNewFriendGoesBackToTheStoriesNotIntoTheirFirstStory() {
        val trailFull = journey.copy(
            trail = Levels.trailGoal(journey.level),
            storiesRead = library.stories(journey.level).map { it.id }.toSet(),
        )
        val reading = Reading(story, bigWords = trailFull.bigWords(story, library), treat = trailFull.treat(story))
        reading.readToTheEnd()
        reading.finishing(Progress(journey = trailFull), library)
        assertTrue(reading.state.callout is JourneyMoment.NewFriend)
        assertTrue(reading.backToMyStories())
        assertNull(reading.state.callout)
    }

    @Test
    fun onlyASentenceInsideTheStoryEndsASentence() {
        val reading = reading()
        assertFalse(reading.state.endedASentence)
        while (reading.state.sentenceIndex == 0) reading.skipWord()
        assertTrue(reading.state.endedASentence)
        reading.readToTheEnd()
        assertFalse(reading.state.endedASentence)
    }
}
