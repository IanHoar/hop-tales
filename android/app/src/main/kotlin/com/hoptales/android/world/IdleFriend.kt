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
import kotlin.math.PI
import kotlin.math.roundToInt
import kotlin.math.sin

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
fun IdleFriend(
    friend: Friend,
    look: String?,
    height: Dp,
    modifier: Modifier = Modifier,
    shadow: Color? = null,
    hopStart: Double? = null,
    hopLift: Dp = 0.dp,
) {
    val assets = LocalContext.current.assets
    val looks = LocalLooks.current
    val still = rememberReducedMotion()
    val sheets = HareSheets.of(friend)
    val sheet = sheets.idle
    val image = remember(friend, look, looks) {
        look?.let { Art.image(assets, sheets.dressed(friend, it, HareSheet.IDLE), looks) } ?: Art.image(assets, sheet.asset)
    }
    val hopImage = remember(friend) { Art.image(assets, sheets.hop.asset) }
    var time by remember { mutableDoubleStateOf(System.nanoTime() / 1e9) }
    LaunchedEffect(still) {
        if (still) return@LaunchedEffect
        while (true) withFrameNanos { time = it / 1e9 }
    }
    val width = height / HareSheet.REST_HEIGHT * sheet.scale * sheet.cellWidth.toFloat()
    val draw: DrawScope.(ColorFilter?) -> Unit = draw@{ filter ->
        val hopFrame = hopStart?.let { ((time - it) * HOP_FPS).toInt() }?.takeIf { !still && it in 0 until HareSheet.HOP.frames }
        val drawn = if (hopFrame != null) sheets.hop else sheet
        val art = (if (hopFrame != null) hopImage else image) ?: return@draw
        val pose = hopFrame?.let { IdlePose(it, 1f, 1f) } ?: IdlePose.at(time, still)
        val arc = hopFrame?.let { sin(PI * ((time - (hopStart ?: time)) * HOP_FPS - 1).div(6).coerceIn(0.0, 1.0)).toFloat() } ?: 0f
        val lift = hopLift.toPx() * arc
        val scale = size.height / HareSheet.REST_HEIGHT * drawn.scale
        val frameSize = IntSize((drawn.cellWidth * scale * pose.scaleX).roundToInt(), (drawn.cellHeight * scale * pose.scaleY).roundToInt())
        drawImage(
            art,
            srcOffset = IntOffset(pose.frame.coerceIn(0, drawn.frames - 1) * drawn.cellWidth, 0),
            srcSize = IntSize(drawn.cellWidth, drawn.cellHeight),
            dstOffset = IntOffset(
                (size.width / 2 - frameSize.width * drawn.anchorX).roundToInt(),
                (size.height - frameSize.height * drawn.anchorY - lift).roundToInt(),
            ),
            dstSize = frameSize,
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

private const val HOP_FPS = 14.0
private val SHADOW_DROP = 4.dp
private val SHADOW_BLUR = 6.dp
