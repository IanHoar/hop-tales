package com.hoptales.content

fun Progress.hasFinishedLevelOne(library: StoryLibrary): Boolean = library.stories(Plus.FREE_LEVEL).all(::isFinished)

fun Progress.celebratingLevelOne(
    story: Story,
    moments: List<JourneyMoment>,
    library: StoryLibrary,
    isPlus: Boolean,
    locksStories: Boolean,
): Recorded<Progress> {
    if (!locksStories || isPlus || levelOneCelebrated || !story.isFree || story.isBigStory || !hasFinishedLevelOne(library)) {
        return Recorded(this, moments)
    }
    val kept = moments.filterNot { it is JourneyMoment.BigStoryReady }
    val at = kept.indexOfFirst { it.isCallout }.let { if (it < 0) kept.size else it }
    return Recorded(copy(levelOneCelebrated = true), kept.take(at) + JourneyMoment.LevelOneFinished + kept.drop(at))
}
