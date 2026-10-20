package com.hoptales.android.world

import com.hoptales.content.Friend

data class SpriteSheet(val asset: String, val cellWidth: Int, val cellHeight: Int, val feetX: Float, val feetY: Float, val frames: Int)

data class HareSheets(val idle: SpriteSheet, val hop: SpriteSheet) {
    companion object {
        const val FPS = 14f
        const val IDLE_FRAMES = 10
        const val HOP_FRAMES = 8

        private fun pair(idle: String, idleCell: Pair<Int, Int>, idleFeet: Pair<Float, Float>, hop: String, hopCell: Pair<Int, Int>, hopFeet: Pair<Float, Float>) =
            HareSheets(
                SpriteSheet(idle, idleCell.first, idleCell.second, idleFeet.first, idleFeet.second, IDLE_FRAMES),
                SpriteSheet(hop, hopCell.first, hopCell.second, hopFeet.first, hopFeet.second, HOP_FRAMES),
            )

        val hare = pair("hare-idle-frames", 260 to 373, 142f to 361f, "hare-hop", 363 to 346, 194f to 334f)
        val bunny = pair("bunny-idle-frames", 322 to 369, 158f to 357f, "bunny-hop", 370 to 346, 194f to 334f)

        fun of(friend: Friend): HareSheets = when (friend) {
            Friend.BUNNY -> bunny
            else -> hare
        }
    }
}
