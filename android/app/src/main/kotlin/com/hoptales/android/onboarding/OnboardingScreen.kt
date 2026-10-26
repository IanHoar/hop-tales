package com.hoptales.android.onboarding

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.ChoicePair
import com.hoptales.android.design.ChoiceSurface
import com.hoptales.android.design.Deckle
import com.hoptales.android.design.EaseOut
import com.hoptales.android.design.Glyphs
import com.hoptales.android.design.LocalFold
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperButton
import com.hoptales.android.design.PaperChoice
import com.hoptales.android.design.ProgressPills
import com.hoptales.android.design.paperField
import com.hoptales.android.design.pressable
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.IdleFriend
import com.hoptales.android.world.MeadowBackdrop
import com.hoptales.android.world.SoundMarksExamples
import com.hoptales.content.Friend
import com.hoptales.onboarding.Authorization
import com.hoptales.onboarding.OnboardingNext
import com.hoptales.onboarding.OnboardingState
import com.hoptales.onboarding.OnboardingStep

class OnboardingActions(
    val nameChanged: (String) -> Unit = {},
    val soundButtonsPicked: (Boolean) -> Unit = {},
    val backupPicked: (Boolean) -> Unit = {},
    val backTapped: () -> Unit = {},
    val primaryTapped: () -> Unit = {},
)

@Composable
fun OnboardingScreen(key: String, onFinished: (offersPlus: Boolean) -> Unit = {}) {
    val context = LocalContext.current
    val app = context.applicationContext as HopTalesApplication
    val model: OnboardingViewModel = viewModel(key = key) {
        val granted = ContextCompat.checkSelfPermission(app, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        OnboardingViewModel(app, granted)
    }
    val state by model.state.collectAsStateWithLifecycle()
    val request = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission(), model::microphoneAnswered)
    BackHandler(enabled = !state.isWelcoming, onBack = model::backTapped)
    OnboardingContent(
        state,
        OnboardingActions(
            nameChanged = model::nameChanged,
            soundButtonsPicked = model::soundButtonsPicked,
            backupPicked = model::backupPicked,
            backTapped = model::backTapped,
            primaryTapped = {
                when (model.primaryTapped()) {
                    OnboardingNext.RequestMicrophone -> request.launch(Manifest.permission.RECORD_AUDIO)
                    is OnboardingNext.Finished -> onFinished(model.offersPlus)
                    else -> Unit
                }
            },
        ),
    )
}

private const val STEP_MILLIS = 350
private val STEP_SLIDE = 18.dp

@Composable
fun OnboardingContent(state: OnboardingState, actions: OnboardingActions) {
    val paper = LocalPaper.current
    val statusBar = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    val fold = LocalFold.current
    val slide = with(LocalDensity.current) { STEP_SLIDE.roundToPx() }
    BoxWithConstraints(Modifier.background(paper.page)) {
        val area = Size(maxWidth.value, maxHeight.value)
        val room = fold?.room(area)
        val top = maxOf(statusBar, (room?.top ?: 0f).dp) + 12.dp
        val sheetHeight = minOf(maxHeight * 0.61f, room?.let { it.bottom.dp - top } ?: Dp.Infinity)
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
            val sheet = remember { SheetEdge(Deckle(seed = 21, jitter = 3.dp, step = 16.dp), overhang = 12.dp) }
            Box(
                Modifier
                    .widthIn(max = 560.dp)
                    .fillMaxWidth()
                    .heightIn(min = sheetHeight)
                    .dropShadow(sheet, Shadow(10.dp, paper.shadow, offset = DpOffset(0.dp, (-4).dp)))
                    .background(paper.paper, sheet),
                propagateMinConstraints = true,
            ) {
                Column(
                    Modifier.padding(start = 24.dp, end = 24.dp, top = 22.dp, bottom = maxOf(bottom, 16.dp) + 8.dp),
                    verticalArrangement = Arrangement.SpaceBetween,
                ) {
                    Column(Modifier.weight(1f, fill = false)) {
                        Header(state, actions.backTapped)
                        Spacer(Modifier.height(16.dp))
                        AnimatedContent(
                            targetState = state.step.takeUnless { state.isWelcoming },
                            transitionSpec = {
                                (
                                    slideInHorizontally(tween(STEP_MILLIS, easing = EaseOut)) { slide } +
                                        fadeIn(tween(STEP_MILLIS, easing = EaseOut))
                                    ) togetherWith
                                    fadeOut(tween(STEP_MILLIS, easing = EaseOut)) using
                                    SizeTransform(clip = false) { _, _ -> snap() }
                            },
                            modifier = Modifier.verticalScroll(rememberScrollState()),
                            label = "step",
                        ) { step -> if (step == null) WelcomePage() else StepPage(state.copy(step = step), actions) }
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
        IdleFriend(Friend.HARE, null, height.dp, shadow = LocalPaper.current.shadow)
    }
}

@Composable
private fun Header(state: OnboardingState, onBack: () -> Unit) {
    val paper = LocalPaper.current
    Box(Modifier.fillMaxWidth().height(24.dp), contentAlignment = Alignment.Center) {
        if (!state.isWelcoming) {
            ProgressPills(current = state.stepNumber - 1, count = state.stepCount)
            Box(
                Modifier
                    .align(Alignment.CenterStart)
                    .offset(x = (-12).dp)
                    .requiredSize(44.dp)
                    .semantics { contentDescription = "Back" }
                    .pressable(onBack),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Glyphs.chevronLeft, contentDescription = null, tint = paper.ink, modifier = Modifier.size(22.dp))
            }
        }
    }
}

private class SheetEdge(private val edge: Shape, private val overhang: Dp) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        edge.createOutline(Size(size.width, size.height + with(density) { overhang.toPx() }), layoutDirection, density)
}

private val OnboardingStep.title: String
    get() = when (this) {
        OnboardingStep.BACKUP -> "Back up to your Google account?"
        OnboardingStep.NAME -> "What should we call you?"
        OnboardingStep.LISTENING -> "Can Hop Tales use the microphone?"
        OnboardingStep.AHEAD -> "Reading grows with your reader"
        OnboardingStep.SOUND_BUTTONS -> "Show dots and dashes under the sounds?"
    }

private val OnboardingStep.detail: String
    get() = when (this) {
        OnboardingStep.BACKUP ->
            "Setting Hop Tales up again on a new phone or tablet? Choose Yes and Android keeps your reader's name and " +
                "progress in your own Google account backup, so they come back with the app. Only you can see it. We never " +
                "do. You can change this later."

        OnboardingStep.NAME ->
            "A first name, a nickname or anything familiar is perfect. We use it to say hello, and it's never sent to us."

        OnboardingStep.LISTENING ->
            "The microphone lets Hop Tales hear your child read, so the hare can hop to the next word. Everything is heard " +
                "on this device. Nothing is recorded, and nothing is sent anywhere."

        OnboardingStep.AHEAD ->
            "Your reader starts with ${Friend.at(1).friendName} and short, simple words. With every story they read, " +
                "they'll meet new friends and move on to longer, trickier words."

        OnboardingStep.SOUND_BUTTONS ->
            "Sound buttons put a dot under each sound and a dash under letters that make one sound together, like sh. " +
                "Many schools teach blending this way. You can change this later."
    }

private const val WELCOME_SUMMARY =
    "Your child reads each word out loud, and the hare hops along the path to the next one. " +
        "Hop Tales listens on this device. Nothing is recorded or sent anywhere."

private val welcomeSteps = listOf(
    "Back up to your Google account, if you like",
    "Your reader's name",
    "Let Hop Tales listen",
    "How reading grows",
    "Dots and dashes under the sounds",
)

@Composable
private fun WelcomePage() {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text("BEFORE YOU START", style = type.caps(13.sp).copy(letterSpacing = 1.sp), color = paper.muted)
        Text("Welcome to Hop Tales", style = type.display(28.sp), color = paper.ink, modifier = Modifier.semantics { heading() })
        Text(WELCOME_SUMMARY, style = type.ui(16.sp, FontWeight.Medium), color = paper.ink.copy(alpha = 0.85f))
        Column(Modifier.padding(top = 4.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Setting up takes about a minute:", style = type.ui(16.sp, FontWeight.SemiBold), color = paper.ink)
            welcomeSteps.forEachIndexed { index, step -> WelcomeStep(index + 1, step) }
        }
    }
}

@Composable
private fun WelcomeStep(number: Int, text: String) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Row(
        Modifier.clearAndSetSemantics { contentDescription = "$number. $text" },
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(26.dp).background(paper.rim.copy(alpha = 0.7f), CircleShape), contentAlignment = Alignment.Center) {
            Text("$number", style = type.ui(14.sp, FontWeight.Bold), color = paper.ink)
        }
        Text(text, style = type.ui(16.sp, FontWeight.Medium), color = paper.ink.copy(alpha = 0.85f))
    }
}

@Composable
private fun StepPage(state: OnboardingState, actions: OnboardingActions) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(
            "STEP ${state.stepNumber} OF ${state.stepCount}",
            style = type.caps(13.sp).copy(letterSpacing = 1.sp),
            color = paper.muted,
            modifier = Modifier.semantics { contentDescription = "Step ${state.stepNumber} of ${state.stepCount}" },
        )
        Text(state.step.title, style = type.display(28.sp), color = paper.ink, modifier = Modifier.semantics { heading() })
        Text(state.step.detail, style = type.ui(16.sp, FontWeight.Medium), color = paper.ink.copy(alpha = 0.85f))
        Box(Modifier.padding(top = 4.dp)) {
            when (state.step) {
                OnboardingStep.BACKUP -> BackupChoices(state.backup, actions.backupPicked)

                OnboardingStep.NAME -> NameField(state.childName, actions.nameChanged) {
                    if (state.primaryEnabled) actions.primaryTapped()
                }

                OnboardingStep.LISTENING -> MicrophoneNote(state.authorization)

                OnboardingStep.AHEAD -> ReadingAhead(state.childName)

                OnboardingStep.SOUND_BUTTONS -> SoundButtonChoices(state.soundButtons, actions.soundButtonsPicked)
            }
        }
    }
}

@Composable
fun NameField(name: String, onChange: (String) -> Unit, onSubmit: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val focus = LocalFocusManager.current
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Name or nickname", style = type.ui(14.sp), color = paper.muted)
        BasicTextField(
            value = name,
            onValueChange = onChange,
            singleLine = true,
            textStyle = type.display(22.sp).copy(color = paper.ink),
            cursorBrush = SolidColor(paper.ink),
            keyboardOptions = KeyboardOptions(
                capitalization = KeyboardCapitalization.Sentences,
                autoCorrectEnabled = false,
                imeAction = ImeAction.Done,
            ),
            keyboardActions = KeyboardActions(
                onDone = {
                    focus.clearFocus()
                    onSubmit()
                },
            ),
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp)
                .paperField(
                    fill = 0.7f,
                    shape = RoundedCornerShape(16.dp),
                    shadowOpacity = 0.4f,
                    shadowRadius = 2.dp,
                    shadowY = 1.dp,
                )
                .semantics { contentDescription = "Name or nickname" },
            decorationBox = { field ->
                Box(Modifier.padding(horizontal = 16.dp), contentAlignment = Alignment.CenterStart) { field() }
            },
        )
    }
}

@Composable
private fun MicrophoneNote(authorization: Authorization?) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    when (authorization) {
        null -> Text(
            "Android will ask you to allow the microphone.",
            style = type.ui(13.sp, FontWeight.Medium),
            color = paper.muted,
        )

        Authorization.AUTHORIZED -> Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(22.dp).background(paper.sage, CircleShape), contentAlignment = Alignment.Center) {
                Icon(Glyphs.check, contentDescription = null, tint = paper.onRed, modifier = Modifier.size(15.dp))
            }
            Spacer(Modifier.width(8.dp))
            Text("Microphone allowed.", style = type.ui(16.sp), color = paper.sageDeep)
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
    val paper = LocalPaper.current
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(Glyphs.micSlash, contentDescription = null, tint = paper.muted, modifier = Modifier.size(20.dp))
        Text(text, style = LocalTypography.current.ui(15.sp, FontWeight.Medium), color = paper.ink)
    }
}

@Composable
private fun ReadingAhead(childName: String) {
    val friends = (1..3).map(Friend::at)
    Column(Modifier.fillMaxWidth()) {
        friends.forEachIndexed { index, friend ->
            if (index > 0) Trail()
            FriendAhead(friend, startsHere = index == 0, childName = childName)
        }
        Trail()
        Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Spacer(Modifier.width(58.dp))
            Text(
                "More friends further along",
                style = LocalTypography.current.ui(14.sp, FontWeight.Medium),
                color = LocalPaper.current.muted,
            )
        }
    }
}

@Composable
private fun FriendAhead(friend: Friend, startsHere: Boolean, childName: String) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    val words = friend.examples.joinToString(", ")
    val reader = childName.trim().ifEmpty { "your reader" }
    val start = if (startsHere) ", where $reader starts" else ""
    Row(
        Modifier.clearAndSetSemantics { contentDescription = "${friend.friendName}$start. Words like $words." },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(58.dp), contentAlignment = Alignment.Center) {
            FriendSticker(friend, 58.dp, Modifier.wrapContentWidth(unbounded = true))
        }
        Spacer(Modifier.width(14.dp))
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(verticalAlignment = Alignment.Bottom) {
                Text(friend.friendName, style = type.display(19.sp), color = paper.ink, modifier = Modifier.alignByBaseline())
                if (startsHere) {
                    Spacer(Modifier.width(8.dp))
                    Text(
                        "Starts here",
                        style = type.ui(12.sp, FontWeight.SemiBold),
                        color = paper.ink,
                        modifier = Modifier
                            .alignByBaseline()
                            .background(paper.wash, CircleShape)
                            .padding(horizontal = 8.dp, vertical = 3.dp),
                    )
                }
            }
            Text(
                buildAnnotatedString {
                    append("Words like ")
                    withStyle(type.word(18.sp).toSpanStyle().copy(color = paper.ink)) { append(words) }
                },
                style = type.ui(14.sp),
                color = paper.muted,
            )
        }
    }
}

@Composable
private fun Trail() {
    val dot = LocalPaper.current.muted.copy(alpha = 0.45f)
    Column(
        Modifier.width(58.dp).padding(vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        repeat(3) { Box(Modifier.size(5.dp).background(dot, CircleShape)) }
    }
}

@Composable
private fun SoundButtonChoices(selected: Boolean?, onPick: (Boolean) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        ChoiceSurface(selected = false, onClick = null) {
            SoundMarksExamples(modifier = Modifier.padding(vertical = 14.dp))
        }
        ChoicePair {
            PaperChoice("Yes, show them", selected = selected == true) {
                onPick(true)
            }
            PaperChoice("No thanks", selected = selected == false) {
                onPick(false)
            }
        }
    }
}

@Composable
private fun BackupChoices(selected: Boolean?, onPick: (Boolean) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        ChoicePair {
            PaperChoice("Yes, back up", selected = selected == true) {
                onPick(true)
            }
            PaperChoice("Not now", selected = selected == false) {
                onPick(false)
            }
        }
        if (selected == true) {
            Text(
                "Android's own backup needs to be on too. It's in the Settings app, under Backup.",
                style = LocalTypography.current.ui(13.sp, FontWeight.Medium),
                color = LocalPaper.current.muted,
            )
        }
    }
}
