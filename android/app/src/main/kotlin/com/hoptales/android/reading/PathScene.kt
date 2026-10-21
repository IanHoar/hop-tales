package com.hoptales.android.reading

import android.content.res.AssetManager
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.sp
import com.hoptales.android.world.Art
import com.hoptales.android.world.HareSheet
import com.hoptales.android.world.HareSheets
import com.hoptales.android.world.MeadowLayer
import com.hoptales.android.world.MeadowLayout
import com.hoptales.android.world.SkyLook
import com.hoptales.android.world.WorldStyle
import com.hoptales.content.Story
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

data class PathGeometry(val width: Float, val height: Float, val density: Float) {
    val isLarge: Boolean get() = min(width, height) / density >= 600f
    val scale: Float get() = min(width, height) / density / if (isLarge) 834f else 390f
    val pathScale: Float get() = scale * (if (isLarge) 1.15f else 1f) * density
    val pathCentre: Float get() = height * if (isLarge) 632f / 834f else 640f / 844f

    fun path(value: Float) = value * pathScale

    val meadow: MeadowLayout get() = MeadowLayout(width, pathScale, pathCentre)

    companion object {
        const val WORD_SIZE = 46f
        const val GAP = 64f
        const val SENTENCE_GAP = 140f
        const val FOCUS_X = 236f
        const val HARE_X = 96f
        const val HARE_FEET_BELOW_PATH = 30f
        const val SITTING_HEIGHT = 124f
        const val HOPPING_HEIGHT = 116f
        const val WORD_APEX = 30f
        const val SENTENCE_APEX = 60f
        const val OVERSHOOT = 200f
        const val RISE = 0.58f
        const val PAN_MILLIS = 620
        const val SIDE_SCALE = 0.7f
        const val WASH_OVERHANG = 14f
        const val TILT_DEGREES = 24f
        const val TILT_ANCHOR = 0.6f
        const val TILT_PERSPECTIVE = 0.5f
        const val START_SIGN = 80f
        const val END_SIGN = 270f
        const val SIGN_HEIGHT = 172f
        const val SIGN_FEET_ABOVE_PATH = 40f
    }
}

data class Stop(val sentence: Int, val word: Int, val layout: TextLayoutResult, val centre: Float) {
    val width: Float get() = layout.size.width.toFloat()
}

class WordPath(
    story: Story,
    val geometry: PathGeometry,
    measurer: TextMeasurer,
    style: TextStyle,
    val world: WorldStyle = WorldStyle.meadow,
) {
    val stops: List<Stop>

    init {
        val stops = mutableListOf<Stop>()
        for ((sentence, words) in story.sentences.withIndex()) {
            for ((index, word) in words.words.withIndex()) {
                val layout = measurer.measure(word.leading + word.text + word.trailing, style)
                val width = layout.size.width.toFloat()
                val previous = stops.lastOrNull()
                val centre = if (previous == null) {
                    geometry.path(PathGeometry.FOCUS_X)
                } else {
                    val gap = if (index == 0) PathGeometry.SENTENCE_GAP else PathGeometry.GAP
                    previous.centre + previous.width / 2 + geometry.path(gap) + width / 2
                }
                stops += Stop(sentence, index, layout, centre)
            }
        }
        this.stops = stops
    }

    fun stop(sentence: Int, word: Int): Stop? = stops.firstOrNull { it.sentence == sentence && it.word == word }

    fun camera(sentence: Int, word: Int): Float {
        stop(sentence, word)?.let { return it.centre - geometry.path(PathGeometry.FOCUS_X) }
        val last = stops.lastOrNull() ?: return 0f
        return last.centre + geometry.path(PathGeometry.OVERSHOOT) - geometry.path(PathGeometry.FOCUS_X)
    }

    val hareX: Float get() = geometry.path(PathGeometry.HARE_X)

    val hareFeetY: Float
        get() = geometry.pathCentre + geometry.path(world.feetAbovePath?.let { -it } ?: PathGeometry.HARE_FEET_BELOW_PATH)

    fun apex(carried: Boolean): Float = geometry.path(if (carried) PathGeometry.SENTENCE_APEX else PathGeometry.WORD_APEX)

    fun hareHeight(hopping: Boolean): Float = geometry.path(if (hopping) PathGeometry.HOPPING_HEIGHT else PathGeometry.SITTING_HEIGHT)

    fun wordCentreY(stop: Stop): Float = geometry.pathCentre + (0.5f - PathGeometry.RISE) * stop.layout.size.height

    fun hit(offset: Offset, cameraX: Float, sentence: Int, word: Int): Boolean {
        val stop = stop(sentence, word) ?: return false
        val x = stop.centre - cameraX
        val y = wordCentreY(stop)
        val slop = geometry.path(16f)
        return offset.x in (x - stop.width / 2 - slop)..(x + stop.width / 2 + slop) &&
            offset.y in (y - stop.layout.size.height / 2 - slop)..(y + stop.layout.size.height / 2 + slop)
    }
}

enum class WordState(val ink: Color, val chalk: Color) {
    READ(Color(0xFF3B2A20), Color(0xD9F4EFE4)),
    CURRENT(Color(0xFF2E2018), Color(0xFFFFFDF7)),
    UPCOMING(Color(0x6B3B2A20), Color(0x73F4EFE4)),
}

data class HareArt(val idle: ImageBitmap?, val hop: ImageBitmap?, val sheets: HareSheets) {
    fun image(sheet: HareSheet): ImageBitmap? = if (sheet == HareSheet.IDLE) idle else hop
}

fun DrawScope.drawMeadow(layers: Map<MeadowLayer, ImageBitmap?>, layout: MeadowLayout, cameraX: Float, look: SkyLook) {
    for (layer in MeadowLayer.entries) {
        val colour = look.tint(layer)
        val tint = if (colour == Color.White) null else ColorFilter.tint(colour, BlendMode.Modulate)
        val image = layers[layer] ?: continue
        val width = layout.tileWidth(layer)
        val height = layout.tileHeight(layer)
        val offset = layout.offset(layer, cameraX)
        val top = layout.top(layer)
        for (index in 0 until layout.tileCount(layer)) {
            drawImage(
                image = image,
                dstOffset = IntOffset((offset + index * width).roundToInt(), top.roundToInt()),
                dstSize = IntSize(width.roundToInt() + 1, height.roundToInt()),
                colorFilter = tint,
                filterQuality = FilterQuality.Medium,
            )
        }
        if (layer == MeadowLayer.NEAR) {
            val bottom = top + height
            if (bottom < size.height) {
                drawRect(
                    multiply(UNDERSTORY, look.tint(layer)),
                    topLeft = Offset(0f, bottom - 1),
                    size = Size(size.width, size.height - bottom + 1),
                )
            }
        }
    }
}

fun DrawScope.drawWords(path: WordPath, cameraX: Float, sentence: Int, word: Int) {
    val overhang = path.geometry.path(PathGeometry.WASH_OVERHANG)
    val blend = if (path.world.chalk) BlendMode.Screen else BlendMode.Multiply
    for (stop in path.stops) {
        val x = stop.centre - cameraX
        if (x + stop.width < 0 || x - stop.width > size.width) continue
        val state = when {
            stop.sentence < sentence || (stop.sentence == sentence && stop.word < word) -> WordState.READ
            stop.sentence == sentence && stop.word == word -> WordState.CURRENT
            else -> WordState.UPCOMING
        }
        val height = stop.layout.size.height.toFloat()
        val frame = Rect(Offset(x - stop.width / 2, path.wordCentreY(stop) - height / 2), Size(stop.width, height))
        val scale = if (state == WordState.CURRENT) 1f else PathGeometry.SIDE_SCALE
        lying(frame, scale) {
            if (state == WordState.READ) drawWash(frame.inflateHorizontally(overhang), blend)
            drawText(stop.layout, color = if (path.world.chalk) state.chalk else state.ink, topLeft = frame.topLeft, blendMode = blend)
        }
    }
}

private fun DrawScope.lying(frame: Rect, scale: Float, block: DrawScope.() -> Unit) {
    val anchor = Offset(frame.center.x, frame.top + frame.height * PathGeometry.TILT_ANCHOR)
    val depth = maxOf(frame.width, frame.height) / PathGeometry.TILT_PERSPECTIVE
    val angle = Math.toRadians(PathGeometry.TILT_DEGREES.toDouble())
    val corners = listOf(frame.topLeft, frame.topRight, frame.bottomRight, frame.bottomLeft)
    val source = FloatArray(8)
    val target = FloatArray(8)
    for ((index, corner) in corners.withIndex()) {
        val scaled = frame.center + (corner - frame.center) * scale
        val dx = scaled.x - anchor.x
        val dy = scaled.y - anchor.y
        val z = dy * sin(angle).toFloat()
        val projection = 1f / (1f - z / depth)
        source[index * 2] = corner.x
        source[index * 2 + 1] = corner.y
        target[index * 2] = anchor.x + dx * projection
        target[index * 2 + 1] = anchor.y + dy * cos(angle).toFloat() * projection
    }
    val matrix = android.graphics.Matrix().apply { setPolyToPoly(source, 0, target, 0, 4) }
    val canvas = drawContext.canvas.nativeCanvas
    canvas.save()
    canvas.concat(matrix)
    block()
    canvas.restore()
}

private fun Rect.inflateHorizontally(amount: Float) = Rect(left - amount, top, right + amount, bottom)

private fun DrawScope.drawWash(frame: Rect, blend: BlendMode) {
    val stops = arrayOf(0f to WASH.copy(alpha = 0.95f), 0.52f to WASH.copy(alpha = 0.7f), 0.72f to WASH.copy(alpha = 0f))
    withTransform({ scale(frame.width / frame.height, 1f, frame.center) }) {
        val square = Rect(frame.center, frame.height / 2)
        drawRect(
            Brush.radialGradient(*stops, center = frame.center, radius = frame.height * WASH_REACH),
            topLeft = square.topLeft,
            size = square.size,
            blendMode = blend,
        )
    }
}

class Signposts(assets: AssetManager, path: WordPath, measurer: TextMeasurer, family: FontFamily, title: String) {
    private val density = path.geometry.density
    val image: ImageBitmap? = Art.image(assets, "prop-signpost")
    val height = path.geometry.path(PathGeometry.SIGN_HEIGHT)
    val width = height * (image?.let { it.width.toFloat() / it.height } ?: 0.8f)
    private val unit = height / PathGeometry.SIGN_HEIGHT
    val label = Rect(Offset(7 * unit, 23 * unit), Size(width - 30 * unit, 53 * unit))
    val start = path.stops.firstOrNull()?.let { it.centre + path.geometry.path(PathGeometry.START_SIGN) }
    val end = path.stops.lastOrNull()?.let { it.centre + path.geometry.path(PathGeometry.END_SIGN) }
    val feetY = path.geometry.pathCentre - path.geometry.path(PathGeometry.SIGN_FEET_ABOVE_PATH)
    val titleText = fit(measurer, title, family, path.geometry.path(17f))
    val endText = fit(measurer, "The end", family, path.geometry.path(21f))

    private fun fit(measurer: TextMeasurer, text: String, family: FontFamily, size: Float): TextLayoutResult {
        var scale = 1f
        while (true) {
            val style = TextStyle(
                fontFamily = family,
                fontWeight = FontWeight.Bold,
                fontSize = (size * scale / density).sp,
                textAlign = TextAlign.Center,
                lineHeight = (size * scale * SIGN_LEADING / density).sp,
            )
            val layout = measurer.measure(
                text,
                style,
                maxLines = 2,
                constraints = Constraints(maxWidth = label.width.roundToInt().coerceAtLeast(1)),
            )
            val fits = !layout.hasVisualOverflow && layout.size.height <= label.height
            if (fits || scale <= SIGN_MIN_SCALE) return layout
            scale -= 0.05f
        }
    }
}

fun DrawScope.drawSigns(signs: Signposts, cameraX: Float, tint: Color) {
    val image = signs.image ?: return
    val filter = if (tint == Color.White) null else ColorFilter.tint(tint, BlendMode.Modulate)
    for ((x, text) in listOf(signs.start to signs.titleText, signs.end to signs.endText)) {
        if (x == null) continue
        val left = x - cameraX - signs.width / 2
        if (left > size.width || left + signs.width < 0) continue
        val top = signs.feetY - signs.height
        drawImage(
            image,
            dstOffset = IntOffset(left.roundToInt(), top.roundToInt()),
            dstSize = IntSize(signs.width.roundToInt(), signs.height.roundToInt()),
            colorFilter = filter,
            filterQuality = FilterQuality.Medium,
        )
        val label = signs.label.translate(left, top)
        rotate(SIGN_TILT, label.center) {
            drawText(
                text,
                color = multiply(SIGN_INK, tint),
                topLeft = Offset(label.center.x - text.size.width / 2f, label.center.y - text.size.height / 2f),
                blendMode = BlendMode.Multiply,
            )
        }
    }
}

fun DrawScope.drawHare(art: HareArt, path: WordPath, pose: HareMotion.Pose, lift: Float) {
    val hopping = pose.frame.sheet == HareSheet.HOP
    val sheet = art.sheets.of(pose.frame.sheet)
    val image = art.image(pose.frame.sheet) ?: art.idle ?: return
    val frame = pose.frame.index.coerceIn(0, sheet.frames - 1)
    val scale = path.hareHeight(hopping) / HareSheet.REST_HEIGHT * sheet.scale
    val width = sheet.cellWidth * scale * pose.scaleX
    val height = sheet.cellHeight * scale * pose.scaleY
    val feetX = path.hareX + pose.x
    val feetY = path.hareFeetY - lift
    drawImage(
        image = image,
        srcOffset = IntOffset(frame * sheet.cellWidth, 0),
        srcSize = IntSize(sheet.cellWidth, sheet.cellHeight),
        dstOffset = IntOffset((feetX - width * sheet.anchorX).roundToInt(), (feetY - height * sheet.anchorY).roundToInt()),
        dstSize = IntSize(width.roundToInt(), height.roundToInt()),
        filterQuality = FilterQuality.Medium,
    )
}

const val IDLE_FPS = 20f

private val UNDERSTORY = Color(0xFF6E8B3D)
private val WASH = Color(0xFFF7D774)
private val WASH_REACH = 0.5f * sqrt(2f)
private val SIGN_INK = Color(0xFF3B2A20)
private const val SIGN_TILT = -1.5f
private const val SIGN_MIN_SCALE = 0.6f
private const val SIGN_LEADING = 1.05f

private fun multiply(colour: Color, tint: Color) =
    Color(colour.red * tint.red, colour.green * tint.green, colour.blue * tint.blue, colour.alpha)
