package com.hoptales.android.home

import android.provider.Settings
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.hoptales.android.design.FitText
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.paperChip
import com.hoptales.android.design.pressable
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.IdleFriend
import com.hoptales.content.Friend

@Composable
fun NewFriendCard(friend: Friend, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val shape = RoundedCornerShape(20.dp)
    val line = "Read ${friend.friendName}'s big story to reach Level ${friend.level}"
    Row(
        Modifier
            .fillMaxWidth()
            .pressable(onClick)
            .clearAndSetSemantics {
                contentDescription = "A new friend. Meet ${friend.friendName}. $line."
                role = Role.Button
            }
            .dropShadow(shape, Shadow(3.dp, paper.shadow.copy(alpha = paper.shadow.alpha * 0.55f), offset = DpOffset(0.dp, 2.dp)))
            .background(paper.rim, shape)
            .border(3.dp, paper.red, shape)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(62.dp), contentAlignment = Alignment.Center) { FriendSticker(friend, 58.dp) }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("A NEW FRIEND", style = type.caps(12.sp).copy(letterSpacing = 0.06.em), color = paper.redInk)
            FitText("Meet ${friend.friendName}", style = type.display(19.sp), color = paper.ink, minimumScale = 0.8f)
            Text(line, style = type.ui(13.sp, FontWeight.Medium), color = paper.muted)
        }
        Box(Modifier.size(46.dp).paperChip(CircleShape, fill = paper.red), contentAlignment = Alignment.Center) {
            PlayGlyph(paper.onRed, Modifier.size(16.dp))
        }
    }
}

@Composable
fun WaitingFriend(friend: Friend, height: Dp, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val context = LocalContext.current
    val still = remember { Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
    val bob by rememberInfiniteTransition(label = "waiting").animateFloat(
        initialValue = 0f,
        targetValue = if (still) 0f else -4f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse),
        label = "bob",
    )
    Box(
        modifier
            .pressable(onClick)
            .clearAndSetSemantics {
                contentDescription = "${friend.friendName} is waiting with a big story"
                role = Role.Button
            },
        contentAlignment = Alignment.BottomCenter,
    ) {
        IdleFriend(friend, look = null, height = height, shadow = paper.shadow)
        Text(
            "New!",
            style = LocalTypography.current.ui(13.sp, FontWeight.Bold),
            color = paper.onRed,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .graphicsLayer { translationY = (bob - 26f).dp.toPx() }
                .background(paper.red, CircleShape)
                .padding(horizontal = 10.dp, vertical = 4.dp),
        )
    }
}
