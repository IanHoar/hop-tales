package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.floor

class JourneyTest {
    private val library = Fixtures.library

    private fun words(story: String) = library[story]?.wordCount ?: 0

    private fun Journey.everyStoryRead() = copy(storiesRead = library.stories(level).map { it.id }.toSet())

    private fun Journey.record(result: StoryResult): Pair<Journey, List<JourneyMoment>> =
        recording(result, library).let { it.value to it.moments }

    @Test
    fun startingWithAFriendMeetsTheEasierOnes() {
        val journey = Journey.starting(Friend.FROG)
        assertEquals(3, journey.level)
        assertEquals(setOf(Friend.BUNNY, Friend.HARE, Friend.FROG), journey.met)
        assertEquals(Friend.FROG, journey.activeFriend)
        assertEquals(Friend.CROW, journey.nextFriend)
    }

    @Test
    fun wordsAtYourLevelAreAStepAndBigWordsAreFive() {
        val journey = Journey.starting(Friend.BUNNY)
        val story = library["bob-bug"]!!
        val result = StoryResult(story.id, wordsRead = 20, bigWordsRead = 2, helpedWords = 5)
        assertEquals(18.0 + 10, journey.stepsEarned(result, story), 0.0)
    }

    @Test
    fun aStoryReadWithLittleHelpEarnsTheBonus() {
        val journey = Journey.starting(Friend.BUNNY)
        val story = library["bob-bug"]!!
        assertEquals(20 + Levels.STORY_BONUS, journey.stepsEarned(StoryResult(story.id, wordsRead = 20), story), 0.0)
    }

    @Test
    fun easierStoriesEarnHalfAStepAndNoBonus() {
        val journey = Journey.starting(Friend.HARE)
        val story = library["bob-bug"]!!
        assertEquals(10.0, journey.stepsEarned(StoryResult(story.id, wordsRead = 20), story), 0.0)
    }

    @Test
    fun helpNeverCostsAStep() {
        val journey = Journey.starting(Friend.BUNNY)
        val story = library["bob-bug"]!!
        val alone = StoryResult(story.id, wordsRead = 20, helpedWords = 3)
        val helped = StoryResult(story.id, wordsRead = 20, helpedWords = 20)
        assertEquals(journey.stepsEarned(alone, story), journey.stepsEarned(helped, story), 0.0)
    }

    @Test
    fun aFullPathOffersTheBigStory() {
        var journey = Journey.starting(Friend.BUNNY).everyStoryRead()
        journey = journey.copy(steps = journey.goal(library) - 5)
        val (after, moments) = journey.record(StoryResult("bob-bug", wordsRead = 10, helpedWords = 5))
        assertTrue(after.isPathFull(library))
        assertEquals(JourneyMoment.BigStoryReady(Friend.HARE), moments.last())
        assertEquals("skip-big-story", after.bigStory(library)?.id)
        assertEquals(after.goal(library), after.steps, 0.0)
    }

    @Test
    fun readingTheBigStoryWellMeetsTheNextFriend() {
        var journey = Journey.starting(Friend.BUNNY).everyStoryRead()
        journey = journey.copy(steps = journey.goal(library))
        val words = words("skip-big-story")
        val (after, moments) = journey.record(StoryResult("skip-big-story", wordsRead = words, helpedWords = 2))
        assertEquals(listOf(JourneyMoment.NewFriend(Friend.HARE, LevelUp.BIG_STORY)), moments)
        assertEquals(2, after.level)
        assertEquals(Friend.HARE, after.activeFriend)
        assertTrue(Friend.HARE in after.met)
        assertEquals(0.0, after.steps, 0.0)
    }

    @Test
    fun aBigStoryWithTooMuchHelpIsNotYetAndNothingIsLost() {
        var journey = Journey.starting(Friend.BUNNY).everyStoryRead()
        journey = journey.copy(steps = journey.goal(library))
        val words = words("skip-big-story")
        val (after, moments) = journey.record(StoryResult("skip-big-story", wordsRead = words, helpedWords = words / 2))
        assertEquals(listOf(JourneyMoment.NotYet(Friend.HARE)), moments)
        assertEquals(1, after.level)
        assertTrue(after.isPathFull(library))
        assertEquals(1, after.bigStoryAttempts)
    }

    @Test
    fun theNextFriendIsAFewGoodReadsAwayAndTheRoutesStayBalanced() {
        assertEquals(mapOf(1 to 160, 2 to 200, 3 to 250, 4 to 320, 5 to 390, 6 to 460), library.levels.stepsToNextFriend)
        for (level in 1 until Levels.top) {
            val reads = (library.levels.stepsToNextFriend[level] ?: 0) / library.levels.goodRead(level)
            assertTrue("level $level", reads in 3.0..6.0)
            assertTrue("level $level", Levels.trailGoal(level) >= floor(reads).toInt())
            assertTrue("level $level", Levels.trailGoal(level) < Levels.SUSTAINED_STORIES)
        }
    }

    @Test
    fun theNextFriendWaitsUntilEveryStoryAtTheLevelIsRead() {
        var journey = Journey.starting(Friend.BUNNY)
        journey = journey.copy(
            steps = journey.goal(library),
            trail = Levels.trailGoal(1),
            storiesReadWell = Levels.SUSTAINED_STORIES,
        )
        val stories = library.stories(1)
        assertFalse(journey.isPathFull(library))
        for (story in stories.dropLast(1)) {
            val (after, moments) = journey.record(StoryResult(story.id, wordsRead = 5))
            journey = after
            assertEquals(1, journey.level)
            assertTrue(moments.none { it.isCallout })
        }
        assertEquals(listOf(stories.last().id), journey.storiesLeft(library).map { it.id })
        val (after, moments) = journey.record(StoryResult(stories.last().id, wordsRead = 5))
        assertEquals(JourneyMoment.NewFriend(Friend.HARE, LevelUp.TRAIL), moments.last())
        assertTrue(after.storiesRead.isEmpty())
    }

    @Test
    fun easierStoriesDoNotCountTowardsTheLevel() {
        val (journey, _) = Journey.starting(Friend.HARE).record(StoryResult("bob-bug", wordsRead = 5))
        assertTrue(journey.storiesRead.isEmpty())
        assertEquals(library.stories(2).size, journey.storiesLeft(library).size)
    }

    @Test
    fun eightStoriesReadWellMoveUpWithoutTheBigStory() {
        var journey = Journey.starting(Friend.BUNNY).everyStoryRead()
        var last = emptyList<JourneyMoment>()
        repeat(Levels.SUSTAINED_STORIES) {
            val (after, moments) = journey.record(StoryResult("big-nap", wordsRead = 1))
            journey = after
            last = moments
        }
        assertEquals(JourneyMoment.NewFriend(Friend.HARE, LevelUp.SUSTAINED_READING), last.last())
        assertEquals(2, journey.level)
        assertEquals(0, journey.storiesReadWell)
    }

    @Test
    fun aFullTrailBringsTheNextFriend() {
        var journey = Journey.starting(Friend.HARE).everyStoryRead()
        val trail = CollectedTreat(Friend.FROG, isTrail = true, isGolden = false)
        var last = emptyList<JourneyMoment>()
        repeat(Levels.trailGoal(2)) {
            val (after, moments) = journey.record(StoryResult("crunchy-carrot", wordsRead = 5, helpedWords = 5, treat = trail))
            journey = after
            last = moments
        }
        assertEquals(JourneyMoment.NewFriend(Friend.FROG, LevelUp.TRAIL), last.last())
        assertEquals(0, journey.trail)
    }

    @Test
    fun theTopFriendHasNoPathToFill() {
        val journey = Journey.starting(Friend.BUNNY).copy(level = 7, activeFriend = Friend.GRASSHOPPER)
        val (after, moments) = journey.record(StoryResult("bartholomew-fiddle", wordsRead = 40))
        assertTrue(moments.isEmpty())
        assertFalse(after.isPathFull(library))
    }

    @Test
    fun bigWordsRiseAsThePathFillsAndBackOffWhenItIsHard() {
        val story = library["bartholomew-journey"]!!
        var journey = Journey.starting(Friend.BUNNY).copy(level = 7)
        val early = journey.bigWords(story, library)
        journey = journey.copy(steps = 1_000.0, level = 6)
        val late = journey.bigWords(library["barnacle-storm"]!!, library)
        assertTrue(early.size <= late.size + 2)
        journey = journey.copy(recentHelpRates = listOf(0.5, 0.5, 0.5))
        assertEquals(Levels.BIG_WORD_RATE_EARLY, journey.bigWordShare(library), 0.0)
    }

    @Test
    fun easierAndBigStoriesShowNoBigWords() {
        val journey = Journey.starting(Friend.FROG)
        assertTrue(journey.bigWords(library["bob-bug"]!!, library).isEmpty())
        assertTrue(journey.bigWords(library["oggy-big-story"]!!, library).isEmpty())
    }

    @Test
    fun aGrownUpCanMoveBetweenMetFriendsButNotSkipPastLevelThree() {
        var journey = Journey.starting(Friend.BUNNY)
        journey = journey.grownUpMovedTo(Friend.FROG)
        assertEquals(3, journey.level)
        journey = journey.grownUpMovedTo(Friend.CROW)
        assertEquals(Friend.FROG, journey.activeFriend)
        journey = journey.grownUpMovedTo(Friend.BUNNY)
        assertEquals(Friend.BUNNY, journey.activeFriend)
        assertEquals(3, journey.level)
    }

    @Test
    fun aSavedJourneyCountsTheStoriesAlreadyFinished() {
        val journey = """
            {"level":1,"steps":40,"met":["bunny"],"activeFriend":"bunny","bigStoryAttempts":0,
            "trail":0,"storiesReadWell":0,"recentHelpRates":[],"cleanStreak":0}
        """.trimIndent()
        val json = """
            {"completedSentences":{"bob-bug":6,"meadow-walk":2},"stars":4,"wordsRead":{},
            "journey":$journey}
        """.trimIndent()
        val progress = StoryLibrary.json.decodeFromString(Progress.serializer(), json).restoringStoriesRead(library)
        assertEquals(40.0, progress.journey.steps, 0.0)
        assertEquals(setOf("bob-bug"), progress.journey.storiesRead)
    }

    @Test
    fun aProgressFileFromBeforeTheJourneyStartsFresh() {
        val json = """{"completedSentences":{},"stars":4,"wordsRead":{}}"""
        val progress = StoryLibrary.json.decodeFromString(Progress.serializer(), json).restoringStoriesRead(library)
        assertEquals(Journey(), progress.journey)
        assertEquals(4, progress.stars)
    }

    @Test
    fun anAndroidProgressFileFromBeforeTheJourneyKeepsItsStarsAndSentences() {
        val json = """{"stars":31,"completedSentences":{"meadow-walk":6,"golden-hour":2},"wordsRead":{"meadow-walk":30}}"""
        val progress = StoryLibrary.json.decodeFromString(Progress.serializer(), json).restoringStoriesRead(library)
        assertEquals(31, progress.stars)
        assertEquals(mapOf("meadow-walk" to 6, "golden-hour" to 2), progress.completedSentences)
        assertEquals(mapOf("meadow-walk" to 30), progress.wordsRead)
        assertEquals(setOf("meadow-walk"), progress.journey.storiesRead)
    }

    @Test
    fun whatIsSavedComesBack() {
        val progress = Progress(
            stars = 41,
            completedSentences = mapOf("castle-road" to 3),
            wordsRead = mapOf("castle-road" to 18, "pond" to 4),
            journey = Journey.starting(Friend.FROG).copy(steps = 12.5, recentHelpRates = listOf(0.1)),
            baskets = mapOf(Friend.FROG to Basket(total = 5, golden = 1)),
            outfits = mapOf(Friend.FROG to mapOf(Slot.HEAD to "straw-hat"), Friend.BUNNY to emptyMap()),
        )
        val json = StoryLibrary.json.encodeToString(Progress.serializer(), progress)
        assertEquals(progress, StoryLibrary.json.decodeFromString(Progress.serializer(), json))
    }
}
