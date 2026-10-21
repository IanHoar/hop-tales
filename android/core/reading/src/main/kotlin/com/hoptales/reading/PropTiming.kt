package com.hoptales.reading

import com.hoptales.content.Sentence
import com.hoptales.content.Story
import com.hoptales.content.StoryEvent

data class HopTarget(val sentence: Int, val word: Int) : Comparable<HopTarget> {
    override fun compareTo(other: HopTarget): Int = compareValuesBy(this, other, { it.sentence }, { it.word })
}

data class PropKey(val sentence: Int, val index: Int)

data class PropCue(val revealed: Double, val ended: Double? = null)

object PropTiming {
    const val AFTER_WORD = 0.35
    const val SENTENCE_START = 0.9
    const val EXIT = 0.6
    const val DASH = 1.1

    fun cues(cues: Map<PropKey, PropCue>, story: Story, position: HopTarget, now: Double): Map<PropKey, PropCue> {
        val next = cues.filterKeys { it.sentence <= position.sentence }.toMutableMap()
        for ((key, cue) in next.entries.toList()) {
            if (key.sentence >= position.sentence || cue.ended != null || lingers(key, story, position)) continue
            next[key] = cue.copy(ended = now)
        }
        for ((sentenceIndex, sentence) in story.sentences.take(position.sentence).withIndex()) {
            for (index in sentence.events.indices) {
                val key = PropKey(sentenceIndex, index)
                if (key in next || !lingers(key, story, position)) continue
                next[key] = PropCue(now + AFTER_WORD)
            }
        }
        val sentence = story.sentences.getOrNull(position.sentence) ?: return next
        for ((index, event) in sentence.events.withIndex()) {
            if (!shows(event, position.word)) continue
            val key = PropKey(position.sentence, index)
            if (key in next) continue
            next[key] = PropCue(now + if (event.after == null) SENTENCE_START else AFTER_WORD)
        }
        return next
    }

    fun lingers(key: PropKey, story: Story, position: HopTarget): Boolean {
        if (position.sentence >= story.sentences.size) return false
        val sentence = story.sentences.getOrNull(key.sentence) ?: return false
        val event = sentence.events.getOrNull(key.index) ?: return false
        if (event.isCompanion) return true
        return key.sentence == position.sentence - 1 && carries(event, sentence)
    }

    fun carries(event: StoryEvent, sentence: Sentence): Boolean = event.after == sentence.words.size - 1

    fun shows(event: StoryEvent, word: Int): Boolean = event.after?.let { it < word } ?: true
}
