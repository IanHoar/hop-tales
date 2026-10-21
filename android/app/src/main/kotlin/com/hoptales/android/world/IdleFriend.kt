package com.hoptales.android.world

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
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
fun IdleFriend(friend: Friend, look: String?, height: Dp, modifier: Modifier = Modifier) {
    val assets = LocalContext.current.assets
    val still = rememberReducedMotion()
    val sheets = HareSheets.of(friend)
    val sheet = sheets.idle
    val image = remember(friend, look) {
        look?.let { Art.image(assets, sheets.dressed(friend, it, HareSheet.IDLE)) } ?: Art.image(assets, sheet.asset)
    }
    var time by remember { mutableDoubleStateOf(0.0) }
    LaunchedEffect(still) {
        if (still) return@LaunchedEffect
        val origin = withFrameNanos { it }
        while (true) withFrameNanos { time = (it - origin) / 1e9 }
    }
    val width = height / HareSheet.REST_HEIGHT * sheet.scale * sheet.cellWidth.toFloat()
    Canvas(modifier.size(width, height)) {
        val art = image ?: return@Canvas
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
            filterQuality = FilterQuality.Medium,
        )
    }
}
