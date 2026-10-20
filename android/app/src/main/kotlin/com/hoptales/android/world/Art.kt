package com.hoptales.android.world

import android.content.res.AssetManager
import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import java.util.concurrent.ConcurrentHashMap

object Art {
    private val cache = ConcurrentHashMap<String, ImageBitmap>()

    fun image(assets: AssetManager, name: String): ImageBitmap? {
        cache[name]?.let { return it }
        val file = listOf("$name.webp", "$name.png").firstOrNull { candidate ->
            runCatching { assets.open(candidate).close() }.isSuccess
        } ?: return null
        val bitmap = assets.open(file).use { BitmapFactory.decodeStream(it) } ?: return null
        return bitmap.asImageBitmap().also { cache[name] = it }
    }

    fun trim() = cache.clear()
}

@Composable
fun rememberArt(name: String): ImageBitmap? {
    val assets = LocalContext.current.assets
    return remember(name) { Art.image(assets, name) }
}

@Composable
fun Sticker(name: String, modifier: Modifier = Modifier, contentDescription: String? = null) {
    val image = rememberArt(name) ?: return
    Image(image, contentDescription, modifier, contentScale = ContentScale.Fit)
}
