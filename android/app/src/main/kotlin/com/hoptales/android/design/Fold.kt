package com.hoptales.android.design

import androidx.activity.compose.LocalActivity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.platform.LocalDensity
import androidx.window.layout.FoldingFeature
import androidx.window.layout.WindowInfoTracker
import androidx.window.layout.WindowLayoutInfo
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.map

data class Fold(val frame: Rect) {
    val runsAcross: Boolean get() = frame.width >= frame.height

    fun room(size: Size): Rect = if (runsAcross) {
        Rect(0f, frame.bottom, size.width, maxOf(frame.bottom, size.height))
    } else {
        Rect(frame.right, 0f, maxOf(frame.right, size.width), size.height)
    }

    fun stage(size: Size): Rect = if (runsAcross) {
        Rect(0f, 0f, size.width, maxOf(0f, frame.top))
    } else {
        Rect(0f, 0f, maxOf(0f, frame.left), size.height)
    }

    companion object {
        fun of(info: WindowLayoutInfo, density: Float): Fold? = info.displayFeatures
            .filterIsInstance<FoldingFeature>()
            .firstOrNull { it.state == FoldingFeature.State.HALF_OPENED || it.isSeparating }
            ?.bounds
            ?.let { Fold(Rect(it.left / density, it.top / density, it.right / density, it.bottom / density)) }
    }
}

val LocalFold = compositionLocalOf<Fold?> { null }

@Composable
fun FoldAware(content: @Composable () -> Unit) {
    val activity = LocalActivity.current
    val density = LocalDensity.current.density
    val layouts = remember(activity, density) {
        activity?.let { WindowInfoTracker.getOrCreate(it).windowLayoutInfo(it).map { info -> Fold.of(info, density) } }
            ?: emptyFlow()
    }
    val fold by layouts.collectAsState(null)
    CompositionLocalProvider(LocalFold provides (fold ?: LocalFold.current), content = content)
}
