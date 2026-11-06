package com.hoptales.content

data class PlusWelcome(val story: Story, val friend: Friend, val meetsFriend: Boolean)

sealed interface LevelStanding {
    data object Locked : LevelStanding

    data class Ready(val story: Story) : LevelStanding

    data object Ahead : LevelStanding
}

fun Progress.plusWelcome(library: StoryLibrary): PlusWelcome? {
    val next = shelf(library).keepGoing(journey.activeFriend.startingStoryID(library))
    val friend = journey.nextFriend ?: return next?.let { PlusWelcome(it.story, it.story.friend, meetsFriend = false) }
    journey.bigStory(library)?.let { return PlusWelcome(it, friend, meetsFriend = true) }
    return next?.let { PlusWelcome(it.story, friend, meetsFriend = false) }
}

fun Progress.bigStoryWaiting(library: StoryLibrary, isPlus: Boolean, locksStories: Boolean): Story? =
    journey.bigStory(library)?.takeUnless { Plus.isLocked(it, isPlus, locksStories) }

fun Progress.nextLevels(library: StoryLibrary, isPlus: Boolean, locksStories: Boolean): List<Friend> =
    Plus.lockedLevels(journey.activeFriend.level, library, isPlus, locksStories)
        .ifEmpty { Plus.levels(journey.level, library) }

fun Progress.levelStanding(friend: Friend, library: StoryLibrary, isPlus: Boolean, locksStories: Boolean): LevelStanding {
    if (friend in Plus.lockedLevels(journey.activeFriend.level, library, isPlus, locksStories)) return LevelStanding.Locked
    val waiting = bigStoryWaiting(library, isPlus, locksStories)
    if (friend == journey.nextFriend && waiting != null) return LevelStanding.Ready(waiting)
    return LevelStanding.Ahead
}
