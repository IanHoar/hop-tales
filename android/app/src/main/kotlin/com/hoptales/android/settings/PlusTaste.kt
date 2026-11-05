package com.hoptales.android.settings

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.rememberReducedMotion
import com.hoptales.android.world.IdleFriend
import com.hoptales.android.world.MeadowBackdrop
import com.hoptales.android.world.MeadowFraming
import com.hoptales.android.world.MeadowLayout
import com.hoptales.content.Friend
import com.hoptales.content.Story
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

object PlusTaste {
    val friend = Friend.CAT
    const val STORY = "wool-in-the-wind"
    const val START = 900f
}

internal val halfWide = MeadowFraming { width, height, density ->
    val wide = MeadowLayout.wide(width * 2, height * 2, density)
    MeadowLayout(width, wide.pathScale / 2, wide.pathCentre / 2, wideBottom = height)
}

@Composable
fun PlusTaste(modifier: Modifier = Modifier) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val still = rememberReducedMotion()
    val app = LocalContext.current.applicationContext as? HopTalesApplication
    val words = remember(app) {
        app?.library?.all?.firstOrNull { it.id == PlusTaste.STORY }?.sentences?.firstOrNull()?.words
            ?.map { it.leading + it.text + it.trailing }.orEmpty()
    }
    val camera = remember { Animatable(PlusTaste.START) }
    var read by remember { mutableIntStateOf(0) }
    var shown by remember { mutableIntStateOf(1) }
    var hopStart by remember { mutableDoubleStateOf(-1.0) }
    val opacity by animateFloatAsState(shown.toFloat(), tween(400), label = "taste")

    LaunchedEffect(still, words) {
        if (still || words.isEmpty()) return@LaunchedEffect
        while (true) {
            for (index in 1..words.size) {
                delay(1_500)
                read = index
                hopStart = System.nanoTime() / 1e9
                launch { camera.animateTo(camera.value + Story.STEP_PER_WORD.toFloat(), tween(600)) }
            }
            delay(2_200)
            shown = 0
            delay(450)
            read = 0
            camera.snapTo(PlusTaste.START)
            delay(600)
            shown = 1
        }
    }

    Box(
        modifier
            .fillMaxWidth()
            .height(170.dp)
            .clip(RoundedCornerShape(14.dp))
            .alpha(opacity)
            .clearAndSetSemantics {},
    ) {
        MeadowBackdrop(
            progress = camera.value / 2,
            framing = halfWide,
            world = PlusTaste.friend,
            live = false,
        )
        IdleFriend(
            PlusTaste.friend,
            look = null,
            height = 64.dp,
            modifier = Modifier.align(Alignment.BottomCenter).offset(y = 8.dp),
            shadow = paper.shadow,
            hopStart = hopStart.takeIf { it >= 0 },
            hopLift = 10.dp,
        )
        if (words.isNotEmpty()) {
            val current by animateColorAsState(paper.redInk, label = "word")
            Text(
                buildAnnotatedString {
                    words.forEachIndexed { index, word ->
                        if (index > 0) append(" ")
                        val colour = when {
                            index < read -> paper.ink
                            index == read -> current
                            else -> paper.muted
                        }
                        withStyle(SpanStyle(color = colour)) { append(word) }
                    }
                },
                style = type.word(17.sp),
                textAlign = TextAlign.Center,
                maxLines = 2,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(start = 12.dp, end = 12.dp, top = 10.dp)
                    .background(paper.paper.copy(alpha = 0.92f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 14.dp, vertical = 6.dp),
            )
        }
    }
}
