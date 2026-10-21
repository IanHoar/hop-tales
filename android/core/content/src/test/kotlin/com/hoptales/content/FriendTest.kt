package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FriendTest {
    @Test
    fun theFriendsAreTheSevenLevelsInOrder() {
        assertEquals((1..7).toList(), Friend.entries.map { it.level })
        assertEquals(listOf(Friend.BUNNY, Friend.HARE, Friend.FROG), Friend.starters)
    }

    @Test
    fun aFriendIsSavedByItsKey() {
        for (friend in Friend.entries) {
            assertEquals("\"${friend.key}\"", StoryLibrary.json.encodeToString(Friend.serializer(), friend))
        }
    }
}

class LevelContentTest {
    private val library = Fixtures.library

    @Test
    fun everyLevelHasFourStoriesTwoOfThemStretch() {
        for (level in 1..7) {
            val stories = library.stories(level)
            assertEquals("level $level", 4, stories.size)
            assertEquals("level $level", 2, stories.count { it.stretch })
        }
    }

    @Test
    fun everyLevelUpHasABigStoryWithNoBigWords() {
        for (level in 2..7) {
            val story = library.bigStory(level)!!
            assertFalse(story.stretch)
            assertTrue(story.sentences.all { sentence -> sentence.words.none { it.big } })
        }
    }

    @Test
    fun theFirstLevelHasNoBigStory() {
        assertNull(library.bigStory(1))
    }

    @Test
    fun regularStoriesCarryBigWords() {
        for (level in 1..7) {
            for (story in library.stories(level)) {
                assertTrue(story.id, story.sentences.any { sentence -> sentence.words.any { it.big } })
            }
        }
    }

    @Test
    fun storyIDsAreUnique() {
        val ids = library.all.map { it.id }
        assertEquals(ids.size, ids.toSet().size)
    }

    @Test
    fun theShelfStopsAtTheOnboardingLevelsAndLeavesOutBigStories() {
        val shelf = library.shelf(upTo = 3)
        assertEquals(12, shelf.size)
        assertTrue(shelf.all { it.level <= 3 && !it.isBigStory })
    }

    @Test
    fun aStoryOnlyNamesItsOwnLevelsFriend() {
        val names = Friend.entries.map { it.friendName }.toSet()
        for (story in library.all.filterNot { it.isBigStory && it.level == Levels.top }) {
            for (word in story.sentences.flatMap { it.words }.filter { it.text in names }) {
                assertEquals("${story.id} names ${word.text}", story.friend.friendName, word.text)
            }
        }
    }

    @Test
    fun eachStoryBelongsToItsLevelsFriend() {
        assertEquals(Friend.FROG, library["oggy-kite"]?.friend)
        assertEquals(Friend.GRASSHOPPER, library["bartholomew-big-story"]?.friend)
    }
}
