package com.hoptales.android.reading

import android.content.res.AssetManager
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.StrokeCap
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
    const val PICKUP_DELAY_MILLIS = 6_000L / 24
    const val BASKET_HOLD_MILLIS = 1_800L
    val wash = Color(0xFFF7D774)
}

fun DrawScope.drawBigWords(path: WordPath, art: MarkArt, cameraX: Float, state: ReadingState) {
    if (state.bigWords.isEmpty()) return
    val position = HopTarget(state.sentenceIndex, state.wordIndex)
    val size = path.geometry.path(PathGeometry.WORD_SIZE)
    for (stop in path.stops) {
        if (!state.isBig(stop.sentence, stop.word)) continue
        val x = stop.centre - cameraX
        if (x + stop.width < 0 || x - stop.width > this.size.width) continue
        val top = path.wordCentreY(stop) - stop.layout.size.height / 2
        val bottom = top + stop.layout.size.height
        val read = HopTarget(stop.sentence, stop.word) < position
        val dot = size * 0.07f
        val underline = bottom - size * 0.12f
        var dotX = x - stop.width / 2 + size * 0.05f
        while (dotX <= x + stop.width / 2 - size * 0.05f) {
            drawLine(PathMarks.wash, Offset(dotX, underline), Offset(dotX + 1, underline), strokeWidth = dot, cap = StrokeCap.Round)
            dotX += size * 0.16f + dot
        }
        val star = art.star ?: continue
        if (read) continue
        val height = size * 0.42f
        val width = height * star.width / star.height
        drawImage(
            star,
            dstOffset = IntOffset((x - width / 2).roundToInt(), (top - size * 0.5f).roundToInt()),
            dstSize = IntSize(width.roundToInt(), height.roundToInt()),
            filterQuality = FilterQuality.Medium,
        )
    }
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
