package com.hoptales.android.intro

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.Paper
import com.hoptales.android.design.PaperLabel
import com.hoptales.android.world.IntroArt
import com.hoptales.android.world.IntroFrame
import com.hoptales.android.world.IntroLayout
import com.hoptales.android.world.IntroScene
import com.hoptales.android.world.IntroTimeline

@Composable
fun IntroScreen(art: IntroArt?, reduceMotion: Boolean, onFinished: () -> Unit, modifier: Modifier = Modifier) {
    val finish by rememberUpdatedState(onFinished)
    var elapsed by remember { mutableDoubleStateOf(0.0) }
    LaunchedEffect(art) {
        if (art == null) return@LaunchedEffect
        repeat(SETTLING_FRAMES) { withFrameNanos { } }
        val origin = withFrameNanos { it }
        val route = IntroTimeline.route(reduceMotion)
        while (elapsed < route) withFrameNanos { elapsed = (it - origin) / 1e9 }
        finish()
    }
    IntroContent(
        art = art,
        time = { if (reduceMotion) 0.0 else elapsed },
        fade = { IntroTimeline.launchFade(elapsed) },
        showsTitle = !reduceMotion,
        modifier = modifier
            .clickable(remember { MutableInteractionSource() }, indication = null) { finish() }
            .clearAndSetSemantics {
                contentDescription = "Hop Tales"
                heading()
            },
    )
}

@Composable
fun IntroContent(art: IntroArt?, time: () -> Double, fade: () -> Float, showsTitle: Boolean, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().background(Color(IntroLayout.NIGHT))) {
        if (art != null) {
            IntroScene(art, time, Modifier.fillMaxSize().graphicsLayer { alpha = fade() })
        }
        if (showsTitle) IntroTitle { IntroFrame.at(time()) }
    }
}

@Composable
private fun IntroTitle(frame: () -> IntroFrame) {
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val density = LocalDensity.current
        val layout = IntroLayout(constraints.maxWidth.toFloat(), constraints.maxHeight.toFloat(), density.density)
        val k = layout.titleK
        val typography = LocalTypography.current
        CompositionLocalProvider(LocalPaper provides Paper.light) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(top = maxHeight * 0.14f)
                    .graphicsLayer {
                        val now = frame()
                        alpha = now.title
                        translationY = now.titleOffset * density.density
                    },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(Dp(10 * k)),
            ) {
                PaperLabel(Modifier.rotate(-2f), seed = 28) {
                    Text(
                        "Hop Tales",
                        style = typography.display((46 * k).sp),
                        color = Paper.light.ink,
                        modifier = Modifier.padding(start = Dp(28 * k), end = Dp(28 * k), top = Dp(12 * k), bottom = Dp(16 * k)),
                    )
                }
                Text(
                    "a read-aloud adventure",
                    style = typography.word((17 * minOf(1.5f, k)).sp),
                    color = Paper.light.ink.copy(alpha = 0.85f),
                )
            }
        }
    }
}

private const val SETTLING_FRAMES = 3
