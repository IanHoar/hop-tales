package com.hoptales.content

import kotlinx.serialization.json.Json

class StoryLibrary(val all: List<Story>) {
    val levels: Levels by lazy { Levels(this) }

    operator fun get(id: String): Story? = all.firstOrNull { it.id == id }

    fun stories(level: Int): List<Story> = all.filter { it.level == level && !it.isBigStory }

    fun bigStory(level: Int): Story? = all.firstOrNull { it.level == level && it.isBigStory }

    fun shelf(upTo: Int): List<Story> = all.filter { it.level <= upTo && !it.isBigStory }

    companion object {
        val json = Json { ignoreUnknownKeys = true }

        fun decode(stories: String): StoryLibrary = StoryLibrary(json.decodeFromString(stories))
    }
}
