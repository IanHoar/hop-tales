package com.hoptales.reading

import com.hoptales.content.Friend
import com.hoptales.content.Sentence
import com.hoptales.content.Story
import com.hoptales.content.StoryEvent
import com.hoptales.content.StoryLibrary
import com.hoptales.content.StoryProps
import com.hoptales.content.Word
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import kotlin.math.abs

class StoryPropsTest {
    private val resources = File(System.getProperty("hoptales.resources"))
    private val library = StoryLibrary.decode(File(resources, "stories.json").readText())
    private val props = StoryProps.decode(File(resources, "props.json").readText())
    private val story = library["meadow-walk"]!!
    private val start = 0.0

    private val companion: PropKey
        get() {
            val sentence = story.sentences.indexOfFirst { sentence -> sentence.events.any { it.isCompanion } }
            return PropKey(sentence, story.sentences[sentence].events.indexOfFirst { it.isCompanion })
        }

    private val met: HopTarget get() = HopTarget(companion.sentence + 1, 0)

    @Test fun theMeadowWalksBugRunsAlongsideBob() {
        assertEquals("bug", story.sentences[companion.sentence].events[companion.index].prop)
    }

    @Test fun aCompanionNamedByItsSentencesLastWordArrivesAsTheNextBegins() {
        val cues = PropTiming.cues(emptyMap(), story, met, start)
        assertNotNull(cues[companion])
        assertNull(cues[companion]?.ended)
    }

    @Test fun aCompanionKeepsRunningThroughTheSentencesAfter() {
        var cues = PropTiming.cues(emptyMap(), story, met, start)
        val later = HopTarget(story.sentences.size - 1, 0)
        cues = PropTiming.cues(cues, story, later, start + 9)
        assertNull(cues[companion]?.ended)
    }

    @Test fun aCompanionDashesOffWhenTheStoryEnds() {
        var cues = PropTiming.cues(emptyMap(), story, met, start)
        val end = HopTarget(story.sentences.size, 0)
        cues = PropTiming.cues(cues, story, end, start + 5)
        assertEquals(start + 5, cues[companion]?.ended)
    }

    @Test fun theDashCarriesItPastTheTrailingEdge() {
        val width = 400f
        val running = PropPose.running(time = 5.0, exit = 0.0, width = width, unit = 1f)
        val gone = PropPose.running(time = 5.0, exit = 1.0, width = width, unit = 1f)
        assertTrue(running.flip)
        assertTrue(abs(running.dx) < 1)
        assertTrue(gone.dx >= width)
    }

    @Test fun aPropNamedByTheLastWordArrivesAsTheNextSentenceBegins() {
        val story = library["bob-bug"]!!
        val log = PropKey(0, 0)
        assertEquals("log", story.sentences[0].events[0].prop)
        var cues = PropTiming.cues(emptyMap(), story, HopTarget(1, 0), start)
        assertNotNull(cues[log])
        assertNull(cues[log]?.ended)
        cues = PropTiming.cues(cues, story, HopTarget(2, 0), start)
        assertEquals(start, cues[log]?.ended)
    }

    @Test fun aPropWaitsForItsWordAndTheSentenceStartWaitsLonger() {
        val story = Story(
            id = "s",
            title = "S",
            sentences = listOf(
                Sentence(
                    words = listOf(Word("a"), Word("b"), Word("c")),
                    events = listOf(StoryEvent("kite"), StoryEvent("bug", after = 1)),
                ),
            ),
        )
        val first = PropTiming.cues(emptyMap(), story, HopTarget(0, 0), start)
        assertEquals(PropTiming.SENTENCE_START, first[PropKey(0, 0)]?.revealed)
        assertNull(first[PropKey(0, 1)])
        val second = PropTiming.cues(first, story, HopTarget(0, 2), start + 3)
        assertEquals(PropTiming.SENTENCE_START, second[PropKey(0, 0)]?.revealed)
        assertEquals(start + 3 + PropTiming.AFTER_WORD, second[PropKey(0, 1)]?.revealed)
    }

    @Test fun aPropThatIsNotCarriedLeavesWithItsSentence() {
        val story = library["meadow-walk"]!!
        val butterfly = PropKey(1, 0)
        var cues = PropTiming.cues(emptyMap(), story, HopTarget(1, 0), start)
        assertNotNull(cues[butterfly])
        cues = PropTiming.cues(cues, story, HopTarget(2, 0), start + 4)
        assertEquals(start + 4, cues[butterfly]?.ended)
    }

    @Test fun theThoughtFloatsAboveTheHareAfterItsSentence() {
        val story = library["big-nap"]!!
        val layout = StoryPropLayout(Stage(), story.sentences, props, Friend.BUNNY)
        val items = layout.items(HopTarget(2, 0), cameraX = 0f, cues = emptyMap(), now = null)
        val bed = items.single { it.name == "bed" }
        assertTrue(bed.thought)
        assertEquals(96f + 46f, bed.anchor)
        assertEquals(600f - 124f - 12f, bed.baseline)
        assertFalse(items.any { it.name == "butterfly" })
    }

    @Test fun theCompanionRunsAheadOfTheHareFacingBack() {
        val layout = StoryPropLayout(Stage(), story.sentences, props, Friend.BUNNY)
        val bug = layout.items(HopTarget(3, 4), cameraX = 0f, cues = emptyMap(), now = null).single()
        assertTrue(bug.companion)
        assertEquals(96f + 70f, bug.anchor)
        assertEquals(600f + 28f, bug.baseline)
        assertTrue(PropPose.at(bug, elapsed = null, exit = 0.0, width = 400f, unit = 1f).flip)
    }

    @Test fun aPropRestsBesideTheWordAfterItsOwn() {
        val story = library["golden-hour"]!!
        val layout = StoryPropLayout(Stage(), story.sentences, props, Friend.HARE)
        assertTrue(layout.items(HopTarget(3, 1), cameraX = 0f, cues = emptyMap(), now = null).none { it.name == "thrush" })
        val thrush = layout.items(HopTarget(3, 2), cameraX = 100f, cues = emptyMap(), now = null).single { it.name == "thrush" }
        assertEquals(1000f * 3 + 2 + 48 - 100, thrush.anchor)
        assertEquals(500f, thrush.baseline)
    }

    @Test fun neighboursShuffleAlongTheGround() {
        val story = Story(
            id = "s",
            title = "S",
            sentences = listOf(
                Sentence(words = listOf(Word("a"), Word("b")), events = listOf(StoryEvent("log"), StoryEvent("stone"))),
            ),
        )
        val layout = StoryPropLayout(Stage(), story.sentences, props, Friend.HARE)
        val (log, stone) = layout.items(HopTarget(0, 0), cameraX = 0f, cues = emptyMap(), now = null)
        assertEquals(StoryPropLayout.PROP_GAP, stone.anchor - log.anchor)
    }

    @Test fun anEndedPropIsGoneOnceItsExitIsOver() {
        val story = library["bob-bug"]!!
        val layout = StoryPropLayout(Stage(), story.sentences, props, Friend.BUNNY)
        var cues = PropTiming.cues(emptyMap(), story, HopTarget(1, 0), start)
        cues = PropTiming.cues(cues, story, HopTarget(2, 0), start + 1)
        val leaving = layout.items(HopTarget(2, 0), 0f, cues, now = start + 1 + PropTiming.EXIT / 2)
        assertTrue(leaving.any { it.name == "log" })
        assertEquals(0.5, leaving.single { it.name == "log" }.exit(start + 1 + PropTiming.EXIT / 2), 1e-9)
        val gone = layout.items(HopTarget(2, 0), 0f, cues, now = start + 1 + PropTiming.EXIT + 0.01)
        assertFalse(gone.any { it.name == "log" })
    }

    @Test fun copiesStaggerTheirEntrances() {
        val item =
            PropItem("i", "bee", props.named("bee")!!, 26.0, copy = 2, copies = 3, seed = 0, anchor = 0f, baseline = 0f, cue = PropCue(1.0))
        assertEquals(1.0 - 2 * PropItem.COPY_STAGGER, item.elapsed(2.0)!!, 1e-9)
        assertEquals(1f, item.spread)
        assertEquals("cast-bee-2", item.art(2))
        assertEquals("cast-log", item.copy(name = "log", prop = props.named("log")!!).art(2))
    }

    @Test fun aWalkerArrivesAndStands() {
        val item = PropItem("i", "hen", props.named("hen")!!, 58.0, 0, 1, 0, 0f, 0f, PropCue(0.0))
        val arriving = PropPose.at(item, elapsed = 0.1, exit = 0.0, width = 400f, unit = 1f)
        val standing = PropPose.at(item, elapsed = 3.0, exit = 0.0, width = 400f, unit = 1f)
        assertTrue(arriving.dx > 200)
        assertEquals(0f, standing.dx)
        assertEquals(1, standing.frame)
        assertEquals(0f, PropPose.at(item, elapsed = -0.1, exit = 0.0, width = 400f, unit = 1f).opacity)
        assertEquals(0.5f, PropPose.at(item, elapsed = 3.0, exit = 0.5, width = 400f, unit = 1f).opacity)
    }

    @Test fun aFlierCrossesTheScreenAndIsGone() {
        val item = PropItem("i", "bee", props.named("bee")!!, 26.0, 0, 1, 0, 100f, 0f, PropCue(0.0))
        assertEquals(0f, PropPose.at(item, elapsed = 5.0, exit = 0.0, width = 400f, unit = 1f).opacity)
        assertTrue(PropPose.at(item, elapsed = 2.5, exit = 0.0, width = 400f, unit = 1f).opacity > 0.9f)
    }

    @Test fun aPopOvershootsThenSettles() {
        val item = PropItem("i", "log", props.named("log")!!, 44.0, 0, 1, 0, 0f, 0f, PropCue(0.0))
        assertTrue(PropPose.at(item, elapsed = 0.35, exit = 0.0, width = 400f, unit = 1f).scale > 1f)
        assertEquals(1f, PropPose.at(item, elapsed = 2.0, exit = 0.0, width = 400f, unit = 1f).scale, 1e-6f)
    }

    @Test fun aThoughtRisesAsItFades() {
        assertEquals(PropPose(), PropPose.thinking(time = null, exit = 0.0, unit = 1f))
        val leaving = PropPose.thinking(time = 2.0, exit = 1.0, unit = 1f)
        assertEquals(0f, leaving.opacity)
        assertTrue(leaving.dy < -15)
    }

    @Test fun everyPropHasItsArt() {
        val art = File(resources, "../../World/Resources").listFiles()!!.map { it.nameWithoutExtension }.toSet()
        for ((name, prop) in props.all) {
            val frames = if (prop.motion.frames == 2) listOf("cast-$name-1", "cast-$name-2") else listOf("cast-$name")
            for (frame in frames) assertTrue(frame, frame in art)
        }
    }

    private class Stage : PropStage {
        override val width = 400f
        override val hareX = 96f
        override val hareFeetY = 600f
        override val sittingHeight = 124f
        override val signFeetY = 500f
        override val wordY = 560f
        override val wordHeight = 50f

        override fun path(value: Float) = value

        override fun stopCentre(target: HopTarget) = 1000f * target.sentence + target.word
    }
}
