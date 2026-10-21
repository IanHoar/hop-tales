package com.hoptales.android.world

import com.hoptales.content.Friend

data class WorldStyle(val feetAbovePath: Float? = null, val chalk: Boolean = false) {
    companion object {
        val meadow = WorldStyle()

        fun of(world: Friend): WorldStyle = when (world) {
            Friend.CROW -> WorldStyle(feetAbovePath = 170f, chalk = true)
            Friend.CAT -> WorldStyle(feetAbovePath = 170f)
            else -> meadow
        }
    }
}
