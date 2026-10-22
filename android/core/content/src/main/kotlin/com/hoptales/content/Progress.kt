package com.hoptales.content

import kotlinx.serialization.Serializable

@Serializable
data class Progress(
    val stars: Int = 0,
    val completedSentences: Map<String, Int> = emptyMap(),
    val wordsRead: Map<String, Int> = emptyMap(),
    val journey: Journey = Journey(),
    val baskets: Map<Friend, Basket> = emptyMap(),
    val outfits: Map<Friend, Map<Slot, String>> = emptyMap(),
    val levelOneCelebrated: Boolean = false,
) {
    fun isFinished(story: Story): Boolean = (completedSentences[story.id] ?: 0) >= story.sentences.size

    fun recording(storyID: String, sentences: Int, words: Int, newStars: Int): Progress = copy(
        stars = stars + newStars,
        completedSentences = completedSentences + (storyID to maxOf(completedSentences[storyID] ?: 0, sentences)),
        wordsRead = wordsRead + (storyID to maxOf(wordsRead[storyID] ?: 0, words)),
    )

    fun restoringStoriesRead(library: StoryLibrary): Progress {
        if (journey.storiesRead.isNotEmpty()) return this
        val finished = library.stories(journey.level).filter(::isFinished).map { it.id }.toSet()
        return copy(journey = journey.copy(storiesRead = finished))
    }
}
