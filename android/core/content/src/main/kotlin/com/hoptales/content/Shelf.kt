package com.hoptales.content

data class StoryStanding(val story: Story, val standing: Standing) {
    sealed interface Standing {
        data object Unread : Standing

        data class InProgress(val remaining: Int) : Standing

        data object Finished : Standing
    }

    val subtitle: String
        get() {
            val sentences = "${story.sentences.size} sentences"
            return when (standing) {
                Standing.Unread -> sentences
                is Standing.InProgress -> "$sentences · ${standing.remaining} to go"
                Standing.Finished -> "$sentences · finished"
            }
        }

    val isCurrent: Boolean get() = standing is Standing.InProgress

    companion object {
        fun of(story: Story, progress: Progress): StoryStanding {
            val completed = progress.completedSentences[story.id] ?: 0
            val total = story.sentences.size
            val standing = when {
                completed >= total -> Standing.Finished
                completed > 0 -> Standing.InProgress(total - completed)
                else -> Standing.Unread
            }
            return StoryStanding(story, standing)
        }
    }
}

fun List<StoryStanding>.keepGoing(startingAt: String? = null): StoryStanding? = firstOrNull { it.isCurrent }
    ?: firstOrNull { it.story.id == startingAt && it.standing == StoryStanding.Standing.Unread }
    ?: firstOrNull { it.standing == StoryStanding.Standing.Unread }

fun Progress.shelf(library: StoryLibrary): List<StoryStanding> {
    val level = journey.activeFriend.level
    val stories = library.stories(level) + (level - 1 downTo 1).flatMap(library::stories)
    return stories.map { StoryStanding.of(it, this) }
}

fun Friend.startingStoryID(library: StoryLibrary): String = library.stories(level).firstOrNull()?.id ?: library.all.first().id

sealed interface JourneyStop {
    data object Met : JourneyStop

    data object Reading : JourneyStop

    data class Next(val bigStoryWaiting: Boolean) : JourneyStop

    data object Later : JourneyStop

    val isTappable: Boolean get() = this == Met || this == Next(bigStoryWaiting = true)
}

fun Journey.stop(friend: Friend, library: StoryLibrary): JourneyStop = when {
    friend == activeFriend -> JourneyStop.Reading
    friend in met -> JourneyStop.Met
    friend == nextFriend -> JourneyStop.Next(bigStoryWaiting = isPathFull(library))
    else -> JourneyStop.Later
}
