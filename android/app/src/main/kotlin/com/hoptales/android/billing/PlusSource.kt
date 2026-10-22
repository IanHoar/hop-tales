package com.hoptales.android.billing

import com.hoptales.android.BuildConfig
import com.hoptales.content.Plus
import com.hoptales.content.Story
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

interface PlusSource {
    val isPlus: StateFlow<Boolean>

    fun refresh()

    fun isLocked(story: Story): Boolean = Plus.isLocked(story, isPlus.value, BuildConfig.PLUS_LOCKS_STORIES)
}

class FakePlusSource(isPlus: Boolean = false) : PlusSource {
    override val isPlus = MutableStateFlow(isPlus)

    var refreshes = 0
        private set

    override fun refresh() {
        refreshes += 1
    }
}
