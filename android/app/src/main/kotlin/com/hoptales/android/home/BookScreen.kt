package com.hoptales.android.home

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.Rosette
import com.hoptales.android.world.TreatSticker
import com.hoptales.content.Basket
import com.hoptales.content.Friend
import com.hoptales.content.Progress
import com.hoptales.content.StoryLibrary

private const val GOLDEN_SLOTS = 5

@Composable
fun BookScreen(library: StoryLibrary, progress: Progress, friend: Friend, onFriend: (Friend) -> Unit, onDone: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val basket = progress.baskets[friend] ?: Basket()
    val storiesRead = library.stories(friend.level).filter(progress::isFinished)
    Column(Modifier.fillMaxSize().background(palette.page)) {
        SheetHeader("Collection book", onDone)
        Row(Modifier.fillMaxWidth().weight(1f)) {
            Surface(
                modifier = Modifier.weight(1f).padding(start = 20.dp, bottom = 30.dp),
                shape = RoundedCornerShape(8.dp),
                color = palette.paper,
                border = BorderStroke(3.dp, palette.outline),
                shadowElevation = 4.dp,
            ) {
                Column(Modifier.verticalScroll(rememberScrollState()).padding(22.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                    Text(
                        "${friend.friendName}'s basket",
                        style = type.display(26.sp),
                        color = palette.ink,
                        modifier = Modifier.semantics {
                            heading()
                        },
                    )
                    Row(
                        Modifier.clearAndSetSemantics { contentDescription = "${basket.total} ${friend.treat.many} found" },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Row(horizontalArrangement = Arrangement.spacedBy((-14).dp)) {
                            repeat(basket.total.coerceIn(1, 4)) { index ->
                                Box(Modifier.rotate(index * 14f - 20f)) {
                                    TreatSticker(friend, 52.dp, Modifier.alpha(if (basket.total == 0) 0.3f else 1f))
                                }
                            }
                        }
                        Column(Modifier.padding(start = 12.dp)) {
                            Text("${basket.total}", style = type.display(38.sp), color = palette.ink)
                            Text("${friend.treat.many} found", style = type.ui(15.sp, FontWeight.Medium), color = palette.muted)
                        }
                    }
                    Section("Golden ${friend.treat.many}") {
                        repeat(maxOf(GOLDEN_SLOTS, basket.golden)) { index ->
                            Slot(filled = index < basket.golden) { TreatSticker(friend, 44.dp, isGolden = true) }
                        }
                    }
                    Section("Reading levels") {
                        for (level in Friend.entries) {
                            Slot(filled = level in progress.journey.met) { Rosette(level.level) }
                        }
                    }
                    if (storiesRead.isNotEmpty()) {
                        Section("Stories read") {
                            for (story in storiesRead) {
                                Text(
                                    story.title,
                                    style = type.display(14.sp),
                                    color = palette.ink,
                                    maxLines = 1,
                                    modifier = Modifier
                                        .rotate(if (story.title.length % 2 == 0) -1.5f else 1.5f)
                                        .background(palette.parchmentLip.copy(alpha = 0.6f), RoundedCornerShape(8.dp))
                                        .padding(horizontal = 12.dp, vertical = 8.dp),
                                )
                            }
                        }
                    }
                }
            }
            Column(Modifier.padding(top = 20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                for (tab in Friend.entries) {
                    val met = tab in progress.journey.met
                    Box(
                        Modifier
                            .size(56.dp)
                            .background(
                                if (tab == friend) palette.paper else palette.parchmentLip.copy(alpha = 0.6f),
                                RoundedCornerShape(topEnd = 14.dp, bottomEnd = 14.dp),
                            )
                            .clickable(enabled = met) { onFriend(tab) }
                            .clearAndSetSemantics {
                                contentDescription = if (met) "${tab.friendName}'s page" else "A friend at reading level ${tab.level}"
                            },
                        contentAlignment = Alignment.Center,
                    ) {
                        FriendSticker(tab, 38.dp, isSilhouette = !met)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun Section(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title, style = LocalTypography.current.display(18.sp), color = LocalPalette.current.ink)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) { content() }
    }
}

@Composable
private fun Slot(filled: Boolean, art: @Composable () -> Unit) {
    val palette = LocalPalette.current
    Box(
        Modifier
            .size(width = 52.dp, height = 58.dp)
            .then(if (filled) Modifier else Modifier.border(2.dp, palette.muted.copy(alpha = 0.5f), RoundedCornerShape(12.dp))),
        contentAlignment = Alignment.Center,
    ) {
        if (filled) art()
    }
}
