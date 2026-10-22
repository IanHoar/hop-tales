package com.hoptales.android.world

import android.content.res.AssetManager
import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import java.io.File
import java.io.InputStream
import java.util.concurrent.ConcurrentHashMap

val LocalLooks = compositionLocalOf<File?> { null }

object ArtFile {
    private val extensions = listOf("webp", "png")

    fun open(name: String, pack: File?, bundled: (String) -> InputStream): InputStream? {
        pack?.let { folder ->
            extensions.map { folder.resolve("$name.$it") }.firstOrNull(File::isFile)?.let { return it.inputStream() }
        }
        return extensions.firstNotNullOfOrNull { runCatching { bundled("$name.$it") }.getOrNull() }
    }
}

object Art {
    private val cache = ConcurrentHashMap<String, ImageBitmap>()

    fun image(assets: AssetManager, name: String, looks: File? = null): ImageBitmap? {
        cache[name]?.let { return it }
        val bitmap = ArtFile.open(name, looks, assets::open)?.use { BitmapFactory.decodeStream(it) } ?: return null
        return bitmap.asImageBitmap().also { cache[name] = it }
    }

    fun trim() = cache.clear()
}

@Composable
fun rememberArt(name: String): ImageBitmap? {
    val assets = LocalContext.current.assets
    val looks = LocalLooks.current
    return remember(name, looks) { Art.image(assets, name, looks) }
}

@Composable
fun Sticker(name: String, modifier: Modifier = Modifier, contentDescription: String? = null) {
    val image = rememberArt(name) ?: return
    Image(image, contentDescription, modifier, contentScale = ContentScale.Fit)
}
