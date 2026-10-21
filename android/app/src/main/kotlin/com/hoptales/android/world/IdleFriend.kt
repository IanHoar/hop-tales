package com.hoptales.android.world

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import com.hoptales.android.design.rememberReducedMotion
import com.hoptales.content.Friend
import kotlin.math.roundToInt

data class IdlePose(val frame: Int, val scaleX: Float, val scaleY: Float) {
    companion object {
        val resting = IdlePose(IdleMotion.REST, 1f, 1f)

        fun at(time: Double, still: Boolean): IdlePose {
            if (still) return resting
            val (x, y) = IdleMotion.breathing(time)
            return IdlePose(IdleMotion.frame(time), x, y)
        }
    }
}

@Composable
fun IdleFriend(friend: Friend, look: String?, height: Dp, modifier: Modifier = Modifier, shadow: Color? = null) {
    val assets = LocalContext.current.assets
    val still = rememberReducedMotion()
    val sheets = HareSheets.of(friend)
    val sheet = sheets.idle
    val image = remember(friend, look) {
        look?.let { Art.image(assets, sheets.dressed(friend, it, HareSheet.IDLE)) } ?: Art.image(assets, sheet.asset)
    }
    var time by remember { mutableDoubleStateOf(System.nanoTime() / 1e9) }
    LaunchedEffect(still) {
        if (still) return@LaunchedEffect
        while (true) withFrameNanos { time = it / 1e9 }
    }
    val width = height / HareSheet.REST_HEIGHT * sheet.scale * sheet.cellWidth.toFloat()
    val draw: DrawScope.(ColorFilter?) -> Unit = draw@{ filter ->
        val art = image ?: return@draw
        val pose = IdlePose.at(time, still)
        val scale = size.height / HareSheet.REST_HEIGHT * sheet.scale
        val drawn = IntSize((sheet.cellWidth * scale * pose.scaleX).roundToInt(), (sheet.cellHeight * scale * pose.scaleY).roundToInt())
        drawImage(
            art,
            srcOffset = IntOffset(pose.frame.coerceIn(0, sheet.frames - 1) * sheet.cellWidth, 0),
            srcSize = IntSize(sheet.cellWidth, sheet.cellHeight),
            dstOffset = IntOffset(
                (size.width / 2 - drawn.width * sheet.anchorX).roundToInt(),
                (size.height - drawn.height * sheet.anchorY).roundToInt(),
            ),
            dstSize = drawn,
            colorFilter = filter,
            filterQuality = FilterQuality.Medium,
        )
    }
    Box(modifier.size(width, height)) {
        if (shadow != null) {
            Canvas(
                Modifier.matchParentSize().graphicsLayer {
                    translationY = SHADOW_DROP.toPx()
                    val blur = SHADOW_BLUR.toPx()
                    renderEffect = BlurEffect(blur, blur, TileMode.Decal)
                },
            ) { draw(ColorFilter.tint(shadow, BlendMode.SrcIn)) }
        }
        Canvas(Modifier.matchParentSize()) { draw(null) }
    }
}

private val SHADOW_DROP = 4.dp
private val SHADOW_BLUR = 6.dp
