package com.hoptales.android.home

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.AdaptiveCells
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.pressable
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

private const val OUTFIT_DAMPING = 0.7f
private const val OUTFIT_STIFFNESS = 322f

@Composable
fun WardrobeScreen(
    friend: Friend,
    progress: Progress,
    wardrobe: WardrobeLibrary,
    onItem: (WardrobeItem) -> Unit,
    onJustMe: () -> Unit,
    onDone: () -> Unit,
) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val items = wardrobe.items(friend)
    val outfit = progress.outfit(friend, wardrobe)
    val newest = progress.newestItem(friend, wardrobe)
    val navigationBar = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    val stage = remember { Deckle(seed = 14, jitter = 3.dp, step = 14.dp) }
    Column(Modifier.fillMaxSize().background(paper.page)) {
        PlainSheetHeader("${friend.friendName}'s wardrobe", 24.sp, onDone)
        LazyVerticalGrid(
            columns = AdaptiveCells(TILE, TILE + 20.dp),
            modifier = Modifier.fillMaxWidth().weight(1f),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = navigationBar + 30.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item(span = { GridItemSpan(maxLineSpan) }) {
                Box(
                    Modifier
                        .padding(bottom = 6.dp)
                        .fillMaxWidth()
                        .background(paper.shade, stage)
                        .padding(vertical = 18.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    AnimatedContent(
                        targetState = outfit,
                        transitionSpec = {
                            fadeIn(spring(OUTFIT_DAMPING, OUTFIT_STIFFNESS)) togetherWith
                                fadeOut(spring(OUTFIT_DAMPING, OUTFIT_STIFFNESS)) using
                                SizeTransform(clip = false) { _, _ -> spring(OUTFIT_DAMPING, OUTFIT_STIFFNESS, IntSize(1, 1)) }
                        },
                        contentAlignment = Alignment.Center,
                        label = "outfit",
                    ) { worn -> DressedFriend(friend, worn, 200.dp) }
                }
            }
            item {
                Tile(isSelected = outfit.isEmpty(), isLocked = false, label = "Just me, nothing on", onClick = onJustMe) {
                    Text("Just me", style = type.display(15.sp), color = paper.ink)
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
                            color = paper.onRed,
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(6.dp)
                                .background(paper.red, CircleShape)
                                .padding(horizontal = 6.dp, vertical = 2.dp),
                        )
                    }
                    if (!unlocked) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Padlock(paper.ink.copy(alpha = 0.8f))
                            Text("Basket $basket", style = type.ui(11.sp), color = paper.ink.copy(alpha = 0.8f))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Padlock(colour: Color) {
    Canvas(Modifier.size(width = 13.dp, height = 17.dp)) {
        val stroke = 2.2.dp.toPx()
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
private fun Tile(isSelected: Boolean, isLocked: Boolean, label: String, onClick: () -> Unit, content: @Composable BoxScope.() -> Unit) {
    val shape = RoundedCornerShape(16.dp)
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) { TileFace(isSelected, isLocked, label, onClick, shape, content) }
}

@Composable
private fun TileFace(
    isSelected: Boolean,
    isLocked: Boolean,
    label: String,
    onClick: () -> Unit,
    shape: RoundedCornerShape,
    content: @Composable BoxScope.() -> Unit,
) {
    val paper = LocalPaper.current
    Box(
        Modifier
            .clearAndSetSemantics {
                contentDescription = label
                selected = isSelected
                role = Role.Button
                onClick {
                    onClick()
                    true
                }
            }
            .pressable(onClick)
            .size(TILE)
            .dropShadow(shape, Shadow(3.dp, paper.shadow.copy(alpha = paper.shadow.alpha * 0.5f), offset = DpOffset(0.dp, 2.dp)))
            .background(if (isLocked) paper.shade else paper.paper, shape)
            .border(if (isSelected) 4.dp else 2.dp, if (isSelected) paper.red else paper.rim, shape),
        contentAlignment = Alignment.Center,
        content = content,
    )
}
