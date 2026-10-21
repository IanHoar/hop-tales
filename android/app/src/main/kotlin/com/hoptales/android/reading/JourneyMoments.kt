package com.hoptales.android.reading

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperChip
import com.hoptales.android.design.paperChip
import com.hoptales.android.design.pressable
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.Sticker
import com.hoptales.android.world.TreatSticker
import com.hoptales.android.world.WearSticker
import com.hoptales.content.CollectedTreat
import com.hoptales.content.Friend
import com.hoptales.content.JourneyMoment
import com.hoptales.content.LevelUp
import com.hoptales.content.Levels
import com.hoptales.content.Story
import com.hoptales.content.StoryTreat
import com.hoptales.content.WardrobeItem
import com.hoptales.content.unlockedItem
import com.hoptales.reading.ReadingState
import kotlin.math.roundToInt

@Composable
fun TallyCard(tally: JourneyMoment.Tally, found: JourneyMoment.TreatFound?, modifier: Modifier = Modifier) {
    val type = LocalTypography.current
    val reached = tally.total >= tally.goal
    val paper = LocalPaper.current
    val card = remember { Deckle(seed = 21, jitter = 2.4.dp, step = 10.dp) }
    Column(
        modifier
            .widthIn(max = 320.dp)
            .rotate(-1.5f)
            .dropShadow(card, Shadow(8.dp, paper.shadow, offset = DpOffset(0.dp, 5.dp)))
            .background(paper.paper, card)
            .padding(16.dp)
            .clearAndSetSemantics {
                contentDescription = "${tally.steps.roundToInt()} steps. ${tally.total.toInt()} of ${tally.goal.toInt()} on the path to " +
                    "${tally.next.friendName}." +
                    if (tally.storiesLeft > 0 && reached) " ${tally.storiesLeft} more stories to read first." else ""
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        found?.let { (treat, trail) ->
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                TreatSticker(treat.friend, 26.dp, isGolden = treat.isGolden)
                Text(treatLine(treat, trail), style = type.display(17.sp), color = paper.ink)
            }
        }
        if (tally.bigWords > 0) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Sticker("collect-star", Modifier.size(22.dp))
                Text(
                    if (tally.bigWords == 1) "A big word read!" else "${tally.bigWords} big words read!",
                    style = type.display(17.sp),
                    color = paper.ink,
                )
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            FriendSticker(tally.next, 46.dp, isSilhouette = !reached)
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("The path to ${tally.next.friendName}", style = type.display(16.sp), color = paper.ink)
                PathRibbon(if (tally.goal > 0) tally.total / tally.goal else 1.0)
                Text(
                    "+${tally.steps.roundToInt()} steps · ${tally.total.toInt()} of ${tally.goal.toInt()}",
                    style = type.ui(13.sp, FontWeight.Medium),
                    color = paper.muted,
                )
                if (tally.storiesLeft > 0 && reached) {
                    Text(
                        if (tally.storiesLeft == 1) {
                            "Read one more story to meet ${tally.next.friendName}"
                        } else {
                            "Read ${tally.storiesLeft} more stories to meet ${tally.next.friendName}"
                        },
                        style = type.ui(13.sp),
                        color = paper.ink,
                    )
                }
            }
        }
    }
}

fun treatLine(treat: CollectedTreat, trail: Int): String {
    if (treat.isTrail) {
        val treats = treat.friend.treat.many.replaceFirstChar { it.uppercase() }
        return "$treats for ${treat.friend.friendName} · $trail of ${Levels.trailGoal(treat.friend.level - 1)}"
    }
    return if (treat.isGolden) {
        "A golden ${treat.friend.treat.one}! That counts ${treat.worth}."
    } else {
        "You found a ${treat.friend.treat.one}!"
    }
}

@Composable
fun PathRibbon(fill: Double, modifier: Modifier = Modifier) {
    val palette = LocalPalette.current
    Box(modifier.width(180.dp).height(12.dp).clip(CircleShape).background(palette.muted.copy(alpha = 0.22f))) {
        Box(Modifier.fillMaxWidth(fill.coerceIn(0.0, 1.0).toFloat()).height(12.dp).background(palette.gold, CircleShape))
    }
}

@Composable
fun CalloutCard(
    moment: JourneyMoment,
    item: WardrobeItem?,
    leads: Boolean,
    primary: () -> Unit,
    dismiss: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val type = LocalTypography.current
    val paper = LocalPaper.current
    var opened by rememberSaveable(moment.toString()) { mutableStateOf(false) }
    val waitsForOpening = moment is JourneyMoment.BasketFull && !opened
    val card = remember { Deckle(seed = 33, jitter = 2.6.dp, step = 10.dp) }
    Column(
        modifier
            .padding(horizontal = 24.dp)
            .widthIn(max = 340.dp)
            .rotate(-1f)
            .dropShadow(card, Shadow(10.dp, paper.shadow, offset = DpOffset(0.dp, 6.dp)))
            .background(paper.paper, card)
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        when (moment) {
            is JourneyMoment.BigStoryReady -> FriendSticker(moment.friend, 120.dp)
            is JourneyMoment.NotYet -> FriendSticker(moment.friend, 120.dp)
            is JourneyMoment.NewFriend -> FriendSticker(moment.friend, 120.dp)
            is JourneyMoment.BasketFull -> PresentReveal(moment.friend, item, opened) { opened = true }
            else -> Unit
        }
        Text(title(moment), style = type.display(22.sp), color = paper.ink, textAlign = TextAlign.Center)
        Text(
            detail(moment, item, opened),
            style = type.ui(15.sp, FontWeight.Medium),
            color = paper.ink.copy(alpha = 0.85f),
            textAlign = TextAlign.Center,
        )
        Row(
            Modifier.padding(top = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (waitsForOpening) {
                Text("Tap the present to open it", style = type.ui(14.sp, FontWeight.SemiBold), color = paper.muted)
            } else {
                secondary(moment)?.let { CardButton(it, filled = false, onClick = dismiss) }
                CardButton(primaryTitle(moment), filled = true, onClick = if (leads) primary else dismiss)
            }
        }
    }
}

@Composable
private fun PresentReveal(friend: Friend, item: WardrobeItem?, opened: Boolean, open: () -> Unit) {
    Box(
        Modifier
            .height(120.dp)
            .clickable(enabled = !opened, onClick = open)
            .semantics { contentDescription = if (opened) item?.name ?: "A present" else "A present. Double tap to open it." },
        contentAlignment = Alignment.Center,
    ) {
        if (opened) {
            Sticker("collect-present-open", Modifier.size(96.dp).offset(x = (-40).dp))
            if (item != null) WearSticker(friend, item, 96.dp, 78.dp, Modifier.offset(x = 56.dp, y = (-24).dp))
        } else {
            Sticker("collect-present", Modifier.size(110.dp))
        }
    }
}

@Composable
private fun CardButton(text: String, filled: Boolean, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val style = LocalTypography.current.display(16.sp)
    if (filled) {
        Box(
            Modifier
                .pressable(onClick)
                .height(46.dp)
                .background(paper.red, CircleShape)
                .border(3.dp, paper.rim, CircleShape)
                .padding(horizontal = 18.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(text, style = style, color = paper.onRed)
        }
    } else {
        PaperChip(height = 46.dp, onClick = onClick) {
            Text(text, style = style, color = paper.ink)
        }
    }
}

private fun title(moment: JourneyMoment): String = when (moment) {
    is JourneyMoment.BigStoryReady -> "${moment.friend.friendName} has a bigger story!"
    is JourneyMoment.NotYet -> "${moment.friend.friendName} will wait for you at ${moment.friend.place}."
    is JourneyMoment.NewFriend -> "Reading level ${moment.friend.level}!"
    is JourneyMoment.BasketFull -> "A full basket!"
    else -> ""
}

private fun detail(moment: JourneyMoment, item: WardrobeItem?, opened: Boolean): String = when (moment) {
    is JourneyMoment.BigStoryReady -> "The path is full. Read ${moment.friend.friendName}'s story to go to ${moment.friend.place} together."

    is JourneyMoment.NotYet -> "The path stays full. Try the big story again whenever you like."

    is JourneyMoment.NewFriend -> {
        val friend = moment.friend
        "${friend.friendName} is your new friend. ${friend.friendName} gave you ${friend.gift}." +
            if (moment.via == LevelUp.TRAIL) " You found all the ${friend.treat.many}!" else ""
    }

    is JourneyMoment.BasketFull -> if (opened) {
        "It's ${item?.let { "a ${it.name.lowercase()}" } ?: "a present"} for ${moment.friend.friendName}!"
    } else {
        "You filled ${moment.friend.friendName}'s basket of ${moment.friend.treat.many}. There's a present inside!"
    }

    else -> ""
}

private fun primaryTitle(moment: JourneyMoment): String = when (moment) {
    is JourneyMoment.BigStoryReady -> "Try the big story"
    is JourneyMoment.NotYet -> "OK"
    is JourneyMoment.NewFriend -> "Go to ${moment.friend.place}"
    is JourneyMoment.BasketFull -> "Try it on"
    else -> ""
}

private fun secondary(moment: JourneyMoment): String? = when (moment) {
    is JourneyMoment.BigStoryReady -> "Not yet"
    is JourneyMoment.NewFriend, is JourneyMoment.BasketFull -> "Later"
    else -> null
}

@Composable
fun BasketChip(treat: StoryTreat, modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    Row(
        modifier
            .clearAndSetSemantics { contentDescription = "You found a ${treat.friend.treat.one}." }
            .height(42.dp)
            .paperChip(CircleShape, rim = 3.dp)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        if (treat.isTrail) {
            FriendSticker(treat.friend, 28.dp, isSilhouette = true)
        } else {
            Sticker("collect-basket", Modifier.size(28.dp))
        }
        TreatSticker(treat.friend, 22.dp)
        Text("+1", style = LocalTypography.current.display(16.sp), color = paper.ink)
    }
}

@Composable
fun JourneyPanel(state: ReadingState, onStory: (Story) -> Unit, onTryItOn: (Friend) -> Unit, dismiss: () -> Unit) {
    val app = LocalContext.current.applicationContext as HopTalesApplication
    BoxWithConstraints(Modifier.fillMaxSize().safeDrawingPadding(), contentAlignment = Alignment.TopCenter) {
        val top = maxHeight * (PANEL_Y / PANEL_REFERENCE_HEIGHT)
        val callout = state.callout
        val tally = state.tally
        if (callout != null) {
            val item = callout.unlockedItem(app.wardrobe)
            val story = callout.story(app.library)
            key(callout) {
                CalloutCard(
                    moment = callout,
                    item = item,
                    leads = story != null || item != null,
                    primary = {
                        story?.let(onStory)
                        if (callout is JourneyMoment.BasketFull) onTryItOn(callout.friend)
                    },
                    dismiss = dismiss,
                    modifier = Modifier.padding(top = top),
                )
            }
        } else if (tally != null) {
            TallyCard(tally, state.collectedTreat, Modifier.padding(top = top))
        }
    }
}

private const val PANEL_Y = 110f
private const val PANEL_REFERENCE_HEIGHT = 844f
