package com.hoptales.content

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class StoryEventTest {
    private val resources = File(System.getProperty("hoptales.resources"))
    private val library = StoryLibrary.decode(File(resources, "stories.json").readText())
    private val props = StoryProps.decode(File(resources, "props.json").readText())

    @Test
    fun everyEventNamesAKnownProp() {
        for (story in library.all) {
            for (event in story.sentences.flatMap { it.events }) {
                assertNotNull("${story.id}: ${event.prop}", props.named(event.prop))
            }
        }
    }

    @Test
    fun everyStoryHasAtLeastTwoMoments() {
        for (story in library.all) {
            val events = story.sentences.sumOf { it.events.size }
            val moods = story.sentences.count { it.sky != null || it.weather != null }
            assertTrue(story.id, events + moods >= 2)
        }
    }

    @Test
    fun aPropComesAfterItsWordAndNeverNamesAWordItAppearsBefore() {
        for (story in library.all) {
            for (sentence in story.sentences) {
                val words = sentence.words.map { it.text.lowercase() }
                for (event in sentence.events) {
                    val after = event.after
                    if (after != null) {
                        assertTrue("${story.id}: ${event.prop}", after in words.indices)
                    } else {
                        assertFalse("${story.id}: ${event.prop} gives it away", event.prop in words)
                    }
                }
            }
        }
    }

    @Test
    fun aSentenceWithoutEventsDecodesFromOlderJson() {
        val json = """{"words": [{"text": "sun", "homophones": [], "big": false}]}"""
        assertTrue(StoryLibrary.json.decodeFromString<Sentence>(json).events.isEmpty())
    }

    @Test
    fun anEventTakesItsPlaceFromThePropUnlessItNamesOne() {
        assertEquals(StoryEvent.Place.SKY, props.place(StoryEvent("butterfly")))
        assertEquals(StoryEvent.Place.GROUND, props.place(StoryEvent("butterfly", place = StoryEvent.Place.GROUND)))
        assertEquals(StoryEvent.Place.GROUND, props.place(StoryEvent("unknown")))
    }

    @Test
    fun stickersGrowWithTheWorldUpToTheLargest() {
        val bug = props.named("bug")!!
        assertEquals(24.0, bug.height(Friend.HARE), 0.0)
        assertEquals(96.0, bug.height(Friend.GRASSHOPPER), 0.0)
        assertEquals(StoryProp.LARGEST, props.named("sunflower")!!.height(Friend.GRASSHOPPER), 0.0)
        assertEquals(160.0, props.named("lighthouse")!!.height(Friend.GRASSHOPPER), 0.0)
    }
}
