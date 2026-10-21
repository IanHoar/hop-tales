package com.hoptales.android.world

import com.hoptales.content.Friend

enum class HareSheet(val frames: Int) {
    IDLE(10),
    HOP(8),
    ;

    companion object {
        const val REST_HEIGHT = 345f
    }
}

data class SpriteSheet(
    val asset: String,
    val cellWidth: Int,
    val cellHeight: Int,
    val feetX: Float,
    val feetY: Float,
    val scale: Float,
    val frames: Int,
) {
    val anchorX: Float get() = feetX / cellWidth
    val anchorY: Float get() = feetY / cellHeight

    companion object {
        fun idle(asset: String, cell: Pair<Int, Int>, feet: Pair<Float, Float>, size: Float = 1f) =
            SpriteSheet(asset, cell.first, cell.second, feet.first, feet.second, size, HareSheet.IDLE.frames)

        fun hop(asset: String, cell: Pair<Int, Int>, feet: Pair<Float, Float>, standing: Float, size: Float = 1f) =
            SpriteSheet(asset, cell.first, cell.second, feet.first, feet.second, HareSheet.REST_HEIGHT / standing * size, HareSheet.HOP.frames)
    }
}

data class HareSheets(val idle: SpriteSheet, val hop: SpriteSheet) {
    fun of(sheet: HareSheet): SpriteSheet = if (sheet == HareSheet.IDLE) idle else hop

    companion object {
        val hare = HareSheets(
            SpriteSheet.idle("hare-idle-frames", 260 to 373, 142f to 361f),
            SpriteSheet.hop("hare-hop", 363 to 346, 194f to 334f, standing = 322f),
        )

        private val sheets = mapOf(
            Friend.BUNNY to HareSheets(
                SpriteSheet.idle("bunny-idle-frames", 322 to 369, 158f to 357f),
                SpriteSheet.hop("bunny-hop", 370 to 346, 175f to 335f, standing = 323f),
            ),
            Friend.FROG to HareSheets(
                SpriteSheet.idle("frog-idle-frames", 467 to 436, 228f to 420f),
                SpriteSheet.hop("frog-hop", 424 to 376, 220f to 365f, standing = 242f),
            ),
            Friend.CRAB to HareSheets(
                SpriteSheet.idle("crab-idle-frames", 621 to 517, 305f to 496f, size = 0.75f),
                SpriteSheet.hop("crab-hop", 540 to 456, 270f to 440f, standing = 262f, size = 0.75f),
            ),
            Friend.CROW to HareSheets(
                SpriteSheet.idle("crow-idle-frames", 430 to 409, 235f to 397f),
                SpriteSheet.hop("crow-hop", 366 to 376, 181f to 367f, standing = 259f),
            ),
            Friend.CAT to HareSheets(
                SpriteSheet.idle("cat-idle-frames", 321 to 400, 156f to 389f),
                SpriteSheet.hop("cat-hop", 450 to 376, 196f to 365f, standing = 305f),
            ),
            Friend.GRASSHOPPER to HareSheets(
                SpriteSheet.idle("grasshopper-idle-frames", 592 to 420, 255f to 403f),
                SpriteSheet.hop("grasshopper-hop", 421 to 406, 187f to 396f, standing = 166f),
            ),
        )

        fun of(friend: Friend): HareSheets = sheets[friend] ?: hare
    }
}

data class HareFrame(val sheet: HareSheet, val index: Int) {
    companion object {
        val rest = HareFrame(HareSheet.IDLE, 0)
    }
}
