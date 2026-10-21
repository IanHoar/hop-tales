package com.hoptales.android.world

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalTypography
import com.hoptales.content.Friend
import com.hoptales.content.WardrobeItem
import com.hoptales.content.startingLook

fun Friend.stickerAsset(): String = if (this == Friend.HARE) "hare-sit" else "friend-$key"

fun Friend.lookAsset(look: String): String = "look-$key-$look"

fun Friend.wearAsset(item: WardrobeItem): String = "wear-$key-${item.id}"

val TreatGold = Color(0xFFF3C64A)

@Composable
private fun ArtImage(image: ImageBitmap, height: Dp, modifier: Modifier = Modifier, colorFilter: ColorFilter? = null, alpha: Float = 1f) {
    Image(
        image,
        contentDescription = null,
        modifier = modifier.height(height).aspectRatio(image.width.toFloat() / maxOf(image.height, 1)),
        contentScale = ContentScale.Fit,
        colorFilter = colorFilter,
        alpha = alpha,
    )
}

@Composable
fun FriendSticker(
    friend: Friend,
    height: Dp,
    modifier: Modifier = Modifier,
    isSilhouette: Boolean = false,
    isBare: Boolean = false,
    saturation: Float = 1f,
) {
    val dressed = if (isBare) null else friend.startingLook()?.let { rememberArt(it) }
    val image = dressed ?: rememberArt(friend.stickerAsset()) ?: return
    val shadow = LocalPalette.current.muted
    ArtImage(
        image,
        height,
        modifier,
        colorFilter = when {
            isSilhouette -> ColorFilter.tint(shadow, BlendMode.SrcIn)
            saturation < 1f -> ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(saturation) })
            else -> null
        },
        alpha = if (isSilhouette) 0.45f else 1f,
    )
}

@Composable
fun DressedFriend(friend: Friend, outfit: List<WardrobeItem>, height: Dp, modifier: Modifier = Modifier) {
    val look = outfit.firstOrNull()?.let { rememberArt(friend.lookAsset(it.id)) }
    if (look != null) {
        ArtImage(look, height, modifier)
    } else {
        FriendSticker(friend, height, modifier, isBare = true)
    }
}

@Composable
fun TreatSticker(friend: Friend, height: Dp, modifier: Modifier = Modifier, isGolden: Boolean = false) {
    if (isGolden && friend == Friend.HARE) {
        rememberArt("collect-carrot-gold")?.let { ArtImage(it, height, modifier) }
        return
    }
    val image = rememberArt("collect-${friend.treat.art}") ?: return
    ArtImage(image, height, modifier, colorFilter = if (isGolden) ColorFilter.tint(TreatGold, BlendMode.Modulate) else null)
}

@Composable
fun Rosette(level: Int, modifier: Modifier = Modifier, height: Dp = 38.dp) {
    Box(modifier, contentAlignment = Alignment.Center) {
        rememberArt("collect-rosette")?.let { ArtImage(it, height) }
        Text(
            "$level",
            style = LocalTypography.current.display((height.value * 13 / 38).sp),
            color = Color(0xFF3B2A20),
            modifier = Modifier.offset(y = -height * 4 / 38),
        )
    }
}

@Composable
fun WearSticker(
    friend: Friend,
    item: WardrobeItem,
    width: Dp,
    height: Dp,
    modifier: Modifier = Modifier,
    alpha: Float = 1f,
    grey: Boolean = false,
) {
    val image = rememberArt(friend.wearAsset(item)) ?: return
    val aspect = image.width.toFloat() / maxOf(image.height, 1)
    val fitted = if (width / height > aspect) height else width / aspect
    ArtImage(image, fitted, modifier, colorFilter = if (grey) Greyscale else null, alpha = alpha)
}

private val Greyscale = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) })
