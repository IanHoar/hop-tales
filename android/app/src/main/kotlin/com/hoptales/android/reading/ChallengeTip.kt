package com.hoptales.android.reading

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.Star
import com.hoptales.android.design.paperChip
import com.hoptales.reading.HopTarget
import kotlin.math.abs
import kotlin.math.max

data class ChallengeTipState(val target: HopTarget, val id: Long)

enum class WordPress { TAP, LONG_PRESS }

sealed interface WordResponse {
    data object Hear : WordResponse

    data class Explain(val target: HopTarget) : WordResponse
}

object ChallengeTip {
    const val HOLD_MILLIS = 4_000L
    const val SHOW_MILLIS = 200
    const val HIDE_MILLIS = 300
    const val FROM_SCALE = 0.9f
    const val LONG_PRESS_MILLIS = 500L
    const val TITLE = "Challenge word"
    const val DETAIL = "A word from a level or two ahead, worth 5 steps instead of 1."
    const val WIDTH = 250f
    const val INSET = 16f
    const val ABOVE_WORD = 40f
    const val MINIMUM_TARGET = 44f
    const val MARGIN = 200f

    fun respond(press: WordPress, target: HopTarget, position: HopTarget, isChallenge: Boolean): WordResponse? = when {
        target == position && press == WordPress.LONG_PRESS && isChallenge -> WordResponse.Explain(target)
        target == position -> WordResponse.Hear
        isChallenge && press == WordPress.TAP -> WordResponse.Explain(target)
        else -> null
    }

    fun hits(offset: Offset, centre: Offset, width: Float, height: Float, minimum: Float, isCurrent: Boolean): Boolean {
        val across = max(minimum, width) / 2
        val down = (if (isCurrent) max(minimum, height) else height) / 2
        return abs(offset.x - centre.x) <= across && abs(offset.y - centre.y) <= down
    }

    fun x(wordX: Float, screenWidth: Float, geometry: PathGeometry): Float {
        val half = geometry.path(WIDTH / 2)
        val inset = geometry.path(INSET)
        return wordX.coerceIn(half + inset, maxOf(half + inset, screenWidth - half - inset))
    }
}

fun WordPath.pressed(offset: Offset, cameraX: Float, position: HopTarget, isChallenge: (HopTarget) -> Boolean): HopTarget? {
    val minimum = geometry.path(ChallengeTip.MINIMUM_TARGET)
    stop(position.sentence, position.word)?.let { stop ->
        val centre = Offset(stop.centre - cameraX, wordCentreY(stop))
        if (ChallengeTip.hits(offset, centre, stop.width, stop.layout.size.height.toFloat(), minimum, isCurrent = true)) return position
    }
    val margin = geometry.path(ChallengeTip.MARGIN)
    return stops.firstOrNull { stop ->
        val target = HopTarget(stop.sentence, stop.word)
        val x = stop.centre - cameraX
        target != position && isChallenge(target) && x > -margin && x < geometry.width + margin &&
            ChallengeTip.hits(
                offset,
                Offset(x, wordCentreY(stop)),
                stop.width,
                stop.layout.size.height.toFloat(),
                minimum,
                isCurrent = false,
            )
    }?.let { HopTarget(it.sentence, it.word) }
}

@Composable
fun ChallengeTipCard(geometry: PathGeometry, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val density = LocalDensity.current
    fun dp(value: Float): Dp = with(density) { geometry.path(value).toDp() }
    val star = remember { Star() }
    Column(
        modifier
            .width(dp(ChallengeTip.WIDTH))
            .paperChip(RoundedCornerShape(dp(16f)), rim = dp(3f))
            .padding(horizontal = dp(14f), vertical = dp(10f))
            .clearAndSetSemantics {
                contentDescription = "${ChallengeTip.TITLE}. ${ChallengeTip.DETAIL}"
                liveRegion = LiveRegionMode.Polite
            },
        verticalArrangement = Arrangement.spacedBy(dp(4f)),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(dp(6f))) {
            Canvas(Modifier.size(dp(13f))) {
                drawOutline(star.createOutline(size, layoutDirection, this), palette.gold)
            }
            Text(ChallengeTip.TITLE, style = type.display(dp(17f).value.sp), color = paper.ink)
        }
        Text(ChallengeTip.DETAIL, style = type.ui(geometry.sp(14f), FontWeight.Medium), color = paper.ink.copy(alpha = 0.85f))
    }
}
