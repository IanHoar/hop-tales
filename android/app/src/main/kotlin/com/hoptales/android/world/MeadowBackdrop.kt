package com.hoptales.android.world

import android.content.res.AssetManager
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.Palette
import com.hoptales.android.reading.PathGeometry
import com.hoptales.android.reading.drawMeadow
import com.hoptales.android.reading.multiply
import com.hoptales.content.Friend
import com.hoptales.content.Mood
import com.hoptales.content.Sky

fun interface MeadowFraming {
    fun layout(width: Float, height: Float, density: Float): MeadowLayout
}

@Composable
fun MeadowBackdrop(modifier: Modifier = Modifier, progress: Float = 700f, world: Friend = Friend.HARE, framing: MeadowFraming? = null) {
    val context = LocalContext.current
    val palette = LocalPalette.current
    val look = remember(palette) { SkyLook.of(Mood(sky = if (palette == Palette.dark) Sky.NIGHT else Sky.DAY)) }
    val layers = remember(world) { meadowLayers(context.assets, world) }
    val skyArt = remember { SkyArt.load(context.assets) }
    BoxWithConstraints(modifier.fillMaxSize().background(palette.page)) {
        val density = LocalDensity.current.density
        val width = constraints.maxWidth.toFloat()
        val height = constraints.maxHeight.toFloat()
        val meadow = framing?.layout(width, height, density) ?: PathGeometry(width, height, density).meadow
        val skyLayout = SkyLayout.of(meadow, height)
        val stars = remember(skyLayout) { MeadowStars.field(skyLayout) }
        Canvas(Modifier.fillMaxSize()) {
            drawSky(look, skyLayout, skyArt, stars, 0.0, still = true)
            drawMeadow(layers, meadow, progress * meadow.pathScale, look)
            if (framing != null) drawGround(meadow, world, look)
        }
    }
}

fun meadowLayers(assets: AssetManager, world: Friend): Map<MeadowLayer, ImageBitmap?> {
    val own = MeadowLayer.entries.associateWith { Art.image(assets, it.asset(world)) }
    if (own.values.all { it != null }) return own
    return MeadowLayer.entries.associateWith { Art.image(assets, it.asset(Friend.HARE)) }
}

private fun DrawScope.drawGround(meadow: MeadowLayout, world: Friend, look: SkyLook) {
    val top = meadow.top(MeadowLayer.NEAR) + meadow.tileHeight(MeadowLayer.NEAR) - 1
    if (top >= size.height) return
    val tint = look.tint(MeadowLayer.NEAR)
    val colours = listOf(WorldStyle.of(world).ground, GROUND_MIDDLE, GROUND_FOOT).map { multiply(it, tint) }
    drawRect(
        Brush.verticalGradient(colours, startY = top, endY = size.height),
        topLeft = Offset(0f, top),
        size = Size(size.width, size.height - top),
    )
}

private val GROUND_MIDDLE = Color(0xFFD9D6A6)
private val GROUND_FOOT = Color(0xFFEDE6C8)
