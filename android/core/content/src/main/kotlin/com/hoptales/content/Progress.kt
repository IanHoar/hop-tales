package com.hoptales.content

import kotlinx.serialization.Serializable

@Serializable
data class Progress(
    val stars: Int = 0,
    val completedSentences: Map<String, Int> = emptyMap(),
    val wordsRead: Map<String, Int> = emptyMap(),
) {
    fun isFinished(story: Story): Boolean = (completedSentences[story.id] ?: 0) >= story.sentences.size

    fun recording(storyID: String, sentences: Int, words: Int, newStars: Int): Progress = copy(
        stars = stars + newStars,
        completedSentences = completedSentences + (storyID to maxOf(completedSentences[storyID] ?: 0, sentences)),
        wordsRead = wordsRead + (storyID to maxOf(wordsRead[storyID] ?: 0, words)),
    )
}
