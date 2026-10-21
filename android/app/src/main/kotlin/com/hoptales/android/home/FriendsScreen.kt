package com.hoptales.android.home

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.pressable
import com.hoptales.android.world.DressedFriend
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.Rosette
import com.hoptales.android.world.TreatSticker
import com.hoptales.content.Friend
import com.hoptales.content.Progress
import com.hoptales.content.WardrobeLibrary
import com.hoptales.content.outfit

@Composable
fun FriendsScreen(progress: Progress, wardrobe: WardrobeLibrary, onFriend: (Friend) -> Unit, onJourney: () -> Unit, onDone: () -> Unit) {
    val navigationBar = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    Column(Modifier.fillMaxSize().background(LocalPaper.current.page)) {
        SheetHeader("Friends", onDone) { MapButton(onJourney) }
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            modifier = Modifier.fillMaxWidth().weight(1f),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = navigationBar + 30.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            items(Friend.entries) { friend -> FriendCard(friend, progress, wardrobe) { onFriend(friend) } }
        }
    }
}

@Composable
private fun FriendCard(friend: Friend, progress: Progress, wardrobe: WardrobeLibrary, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val journey = progress.journey
    val isMet = friend in journey.met
    val isReading = friend == journey.activeFriend
    val isNext = friend == journey.nextFriend
    val label = when {
        isReading -> "${friend.friendName}, level ${friend.level}. Reading now."
        isMet -> "${friend.friendName}, level ${friend.level}. Tap to read with ${friend.friendName}."
        isNext -> "${friend.friendName} is next. Fill the path, then read the big story."
        else -> "A friend at reading level ${friend.level}."
    }
    val shape = RoundedCornerShape(20.dp)
    Column(
        Modifier
            .fillMaxWidth()
            .heightIn(min = 200.dp)
            .clearAndSetSemantics {
                contentDescription = label
                selected = isReading
                role = Role.Button
                onClick {
                    onClick()
                    true
                }
            }
            .pressable(onClick)
            .dropShadow(shape, Shadow(4.dp, paper.shadow.copy(alpha = paper.shadow.alpha * 0.5f), offset = DpOffset(0.dp, 3.dp)))
            .background(paper.paper, shape)
            .border(if (isReading) 4.dp else 3.dp, if (isReading) paper.red else paper.rim, shape)
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(Modifier.fillMaxWidth().height(110.dp)) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                if (isMet) {
                    DressedFriend(friend, progress.outfit(friend, wardrobe), 96.dp)
                } else {
                    FriendSticker(
                        friend,
                        96.dp,
                        Modifier.alpha(if (isNext) 1f else 0.35f),
                        isSilhouette = !isNext,
                        silhouette = paper.silhouette,
                        saturation = if (isNext) 0.4f else 1f,
                    )
                }
            }
            val tag = when {
                isReading -> "reading"
                isNext -> "next"
                else -> null
            }
            if (tag != null) {
                Text(
                    tag,
                    style = type.ui(12.sp),
                    color = if (isReading) paper.onRed else paper.ink,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .background(if (isReading) paper.red else paper.wash, CircleShape)
                        .padding(horizontal = 8.dp, vertical = 3.dp),
                )
            }
        }
        Text(if (isMet || isNext) friend.friendName else "?", style = type.display(20.sp), color = paper.ink)
        if (isMet) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Rosette(friend.level, height = 30.dp)
                Text("Level ${friend.level}", style = type.ui(14.sp), color = paper.ink)
                Spacer(Modifier.weight(1f).widthIn(min = 4.dp))
                TreatSticker(friend, 20.dp)
                Text(
                    "${progress.baskets[friend]?.total ?: 0}",
                    style = type.ui(14.sp).copy(fontFeatureSettings = "tnum"),
                    color = paper.ink,
                )
            }
        } else {
            Text(
                if (isNext) "Level ${friend.level} · fill the path, then read the big story" else "Reading level ${friend.level}",
                style = type.ui(13.sp, FontWeight.Medium),
                color = paper.muted,
            )
        }
    }
}
