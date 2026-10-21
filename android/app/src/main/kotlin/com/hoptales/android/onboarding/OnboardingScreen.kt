package com.hoptales.android.onboarding

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.BackChip
import com.hoptales.android.design.ChoiceSurface
import com.hoptales.android.design.LocalFold
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperButton
import com.hoptales.android.design.PaperChoice
import com.hoptales.android.design.ProgressPills
import com.hoptales.android.design.field
import com.hoptales.android.world.IdleFriend
import com.hoptales.android.world.MeadowBackdrop
import com.hoptales.android.world.SoundMarksExamples
import com.hoptales.android.world.Sticker
import com.hoptales.android.world.rememberArt
import com.hoptales.content.Friend
import com.hoptales.content.Phonics
import com.hoptales.onboarding.Authorization
import com.hoptales.onboarding.OnboardingNext
import com.hoptales.onboarding.OnboardingState
import com.hoptales.onboarding.OnboardingStep

class OnboardingActions(
    val nameChanged: (String) -> Unit = {},
    val friendPicked: (Friend) -> Unit = {},
    val soundButtonsPicked: (Boolean) -> Unit = {},
    val backTapped: () -> Unit = {},
    val primaryTapped: () -> Unit = {},
)

@Composable
fun OnboardingScreen(key: String) {
    val context = LocalContext.current
    val app = context.applicationContext as HopTalesApplication
    val model: OnboardingViewModel = viewModel(key = key) {
        val granted = ContextCompat.checkSelfPermission(app, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        OnboardingViewModel(app, granted)
    }
    val state by model.state.collectAsStateWithLifecycle()
    val request = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission(), model::microphoneAnswered)
    BackHandler(enabled = !state.isFirstStep, onBack = model::backTapped)
    OnboardingContent(
        state,
        OnboardingActions(
            nameChanged = model::nameChanged,
            friendPicked = model::friendPicked,
            soundButtonsPicked = model::soundButtonsPicked,
            backTapped = model::backTapped,
            primaryTapped = {
                if (model.primaryTapped() == OnboardingNext.RequestMicrophone) request.launch(Manifest.permission.RECORD_AUDIO)
            },
        ),
    )
}

@Composable
fun OnboardingContent(state: OnboardingState, actions: OnboardingActions) {
    val palette = LocalPalette.current
    val statusBar = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    val fold = LocalFold.current
    BoxWithConstraints(Modifier.background(palette.page)) {
        val area = Size(maxWidth.value, maxHeight.value)
        val room = fold?.room(area)
        val top = maxOf(statusBar, (room?.top ?: 0f).dp) + 12.dp
        val sheetHeight = minOf(maxHeight * 0.61f - top, room?.let { it.bottom.dp - top } ?: Dp.Infinity)
        MeadowBackdrop()
        if (fold != null && !fold.runsAcross) StandingHare(fold.stage(area))
        Box(
            Modifier
                .padding(
                    top = top,
                    start = room?.left?.takeIf { it > 0f }?.let { it.dp + 12.dp } ?: 0.dp,
                    end =
                    room?.let { maxWidth - it.right.dp } ?: 0.dp,
                )
                .imePadding()
                .align(Alignment.BottomCenter),
        ) {
            Surface(
                modifier = Modifier.widthIn(max = 560.dp).fillMaxWidth().heightIn(min = sheetHeight),
                shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
                color = palette.paper,
                border = BorderStroke(3.dp, palette.outline),
                shadowElevation = 10.dp,
            ) {
                Column(
                    Modifier.padding(start = 24.dp, end = 24.dp, top = 22.dp, bottom = maxOf(bottom, 16.dp) + 8.dp),
                    verticalArrangement = Arrangement.SpaceBetween,
                ) {
                    Column(Modifier.weight(1f, fill = false)) {
                        Header(state, actions.backTapped)
                        Spacer(Modifier.height(16.dp))
                        AnimatedContent(
                            targetState = state.step,
                            transitionSpec = {
                                (slideInHorizontally(tween(350)) { 18 } + fadeIn(tween(350))) togetherWith
                                    fadeOut(tween(200))
                            },
                            modifier = Modifier.verticalScroll(rememberScrollState()),
                            label = "step",
                        ) { step -> StepPage(state.copy(step = step), actions) }
                    }
                    Spacer(Modifier.height(16.dp))
                    PaperButton(state.primaryTitle, enabled = state.primaryEnabled, onClick = actions.primaryTapped)
                }
            }
        }
    }
}

@Composable
private fun StandingHare(stage: Rect) {
    val height = minOf(160f, stage.width * 0.5f)
    Box(
        Modifier
            .offset(x = (stage.center.x - height).dp, y = (stage.bottom * 0.86f - height).dp)
            .size((height * 2).dp, height.dp),
        contentAlignment = Alignment.BottomCenter,
    ) {
        IdleFriend(Friend.HARE, null, height.dp)
    }
}

@Composable
private fun Header(state: OnboardingState, onBack: () -> Unit) {
    val palette = LocalPalette.current
    Box(Modifier.fillMaxWidth().height(44.dp), contentAlignment = Alignment.Center) {
        ProgressPills(current = state.stepNumber - 1, count = state.stepCount)
        if (!state.isFirstStep) {
            BackChip(Modifier.align(Alignment.CenterStart).offset(x = (-4).dp), description = "Back", onClick = onBack)
        }
    }
}

private val OnboardingStep.title: String
    get() = when (this) {
        OnboardingStep.NAME -> "What should we call you?"
        OnboardingStep.LISTENING -> "Can Hop Tales use the microphone?"
        OnboardingStep.FRIEND -> "Who should your reader start with?"
        OnboardingStep.SOUND_BUTTONS -> "Show dots and dashes under the sounds?"
    }

private val OnboardingStep.detail: String
    get() = when (this) {
        OnboardingStep.NAME ->
            "A first name, a nickname or anything familiar is perfect. We use it to say hello, and it's never sent to us."

        OnboardingStep.LISTENING ->
            "The microphone lets Hop Tales hear your child read, so the hare can hop to the next word. Everything is heard " +
                "on this device. Nothing is recorded, and nothing is sent anywhere."

        OnboardingStep.FRIEND ->
            "Pick the friend whose words look about right, and let your reader have a look too. You can change this later."

        OnboardingStep.SOUND_BUTTONS ->
            "Sound buttons put a dot under each sound and a dash under letters that make one sound together, like sh. " +
                "Many schools teach blending this way. You can change this later."
    }

@Composable
private fun StepPage(state: OnboardingState, actions: OnboardingActions) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(
            "STEP ${state.stepNumber} OF ${state.stepCount}",
            style = type.caps(13.sp),
            color = palette.muted,
            modifier = Modifier.semantics { contentDescription = "Step ${state.stepNumber} of ${state.stepCount}" },
        )
        Text(state.step.title, style = type.display(28.sp), color = palette.ink, modifier = Modifier.semantics { heading() })
        Text(state.step.detail, style = type.ui(16.sp, FontWeight.Medium), color = palette.ink.copy(alpha = 0.85f))
        Box(Modifier.padding(top = 4.dp)) {
            when (state.step) {
                OnboardingStep.NAME -> NameField(state.childName, actions.nameChanged) {
                    if (state.primaryEnabled) actions.primaryTapped()
                }

                OnboardingStep.LISTENING -> MicrophoneNote(state.authorization)

                OnboardingStep.FRIEND -> FriendChoices(state.startingFriend, actions.friendPicked)

                OnboardingStep.SOUND_BUTTONS -> SoundButtonChoices(state.soundButtons, actions.soundButtonsPicked)
            }
        }
    }
}

@Composable
fun NameField(name: String, onChange: (String) -> Unit, onSubmit: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val shape = RoundedCornerShape(16.dp)
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Name or nickname", style = type.ui(14.sp), color = palette.muted)
        BasicTextField(
            value = name,
            onValueChange = onChange,
            singleLine = true,
            textStyle = type.display(22.sp).copy(color = palette.ink),
            cursorBrush = SolidColor(palette.ink),
            keyboardOptions = KeyboardOptions(
                capitalization = KeyboardCapitalization.Words,
                autoCorrectEnabled = false,
                imeAction = ImeAction.Done,
            ),
            keyboardActions = KeyboardActions(onDone = { onSubmit() }),
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp)
                .background(palette.field, shape)
                .border(3.dp, palette.parchmentLip, shape)
                .semantics { contentDescription = "Name or nickname" },
            decorationBox = { field ->
                Box(Modifier.padding(horizontal = 16.dp), contentAlignment = Alignment.CenterStart) { field() }
            },
        )
    }
}

@Composable
private fun MicrophoneNote(authorization: Authorization?) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    when (authorization) {
        null -> Text(
            "Android will ask you to allow the microphone.",
            style = type.ui(13.sp, FontWeight.Medium),
            color = palette.muted,
        )

        Authorization.AUTHORIZED -> Row(verticalAlignment = Alignment.CenterVertically) {
            Text("✓", style = type.ui(20.sp, FontWeight.Bold), color = LocalPaper.current.sageDeep)
            Spacer(Modifier.width(8.dp))
            Text("Microphone allowed.", style = type.ui(16.sp), color = LocalPaper.current.sageDeep)
        }

        Authorization.DENIED -> Note(
            "The microphone is off. You can allow it later in the Settings app, under Apps and Hop Tales. Until then, " +
                "tap a word to hear it.",
        )

        Authorization.UNSUPPORTED -> Note("This device can't recognise speech on its own, so stories use tap to hear instead.")
    }
}

@Composable
private fun Note(text: String) {
    Text(text, style = LocalTypography.current.ui(15.sp, FontWeight.Medium), color = LocalPalette.current.ink)
}

private val Friend.sticker: String get() = if (this == Friend.HARE) "hare-sit" else "friend-$key"

@Composable
private fun FriendChoices(selected: Friend?, onPick: (Friend) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        for (friend in Friend.starters) FriendChoice(friend, friend == selected) { onPick(friend) }
        LaterFriends(Modifier.padding(top = 6.dp))
    }
}

@Composable
private fun FriendChoice(friend: Friend, isSelected: Boolean, onClick: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    ChoiceSurface(
        selected = isSelected,
        onClick = onClick,
        label = "${friend.friendName}, ${friend.stage}. Words like ${friend.examples.joinToString(", ")}.",
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Sticker(friend.sticker, Modifier.size(58.dp))
            Spacer(Modifier.width(14.dp))
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(friend.friendName, style = type.display(19.sp), color = palette.ink, modifier = Modifier.alignByBaseline())
                    Spacer(Modifier.width(8.dp))
                    Text(friend.stage, style = type.ui(14.sp), color = palette.muted, modifier = Modifier.alignByBaseline())
                }
                Text(friend.examples.joinToString(" · "), style = type.word(18.sp), color = palette.ink.copy(alpha = 0.85f))
            }
        }
    }
}

@Composable
private fun LaterFriends(modifier: Modifier = Modifier) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    val later = Friend.entries.filter { it !in Friend.starters }
    Column(
        modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Bottom) {
            for (friend in later) {
                val art = rememberArt(friend.sticker) ?: continue
                Image(
                    art,
                    contentDescription = null,
                    modifier = Modifier.height(34.dp).alpha(0.45f),
                    contentScale = ContentScale.Fit,
                    colorFilter = ColorFilter.tint(palette.ink),
                )
            }
        }
        Text(
            "${later.size} more friends join as your reader gets stronger",
            style = type.ui(13.sp, FontWeight.Medium),
            color = palette.muted,
            textAlign = TextAlign.Center,
        )
        Text(Phonics.STANDARD, style = type.ui(12.sp), color = palette.muted, textAlign = TextAlign.Center)
    }
}

@Composable
private fun SoundButtonChoices(selected: Boolean?, onPick: (Boolean) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        ChoiceSurface(selected = false, onClick = null) {
            SoundMarksExamples(modifier = Modifier.padding(vertical = 14.dp))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            PaperChoice("Yes, show them", selected = selected == true, modifier = Modifier.weight(1f)) { onPick(true) }
            PaperChoice("No thanks", selected = selected == false, modifier = Modifier.weight(1f)) { onPick(false) }
        }
    }
}
