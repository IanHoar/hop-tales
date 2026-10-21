package com.hoptales.content

import java.io.File

object Fixtures {
    private fun resource(name: String) = File(System.getProperty("hoptales.resources"), name).readText()

    val library: StoryLibrary by lazy { StoryLibrary.decode(resource("stories.json")) }

    val wardrobe: WardrobeLibrary by lazy { WardrobeLibrary.decode(resource("wardrobe.json"), resource("looks.json")) }

    val everyLookPainted: WardrobeLibrary by lazy {
        WardrobeLibrary(wardrobe.all, WardrobeLibrary.wearable.mapValues { it.value.toSet() })
    }

    val noLooksPainted: WardrobeLibrary by lazy { WardrobeLibrary(wardrobe.all, emptyMap()) }
}
