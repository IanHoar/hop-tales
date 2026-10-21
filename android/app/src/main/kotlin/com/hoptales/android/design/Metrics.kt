package com.hoptales.android.design

import androidx.compose.ui.geometry.Size

data class Metrics(val reference: Size, val pathScale: Float = 1f, val pathCentre: Float = 640f) {
    val shortSide: Float get() = reference.minDimension

    companion object {
        val PHONE = Metrics(Size(390f, 844f))
        val DUO = Metrics(Size(466f, 678f), pathScale = 0.82f, pathCentre = 514f)
        val PAD = Metrics(Size(1194f, 834f), pathScale = 1.15f, pathCentre = 632f)

        const val SQUAT_ASPECT = 0.6f
        const val REGULAR_WIDTH = 600f
        const val REGULAR_HEIGHT = 480f

        fun isRegular(width: Float, height: Float): Boolean = width >= REGULAR_WIDTH && height >= REGULAR_HEIGHT

        fun forScreen(width: Float, height: Float, regular: Boolean = isRegular(width, height)): Metrics = when {
            regular -> PAD
            height <= 0f || width / height <= SQUAT_ASPECT -> PHONE
            else -> DUO
        }
    }
}
