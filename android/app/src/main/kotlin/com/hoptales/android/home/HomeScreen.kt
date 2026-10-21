package com.hoptales.android.home

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.StarChip
import com.hoptales.android.world.DressedFriend
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.Rosette
import com.hoptales.android.world.Sticker
import com.hoptales.android.world.WearSticker
import com.hoptales.content.Journey
import com.hoptales.content.Progress
import com.hoptales.content.Story
import com.hoptales.content.StoryLibrary
import com.hoptales.content.StoryStanding
import com.hoptales.content.keepGoing
import com.hoptales.content.newestItem
import com.hoptales.content.outfit
import com.hoptales.content.shelf
import com.hoptales.content.startingStoryID

@Composable
fun HomeScreen(
    library: StoryLibrary,
    progress: Progress,
    onStory: (Story) -> Unit,
    onJourney: () -> Unit = {},
    onFriends: () -> Unit = {},
    onWardrobe: () -> Unit = {},
    onBook: () -> Unit = {},
) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val wardrobe = (LocalContext.current.applicationContext as HopTalesApplication).wardrobe
    val insets = WindowInsets.safeDrawing.asPaddingValues()
    val friend = progress.journey.activeFriend
    val standings = progress.shelf(library)
    val keepGoing = standings.keepGoing(friend.startingStoryID(library))
    val newest = progress.newestItem(friend, wardrobe)
    Box(Modifier.fillMaxSize().background(palette.page), contentAlignment = Alignment.TopCenter) {
        LazyColumn(
            modifier = Modifier.widthIn(max = 560.dp).fillMaxSize(),
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
                    Text(
                        "Hop Tales",
                        style = type.display(34.sp),
                        color = palette.ink,
                        modifier = Modifier.weight(1f).semantics { heading() },
                    )
                    StarChip(progress.stars)
                }
            }
            item {
                Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                    DressedFriend(friend, progress.outfit(friend, wardrobe), 170.dp, Modifier.padding(top = 8.dp))
                    Spacer(Modifier.height(14.dp))
                    LevelChip(library, progress.journey, onJourney)
                }
            }
            if (keepGoing != null) {
                item(key = "keep-going") { KeepGoingCard(keepGoing) { onStory(keepGoing.story) } }
            }
            item {
                Row(Modifier.padding(vertical = 6.dp)) {
                    StickerButton("Friends", onFriends) { FriendSticker(friend, 52.dp) }
                    if (newest != null) {
                        StickerButton("Wardrobe", onWardrobe) { WearSticker(friend, newest, 52.dp, 44.dp) }
                    }
                    StickerButton("Book", onBook) { Sticker("collect-basket", Modifier.size(50.dp)) }
                }
            }
            item {
                Text(
                    "More stories",
                    style = type.display(20.sp),
                    color = palette.ink,
                    modifier = Modifier.padding(top = 6.dp).semantics { heading() },
                )
            }
            items(standings.filter { it.story.id != keepGoing?.story?.id }, key = { it.story.id }) { standing ->
                StoryRow(standing) { onStory(standing.story) }
            }
        }
    }
}

@Composable
private fun LevelChip(library: StoryLibrary, journey: Journey, onClick: () -> Unit) {
    val palette = LocalPalette.current
    val next = journey.nextFriend
    val title = if (next == null) {
        "Level ${journey.level} · ${journey.activeFriend.friendName}"
    } else {
        "Level ${journey.level} · ${journey.steps.toInt()} of ${journey.goal(library).toInt()} to ${next.friendName}"
    }
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp).semantics { contentDescription = "$title. Opens your journey." },
        shape = RoundedCornerShape(18.dp),
        color = palette.parchment,
        border = BorderStroke(3.dp, palette.outline),
        shadowElevation = 2.dp,
    ) {
        Row(Modifier.padding(horizontal = 14.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Rosette(journey.level, Modifier.size(40.dp))
            Spacer(Modifier.size(12.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                Text(
                    title,
                    style = LocalTypography.current.display(16.sp),
                    color = palette.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (next != null) {
                    Box(Modifier.fillMaxWidth().height(8.dp).clip(CircleShape).background(palette.muted.copy(alpha = 0.22f))) {
                        Box(Modifier.fillMaxWidth(journey.fill(library).toFloat()).height(8.dp).background(palette.gold, CircleShape))
                    }
                }
            }
            Spacer(Modifier.size(12.dp))
            MapGlyph(palette.ink)
        }
    }
}

@Composable
fun MapGlyph(colour: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.size(22.dp)) {
        val w = size.width
        val h = size.height
        val stroke = Stroke(width = 2.dp.toPx(), join = StrokeJoin.Round)
        val outline = Path().apply {
            moveTo(0f, h * 0.18f)
            lineTo(w / 3, 0f)
            lineTo(w * 2 / 3, h * 0.18f)
            lineTo(w, 0f)
            lineTo(w, h * 0.82f)
            lineTo(w * 2 / 3, h)
            lineTo(w / 3, h * 0.82f)
            lineTo(0f, h)
            close()
        }
        drawPath(outline, colour, style = stroke)
        drawLine(colour, Offset(w / 3, 0f), Offset(w / 3, h * 0.82f), stroke.width)
        drawLine(colour, Offset(w * 2 / 3, h * 0.18f), Offset(w * 2 / 3, h), stroke.width)
    }
}

@Composable
private fun KeepGoingCard(standing: StoryStanding, onClick: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val heading = if (standing.isCurrent) "Keep reading" else "Start here"
    val total = standing.story.sentences.size
    val meta = (standing.standing as? StoryStanding.Standing.InProgress)?.let { "Sentence ${total - it.remaining + 1} of $total" }
        ?: "Your next story"
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().clearAndSetSemantics {
            contentDescription = "$heading. ${standing.story.title}. $meta."
            role = Role.Button
        },
        shape = RoundedCornerShape(20.dp),
        color = palette.paper,
        border = BorderStroke(3.dp, palette.outline),
        shadowElevation = 2.dp,
    ) {
        Row(Modifier.padding(horizontal = 16.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(heading.uppercase(), style = type.caps(12.sp), color = palette.muted)
                Text(standing.story.title, style = type.display(19.sp), color = palette.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(meta, style = type.ui(13.sp, FontWeight.Medium), color = palette.muted)
            }
            PlayButton()
        }
    }
}

@Composable
private fun PlayButton() {
    val palette = LocalPalette.current
    Box(
        Modifier.size(46.dp).clip(CircleShape).background(palette.red).border(3.dp, palette.outline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Canvas(Modifier.size(16.dp)) {
            val play = Path().apply {
                moveTo(size.width * 0.15f, 0f)
                lineTo(size.width, size.height / 2)
                lineTo(size.width * 0.15f, size.height)
                close()
            }
            drawPath(play, palette.onTeal)
        }
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.StickerButton(title: String, onClick: () -> Unit, art: @Composable () -> Unit) {
    val palette = LocalPalette.current
    Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Surface(
            onClick = onClick,
            modifier = Modifier.size(84.dp).semantics { contentDescription = title },
            shape = CircleShape,
            color = palette.parchment,
            border = BorderStroke(3.dp, palette.outline),
            shadowElevation = 2.dp,
        ) {
            Box(contentAlignment = Alignment.Center) { art() }
        }
        Text(title, style = LocalTypography.current.display(16.sp), color = palette.ink)
    }
}

@Composable
private fun StoryRow(standing: StoryStanding, onClick: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().heightIn(min = 64.dp).clearAndSetSemantics {
            contentDescription = "${standing.story.title}. ${standing.subtitle}"
            role = Role.Button
        },
        shape = RoundedCornerShape(22.dp),
        color = palette.parchment,
        border = BorderStroke(3.dp, palette.outline),
        shadowElevation = 2.dp,
    ) {
        Row(Modifier.padding(horizontal = 18.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(standing.story.title, style = type.ui(19.sp), color = palette.ink)
                Text(standing.subtitle, style = type.ui(14.sp, FontWeight.Medium), color = palette.muted)
            }
            when (standing.standing) {
                StoryStanding.Standing.Finished -> Box(
                    Modifier.size(32.dp).background(palette.done, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text("✓", style = type.ui(18.sp, FontWeight.Bold), color = palette.onAccent)
                }

                is StoryStanding.Standing.InProgress -> Sticker("collect-star", Modifier.size(26.dp))

                StoryStanding.Standing.Unread -> Text("New", style = type.ui(14.sp), color = palette.red)
            }
        }
    }
}
