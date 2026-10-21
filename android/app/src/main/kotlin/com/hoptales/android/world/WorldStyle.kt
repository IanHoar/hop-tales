package com.hoptales.android.world

import androidx.compose.ui.graphics.Color
import com.hoptales.content.Friend

data class WorldStyle(val feetAbovePath: Float? = null, val chalk: Boolean = false, val ground: Color = Color(0xFFB7BF7B)) {
    companion object {
        val meadow = WorldStyle()

        fun of(world: Friend): WorldStyle = when (world) {
            Friend.BUNNY -> WorldStyle(ground = Color(0xFF919670))
            Friend.FROG -> WorldStyle(ground = Color(0xFFB6AE66))
            Friend.CRAB -> WorldStyle(ground = Color(0xFFD4AF6F))
            Friend.GRASSHOPPER -> WorldStyle(ground = Color(0xFFC0B66D))
            Friend.CROW -> WorldStyle(feetAbovePath = 170f, chalk = true, ground = Color(0xFFB1934A))
            Friend.CAT -> WorldStyle(feetAbovePath = 170f, ground = Color(0xFFBFB46A))
            else -> meadow
        }
    }
}
