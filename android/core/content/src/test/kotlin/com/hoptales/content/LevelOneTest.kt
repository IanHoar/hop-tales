package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LevelOneTest {
    private val library = Fixtures.library
    private val levelOne = library.stories(1)
    private val last = levelOne.last()
    private val tally = JourneyMoment.Tally(steps = 41.0, total = 200.0, goal = 200.0, bigWords = 0, next = Friend.HARE, storiesLeft = 0)

    private fun finished(stories: List<Story> = levelOne) = Progress(completedSentences = stories.associate { it.id to it.sentences.size })

    private fun Progress.celebrate(
        story: Story = last,
        moments: List<JourneyMoment> = listOf(tally),
        isPlus: Boolean = false,
        locksStories: Boolean = true,
    ) = celebratingLevelOne(story, moments, library, isPlus, locksStories)

    @Test
    fun finishingTheLastLevelOneStoryCelebratesAfterTheTally() {
        val recorded = finished().celebrate()
        assertEquals(listOf(tally, JourneyMoment.LevelOneFinished), recorded.moments)
        assertTrue(recorded.value.levelOneCelebrated)
    }

    @Test
    fun itTakesTheBigStoryCardsPlace() {
        val recorded = finished().celebrate(moments = listOf(tally, JourneyMoment.BigStoryReady(Friend.HARE)))
        assertEquals(listOf(tally, JourneyMoment.LevelOneFinished), recorded.moments)
    }

    @Test
    fun aNewFriendOnTheSameReadFollowsIt() {
        val newFriend = JourneyMoment.NewFriend(Friend.HARE, LevelUp.TRAIL)
        val recorded = finished().celebrate(moments = listOf(tally, newFriend))
        assertEquals(listOf(tally, JourneyMoment.LevelOneFinished, newFriend), recorded.moments)
    }

    @Test
    fun theTreatStaysWithTheTallyAndAFullBasketFollows() {
        val treat = JourneyMoment.TreatFound(CollectedTreat(Friend.BUNNY, isTrail = false, isGolden = false), trail = 0)
        val basket = JourneyMoment.BasketFull(Friend.BUNNY, number = 1)
        val recorded = finished().celebrate(moments = listOf(tally, treat, basket))
        assertEquals(listOf(tally, treat, JourneyMoment.LevelOneFinished, basket), recorded.moments)
    }

    @Test
    fun notWhileALevelOneStoryIsLeft() {
        val recorded = finished(levelOne.dropLast(1)).celebrate(story = levelOne[0])
        assertEquals(listOf(tally), recorded.moments)
        assertFalse(recorded.value.levelOneCelebrated)
    }

    @Test
    fun aStoryPartlyReadIsNotFinished() {
        val progress = finished().let { it.copy(completedSentences = it.completedSentences + (last.id to last.sentences.size - 1)) }
        assertFalse(progress.hasFinishedLevelOne(library))
    }

    @Test
    fun onlyOnce() {
        val moments = listOf(tally, JourneyMoment.BigStoryReady(Friend.HARE))
        val recorded = finished().copy(levelOneCelebrated = true).celebrate(moments = moments)
        assertEquals(moments, recorded.moments)
    }

    @Test
    fun neverForPlus() {
        val recorded = finished().celebrate(isPlus = true)
        assertEquals(listOf(tally), recorded.moments)
        assertFalse(recorded.value.levelOneCelebrated)
    }

    @Test
    fun neverWhileEveryStoryIsOpen() {
        val recorded = finished().celebrate(locksStories = false)
        assertEquals(listOf(tally), recorded.moments)
        assertFalse(recorded.value.levelOneCelebrated)
    }

    @Test
    fun aReaderWhoHadFinishedSeesItAtTheirNextLevelOneStory() {
        val recorded = finished().celebrate(story = levelOne[0])
        assertEquals(listOf(tally, JourneyMoment.LevelOneFinished), recorded.moments)
    }

    @Test
    fun aStoryAboveLevelOneDoesNotShowIt() {
        val recorded = finished().celebrate(story = library.stories(2)[0])
        assertEquals(listOf(tally), recorded.moments)
        assertFalse(recorded.value.levelOneCelebrated)
    }

    @Test
    fun progressSavedBeforeTheFlagHasNotCelebrated() {
        val progress = StoryLibrary.json.decodeFromString(Progress.serializer(), """{"completedSentences":{},"stars":3,"wordsRead":{}}""")
        assertFalse(progress.levelOneCelebrated)
    }
}
