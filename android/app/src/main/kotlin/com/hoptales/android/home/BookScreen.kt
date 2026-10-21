package com.hoptales.android.home

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.FitText
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.pressable
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
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val basket = progress.baskets[friend] ?: Basket()
    val storiesRead = library.stories(friend.level).filter(progress::isFinished)
    val page = remember { Deckle(seed = 19, jitter = 3.dp, step = 14.dp) }
    Column(Modifier.fillMaxSize().background(paper.page)) {
        SheetHeader("Collection book", onDone)
        Row(Modifier.fillMaxWidth().weight(1f)) {
            Box(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
                Column(
                    Modifier
                        .padding(start = 20.dp, bottom = 30.dp)
                        .fillMaxWidth()
                        .dropShadow(page, Shadow(8.dp, paper.shadow, offset = DpOffset(0.dp, 5.dp)))
                        .background(paper.paper, page)
                        .padding(22.dp),
                    verticalArrangement = Arrangement.spacedBy(18.dp),
                ) {
                    Text(
                        "${friend.friendName}'s basket",
                        style = type.display(26.sp),
                        color = paper.ink,
                        modifier = Modifier.semantics { heading() },
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
                            Text("${basket.total}", style = type.display(38.sp).copy(fontFeatureSettings = "tnum"), color = paper.ink)
                            Text("${friend.treat.many} found", style = type.ui(15.sp, FontWeight.Medium), color = paper.muted)
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
                        Section("Stories read", flow = false) { Stamps(storiesRead.map { it.title }) }
                    }
                }
            }
            Column(Modifier.padding(top = 20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                for (tab in Friend.entries) {
                    val met = tab in progress.journey.met
                    Box(
                        Modifier
                            .pressable({ onFriend(tab) }, enabled = met)
                            .clearAndSetSemantics {
                                contentDescription = if (met) "${tab.friendName}'s page" else "A friend at reading level ${tab.level}"
                            }
                            .size(56.dp)
                            .background(
                                if (tab == friend) paper.paper else paper.shade,
                                RoundedCornerShape(topEnd = 14.dp, bottomEnd = 14.dp),
                            ),
                        contentAlignment = Alignment.Center,
                    ) {
                        FriendSticker(
                            tab,
                            38.dp,
                            Modifier.alpha(if (met) 1f else 0.35f),
                            isSilhouette = !met,
                            silhouette = paper.silhouette,
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun Section(title: String, flow: Boolean = true, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title, style = LocalTypography.current.display(18.sp), color = LocalPaper.current.ink)
        if (flow) {
            FlowRow(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) { content() }
        } else {
            content()
        }
    }
}

@Composable
private fun Stamps(titles: List<String>) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val columns = maxOf(1, ((maxWidth + STAMP_SPACING) / (STAMP_MIN_WIDTH + STAMP_SPACING)).toInt())
        val width = (maxWidth - STAMP_SPACING * (columns - 1)) / columns
        Column(verticalArrangement = Arrangement.spacedBy(STAMP_SPACING)) {
            for (row in titles.chunked(columns)) {
                Row(horizontalArrangement = Arrangement.spacedBy(STAMP_SPACING), verticalAlignment = Alignment.CenterVertically) {
                    for (title in row) {
                        Box(Modifier.width(width)) {
                            FitText(
                                title,
                                style = type.display(14.sp),
                                color = paper.ink,
                                minimumScale = 0.7f,
                                modifier = Modifier
                                    .rotate(if (title.length % 2 == 0) -1.5f else 1.5f)
                                    .background(paper.shade, RoundedCornerShape(8.dp))
                                    .padding(horizontal = 12.dp, vertical = 8.dp),
                            )
                        }
                    }
                }
            }
        }
    }
}

private val STAMP_MIN_WIDTH = 130.dp
private val STAMP_SPACING = 8.dp

@Composable
private fun Slot(filled: Boolean, art: @Composable () -> Unit) {
    val dash = LocalPaper.current.muted.copy(alpha = 0.5f)
    Box(Modifier.size(width = 52.dp, height = 58.dp), contentAlignment = Alignment.Center) {
        if (filled) {
            art()
        } else {
            Canvas(Modifier.fillMaxSize()) {
                val line = 2.dp.toPx()
                drawRoundRect(
                    dash,
                    topLeft = Offset(line / 2, line / 2),
                    size = Size(size.width - line, size.height - line),
                    cornerRadius = CornerRadius(12.dp.toPx() - line / 2),
                    style = Stroke(line, pathEffect = PathEffect.dashPathEffect(floatArrayOf(5.dp.toPx(), 4.dp.toPx()))),
                )
            }
        }
    }
}
