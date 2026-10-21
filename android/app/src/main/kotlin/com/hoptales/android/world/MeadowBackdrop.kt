package com.hoptales.android.world

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.Palette
import com.hoptales.android.reading.PathGeometry
import com.hoptales.android.reading.drawMeadow
import com.hoptales.content.Friend
import com.hoptales.content.Mood
import com.hoptales.content.Sky

@Composable
fun MeadowBackdrop(modifier: Modifier = Modifier, progress: Float = 700f) {
    val context = LocalContext.current
    val palette = LocalPalette.current
    val look = remember(palette) { SkyLook.of(Mood(sky = if (palette == Palette.dark) Sky.NIGHT else Sky.DAY)) }
    val layers = remember { MeadowLayer.entries.associateWith { Art.image(context.assets, it.asset(Friend.HARE)) } }
    val skyArt = remember { SkyArt.load(context.assets) }
    val ground = remember { MeadowGround.of(WorldStyle.meadow, layers[MeadowLayer.NEAR], MeadowLayer.NEAR.asset(Friend.HARE)) }
    BoxWithConstraints(modifier.fillMaxSize().background(palette.page)) {
        val density = LocalDensity.current.density
        val geometry = PathGeometry(constraints.maxWidth.toFloat(), constraints.maxHeight.toFloat(), density)
        val skyLayout = SkyLayout.of(geometry.meadow, geometry.height)
        val stars = remember(skyLayout) { MeadowStars.field(skyLayout) }
        Canvas(Modifier.fillMaxSize()) {
            drawSky(look, skyLayout, skyArt, stars, 0.0, still = true)
            drawMeadow(layers, geometry.meadow, progress * geometry.pathScale, look, ground)
        }
    }
}
