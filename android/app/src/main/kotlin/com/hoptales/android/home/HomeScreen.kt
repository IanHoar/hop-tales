package com.hoptales.android.home

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.StarChip
import com.hoptales.android.world.Sticker
import com.hoptales.content.Friend
import com.hoptales.content.Progress
import com.hoptales.content.Story
import com.hoptales.content.StoryLibrary

@Composable
fun HomeScreen(library: StoryLibrary, progress: Progress, onStory: (Story) -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val insets = WindowInsets.safeDrawing.asPaddingValues()
    Box(Modifier.fillMaxSize().background(palette.page), contentAlignment = Alignment.TopCenter) {
        LazyColumn(
            modifier = Modifier.widthIn(max = 640.dp).fillMaxSize(),
            contentPadding = PaddingValues(
                start = 20.dp,
                end = 20.dp,
                top = insets.calculateTopPadding() + 16.dp,
                bottom = insets.calculateBottomPadding() + 24.dp,
            ),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Hop Tales", style = type.display(34.sp), color = palette.ink, modifier = Modifier.weight(1f))
                    StarChip(progress.stars)
                }
            }
            for (friend in Friend.entries) {
                val stories = library.stories(friend.level)
                if (stories.isEmpty()) continue
                item(key = "friend-${friend.key}") { FriendHeader(friend) }
                items(stories, key = { it.id }) { story ->
                    StoryRow(story, isFinished = progress.isFinished(story), onClick = { onStory(story) })
                }
            }
        }
    }
}

@Composable
private fun FriendHeader(friend: Friend) {
    val palette = LocalPalette.current
    Row(Modifier.padding(top = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        Sticker(if (friend == Friend.HARE) "hare-sit" else "friend-${friend.key}", Modifier.size(52.dp))
        Spacer(Modifier.size(12.dp))
        Column {
            Text(friend.friendName, style = LocalTypography.current.display(22.sp), color = palette.ink)
            Text(friend.world.uppercase(), style = LocalTypography.current.caps(12.sp), color = palette.muted)
        }
    }
}

@Composable
private fun StoryRow(story: Story, isFinished: Boolean, onClick: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().heightIn(min = 64.dp),
        shape = RoundedCornerShape(22.dp),
        color = palette.parchment,
        border = BorderStroke(3.dp, palette.outline),
        shadowElevation = 2.dp,
    ) {
        Row(Modifier.padding(horizontal = 18.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(story.title, style = type.ui(19.sp), color = palette.ink)
                Text(
                    "${story.sentences.size} sentences",
                    style = type.ui(14.sp, FontWeight.Medium),
                    color = palette.muted,
                )
            }
            if (isFinished) {
                Box(
                    Modifier.size(32.dp).background(palette.done, CircleShape).semantics { contentDescription = "Read" },
                    contentAlignment = Alignment.Center,
                ) {
                    Text("✓", style = type.ui(18.sp, FontWeight.Bold), color = palette.onAccent)
                }
            }
        }
    }
}
