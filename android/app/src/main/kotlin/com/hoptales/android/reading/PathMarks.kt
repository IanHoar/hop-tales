package com.hoptales.android.reading

import android.content.res.AssetManager
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import com.hoptales.android.world.Art
import com.hoptales.content.StoryTreat
import com.hoptales.reading.HopTarget
import com.hoptales.reading.ReadingState
import kotlin.math.roundToInt

class MarkArt(val star: ImageBitmap?, val treat: ImageBitmap?) {
    companion object {
        fun load(assets: AssetManager, treat: StoryTreat?): MarkArt = MarkArt(
            star = Art.image(assets, "collect-star"),
            treat = treat?.let { Art.image(assets, "collect-${it.friend.treat.art}") },
        )
    }
}

object PathMarks {
    const val BIG_WORD_LIFT = 1.4f
    const val TREAT_BEFORE_WORD = 128f
    const val TREAT_HEIGHT = 44f
    const val PICKUP_FRAMES = 6
    const val PICKUP_DELAY = PICKUP_FRAMES / HareMotion.FPS
    const val PICKUP_TILT = -24f
    const val PICKUP_SHRINK = 0.6f
    const val FLIGHT_SECONDS = 0.6
    const val FLIGHT_BOUNCE = 0.25
    const val CHIP_DELAY = 0.5
    const val CHIP_SECONDS = 0.2
    const val CHIP_FROM = 0.8f
    const val BASKET_HOLD = 1.2
    const val HIDE_AFTER = FLIGHT_SECONDS + BASKET_HOLD
    const val HIDE_SECONDS = 0.4
    const val CHIP_X_FROM_RIGHT = 92f
    const val CHIP_Y = 96f
    const val PICKUP_X = PathGeometry.HARE_X + 12f
    const val PICKUP_BELOW_PATH = PathGeometry.HARE_FEET_BELOW_PATH + 4f
    val wash = Color(0xFFF7D774)
}

data class PickupFrame(val x: Float, val y: Float, val rotation: Float, val scale: Float, val alpha: Float)

object Pickup {
    fun frame(start: Offset, chip: Offset, landed: Float): PickupFrame = PickupFrame(
        x = start.x + (chip.x - start.x) * landed,
        y = start.y + (chip.y - start.y) * landed,
        rotation = PathMarks.PICKUP_TILT - PathMarks.PICKUP_TILT * landed,
        scale = 1 + (PathMarks.PICKUP_SHRINK - 1) * landed,
        alpha = (1 - landed).coerceIn(0f, 1f),
    )

    fun start(geometry: PathGeometry): Offset =
        Offset(geometry.path(PathMarks.PICKUP_X), geometry.pathCentre + geometry.path(PathMarks.PICKUP_BELOW_PATH))

    fun chip(geometry: PathGeometry): Offset =
        Offset(geometry.width - geometry.path(PathMarks.CHIP_X_FROM_RIGHT), geometry.y(PathMarks.CHIP_Y))

    fun passed(treat: StoryTreat?, from: HopTarget, to: HopTarget): StoryTreat? =
        treat?.takeIf { to > from && it.word.sentence == from.sentence && it.word.word == from.word }
}

fun DrawScope.drawTreatOnPath(path: WordPath, art: MarkArt, cameraX: Float, state: ReadingState, tint: Color) {
    val treat = state.treat ?: return
    val image = art.treat ?: return
    if (HopTarget(state.sentenceIndex, state.wordIndex) > HopTarget(treat.word.sentence, treat.word.word)) return
    val next = path.stop(treat.word.sentence, treat.word.word + 1) ?: return
    val height = path.geometry.path(PathMarks.TREAT_HEIGHT)
    val width = height * image.width / image.height
    val centre = Offset(next.centre - cameraX - path.geometry.path(PathMarks.TREAT_BEFORE_WORD), path.hareFeetY + path.geometry.path(4f))
    withTransform({ rotate(-24f, centre) }) {
        drawImage(
            image,
            dstOffset = IntOffset((centre.x - width / 2).roundToInt(), (centre.y - height / 2).roundToInt()),
            dstSize = IntSize(width.roundToInt(), height.roundToInt()),
            colorFilter = if (tint == Color.White) null else ColorFilter.tint(tint, BlendMode.Modulate),
            filterQuality = FilterQuality.Medium,
        )
    }
}
