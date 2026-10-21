package com.hoptales.reading

import com.hoptales.content.Friend
import com.hoptales.content.Sentence
import com.hoptales.content.StoryEvent
import com.hoptales.content.StoryProp
import com.hoptales.content.StoryProps

interface PropStage {
    val width: Float
    val hareX: Float
    val hareFeetY: Float
    val sittingHeight: Float
    val signFeetY: Float
    val wordY: Float
    val wordHeight: Float

    fun path(value: Float): Float

    fun stopCentre(target: HopTarget): Float?
}

data class PropItem(
    val id: String,
    val name: String,
    val prop: StoryProp,
    val height: Double,
    val copy: Int,
    val copies: Int,
    val seed: Int,
    val anchor: Float,
    val baseline: Float,
    val cue: PropCue?,
    val companion: Boolean = false,
    val thought: Boolean = false,
) {
    val spread: Float get() = copy - (copies - 1) / 2f

    fun elapsed(now: Double?): Double? {
        if (now == null || cue == null) return null
        return now - cue.revealed - copy * COPY_STAGGER
    }

    fun exit(now: Double?): Double {
        val ended = cue?.ended
        if (now == null || ended == null) return 0.0
        val duration = if (companion) PropTiming.DASH else PropTiming.EXIT
        return ((now - ended) / duration).coerceIn(0.0, 1.0)
    }

    fun art(frame: Int): String = if (prop.motion.frames == 2) "cast-$name-$frame" else "cast-$name"

    companion object {
        const val COPY_STAGGER = 0.25
    }
}

class StoryPropLayout(
    private val stage: PropStage,
    private val sentences: List<Sentence>,
    private val props: StoryProps,
    private val world: Friend,
) {
    fun items(position: HopTarget, cameraX: Float, cues: Map<PropKey, PropCue>, now: Double?): List<PropItem> {
        val items = mutableListOf<PropItem>()
        for ((sentenceIndex, sentence) in sentences.withIndex()) {
            for ((index, event) in sentence.events.withIndex()) {
                val prop = props.named(event.prop) ?: continue
                val key = PropKey(sentenceIndex, index)
                val cue: PropCue?
                if (now == null) {
                    if (!stillShows(event, sentenceIndex, position)) continue
                    cue = null
                } else {
                    val found = cues[key] ?: continue
                    val exit = if (event.isCompanion) PropTiming.DASH else PropTiming.EXIT
                    val ended = found.ended
                    if (ended != null && now - ended > exit) continue
                    cue = found
                }
                val copies = maxOf(1, event.count)
                val height = prop.height(world)
                for (copy in 0 until copies) {
                    items += PropItem(
                        id = "$sentenceIndex-$index-$copy",
                        name = event.prop,
                        prop = prop,
                        height = height,
                        copy = copy,
                        copies = copies,
                        seed = sentenceIndex * 7 + index * 3 + copy,
                        anchor = anchor(sentenceIndex, event, position, cameraX),
                        baseline = baseline(event, height),
                        cue = cue,
                        companion = event.isCompanion,
                        thought = event.isThought,
                    )
                }
            }
        }
        return items
    }

    fun stillShows(event: StoryEvent, sentence: Int, position: HopTarget): Boolean {
        if (sentence >= position.sentence) {
            return sentence == position.sentence && PropTiming.shows(event, position.word)
        }
        if (position.sentence >= sentences.size) return false
        return event.isCompanion ||
            (sentence == position.sentence - 1 && PropTiming.carries(event, sentences[sentence]))
    }

    fun anchor(sentence: Int, event: StoryEvent, position: HopTarget, cameraX: Float): Float {
        if (event.isCompanion) return stage.hareX + stage.path(COMPANION_LEAD)
        if (event.isThought) return stage.hareX + stage.path(THOUGHT_LEAD)
        if (sentence < position.sentence && PropTiming.carries(event, sentences[sentence])) {
            return stage.hareX + stage.path(CARRIED_LEAD)
        }
        val words = sentences[sentence].words.size
        val word = minOf((event.after ?: -1) + 1, words - 1)
        val centre = stage.stopCentre(HopTarget(sentence, word)) ?: return stage.width * 0.7f
        val gap = PROP_GAP * neighbours(event, sentence)
        return centre + stage.path(48 + gap) - cameraX
    }

    private fun neighbours(event: StoryEvent, sentence: Int): Int {
        val events = sentences[sentence].events
        val index = events.indexOf(event)
        if (index < 0) return 0
        return events.take(index).count {
            it.after == event.after && props.place(it) == props.place(event) && !it.isCompanion && !it.isThought
        }
    }

    fun baseline(event: StoryEvent, height: Double): Float {
        if (event.isCompanion) return stage.hareFeetY + stage.path(COMPANION_DROP)
        if (event.isThought) return stage.hareFeetY - stage.sittingHeight - stage.path(THOUGHT_LIFT)
        return when (props.place(event)) {
            StoryEvent.Place.GROUND -> stage.signFeetY
            StoryEvent.Place.NEAR -> stage.wordY + stage.wordHeight / 2 + stage.path(10 + height.toFloat())
            StoryEvent.Place.SKY -> stage.signFeetY - stage.path(300f)
        }
    }

    companion object {
        const val COMPANION_LEAD = 70f
        const val COMPANION_DROP = 28f
        const val THOUGHT_LEAD = 46f
        const val THOUGHT_LIFT = 12f
        const val CARRIED_LEAD = 84f
        const val PROP_GAP = 64f
    }
}
