package com.hoptales.android.home

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.world.DressedFriend
import com.hoptales.android.world.WearSticker
import com.hoptales.content.Friend
import com.hoptales.content.Progress
import com.hoptales.content.WardrobeItem
import com.hoptales.content.WardrobeLibrary
import com.hoptales.content.isUnlocked
import com.hoptales.content.newestItem
import com.hoptales.content.outfit

private val TILE = 82.dp

@Composable
fun WardrobeScreen(
    friend: Friend,
    progress: Progress,
    wardrobe: WardrobeLibrary,
    onItem: (WardrobeItem) -> Unit,
    onJustMe: () -> Unit,
    onDone: () -> Unit,
) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val items = wardrobe.items(friend)
    val outfit = progress.outfit(friend, wardrobe)
    val newest = progress.newestItem(friend, wardrobe)
    Column(Modifier.fillMaxSize().background(palette.page)) {
        SheetHeader("${friend.friendName}'s wardrobe", onDone)
        LazyVerticalGrid(
            columns = GridCells.Adaptive(TILE + 12.dp),
            modifier = Modifier.fillMaxWidth().weight(1f),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 30.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item(span = { GridItemSpan(maxLineSpan) }) {
                Box(
                    Modifier
                        .padding(bottom = 6.dp)
                        .fillMaxWidth()
                        .background(palette.parchmentLip.copy(alpha = 0.6f), RoundedCornerShape(6.dp))
                        .padding(vertical = 18.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    DressedFriend(friend, outfit, 200.dp)
                }
            }
            item {
                Tile(isSelected = outfit.isEmpty(), isLocked = false, label = "Just me, nothing on", onClick = onJustMe) {
                    Text("Just me", style = type.display(15.sp), color = palette.ink)
                }
            }
            items(items, key = { it.id }) { item ->
                val unlocked = progress.isUnlocked(item, friend, wardrobe)
                val basket = wardrobe.unlockable(friend).indexOf(item).coerceAtLeast(0)
                Tile(
                    isSelected = item in outfit,
                    isLocked = !unlocked,
                    label = if (unlocked) item.name else "${item.name}, locked",
                    onClick = { onItem(item) },
                ) {
                    WearSticker(friend, item, TILE * 0.78f, TILE * 0.62f, alpha = if (unlocked) 1f else 0.35f, grey = !unlocked)
                    if (unlocked && item == newest && item !in outfit) {
                        Text(
                            "new",
                            style = type.ui(11.sp),
                            color = palette.onTeal,
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(6.dp)
                                .background(palette.red, CircleShape)
                                .padding(horizontal = 6.dp, vertical = 2.dp),
                        )
                    }
                    if (!unlocked) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Padlock(palette.ink.copy(alpha = 0.8f))
                            Text("Basket $basket", style = type.ui(11.sp), color = palette.ink.copy(alpha = 0.8f))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Padlock(colour: Color) {
    Canvas(Modifier.size(width = 16.dp, height = 20.dp)) {
        val stroke = 2.5.dp.toPx()
        drawArc(
            colour,
            startAngle = 180f,
            sweepAngle = 180f,
            useCenter = false,
            topLeft = Offset(size.width * 0.2f, stroke / 2),
            size = Size(size.width * 0.6f, size.height * 0.7f),
            style = Stroke(stroke),
        )
        drawRoundRect(
            colour,
            topLeft = Offset(0f, size.height * 0.42f),
            size = Size(size.width, size.height * 0.58f),
            cornerRadius = CornerRadius(3.dp.toPx()),
        )
    }
}

@Composable
private fun Tile(
    isSelected: Boolean,
    isLocked: Boolean,
    label: String,
    onClick: () -> Unit,
    content: @Composable androidx.compose.foundation.layout.BoxScope.() -> Unit,
) {
    val palette = LocalPalette.current
    Surface(
        onClick = onClick,
        modifier = Modifier.size(TILE).clearAndSetSemantics {
            contentDescription = label
            selected = isSelected
            role = Role.Button
            onClick {
                onClick()
                true
            }
        },
        shape = RoundedCornerShape(16.dp),
        color = if (isLocked) palette.parchmentLip.copy(alpha = 0.6f) else palette.paper,
        border = BorderStroke(if (isSelected) 4.dp else 2.dp, if (isSelected) palette.red else palette.outline),
        shadowElevation = 2.dp,
    ) {
        Box(contentAlignment = Alignment.Center, content = content)
    }
}
