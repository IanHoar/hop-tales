package com.hoptales.android.settings

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.ChevronGlyph
import com.hoptales.android.design.ChoiceSurface
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperChip
import com.hoptales.android.design.PaperChoice
import com.hoptales.android.design.PaperToggle
import com.hoptales.android.design.SpeakerGlyph
import com.hoptales.android.design.paperChip
import com.hoptales.android.design.paperField
import com.hoptales.android.design.pressable
import com.hoptales.android.home.SheetHeader
import com.hoptales.android.world.FriendSticker
import com.hoptales.android.world.SoundMarksExamples
import com.hoptales.content.Friend
import com.hoptales.content.Phonics
import com.hoptales.content.Profile
import com.hoptales.speech.Strictness

class SettingsActions(
    val nameChanged: (String) -> Unit = {},
    val nameSubmitted: () -> Unit = {},
    val friendPicked: (Friend) -> Unit = {},
    val accentPicked: (Profile.Accent) -> Unit = {},
    val themePicked: (Profile.Theme) -> Unit = {},
    val strictnessPicked: (Strictness) -> Unit = {},
    val soundButtonsToggled: (Boolean) -> Unit = {},
    val voicePicked: (String?) -> Unit = {},
    val hearVoice: () -> Unit = {},
    val soundToggled: (Boolean) -> Unit = {},
    val backupToggled: (Boolean) -> Unit = {},
    val speechLogToggled: (Boolean) -> Unit = {},
    val speechLogExported: () -> Unit = {},
    val speechLogCleared: () -> Unit = {},
    val resetOnboarding: () -> Unit = {},
    val resetJourney: () -> Unit = {},
    val unlockEverything: () -> Unit = {},
    val done: () -> Unit = {},
)

@Composable
fun SettingsScreen(key: String, onDone: () -> Unit) {
    val context = LocalContext.current
    val app = context.applicationContext as HopTalesApplication
    val model: SettingsViewModel = viewModel(key = key) { SettingsViewModel(app) }
    val state by model.state.collectAsStateWithLifecycle()
    val done = {
        model.done()
        onDone()
    }
    BackHandler(onBack = done)
    SettingsContent(
        state,
        SettingsActions(
            nameChanged = model::nameChanged,
            nameSubmitted = model::nameSubmitted,
            friendPicked = model::friendPicked,
            accentPicked = model::accentPicked,
            themePicked = model::themePicked,
            strictnessPicked = model::strictnessPicked,
            soundButtonsToggled = model::soundButtonsToggled,
            voicePicked = model::voicePicked,
            hearVoice = model::hearVoice,
            soundToggled = model::soundToggled,
            backupToggled = model::backupToggled,
            speechLogToggled = model::speechLogToggled,
            speechLogExported = { app.speechLog.shareIntent(context)?.let(context::startActivity) },
            speechLogCleared = model::speechLogCleared,
            resetJourney = model::resetJourney,
            unlockEverything = model::unlockEverything,
            resetOnboarding = {
                model.resetOnboarding()
                onDone()
            },
            done = done,
        ),
    )
}

val Strictness.title: String
    get() = when (this) {
        Strictness.GENTLE -> "Gentle"
        Strictness.STANDARD -> "Standard"
    }

val Strictness.detail: String
    get() = when (this) {
        Strictness.GENTLE -> "Accepts close tries, dropped endings and sound-alikes. Best for new readers."
        Strictness.STANDARD -> "Wants each word said clearly. A small slip is still fine."
    }

@Composable
fun SettingsContent(state: SettingsState, actions: SettingsActions) {
    val paper = LocalPaper.current
    val insets = WindowInsets.safeDrawing.asPaddingValues()
    Column(Modifier.fillMaxSize().background(paper.page)) {
        SheetHeader("Settings", actions.done)
        Box(Modifier.fillMaxSize().verticalScroll(rememberScrollState()), contentAlignment = Alignment.TopCenter) {
            Column(
                Modifier
                    .widthIn(max = 560.dp)
                    .fillMaxWidth()
                    .padding(start = 20.dp, end = 20.dp, top = 8.dp, bottom = insets.calculateBottomPadding() + 30.dp),
                verticalArrangement = Arrangement.spacedBy(28.dp),
            ) {
                Section("Reader") { SettingsName(state.childName, actions) }
                Section("Reading with") {
                    for (friend in state.readingFriends) {
                        ReadingWith(friend, selected = friend == state.journey.activeFriend) { actions.friendPicked(friend) }
                    }
                    Text(
                        Phonics.STANDARD,
                        style = LocalTypography.current.ui(13.sp),
                        color = paper.muted,
                        modifier = Modifier.padding(horizontal = 4.dp),
                    )
                }
                Section("Accent") {
                    for (accent in Profile.Accent.entries) {
                        PaperChoice(accent.accentName, selected = accent == state.profile.accent) { actions.accentPicked(accent) }
                    }
                }
                Section("Theme") {
                    for (theme in Profile.Theme.entries) {
                        PaperChoice(theme.themeName, selected = theme == state.profile.theme) { actions.themePicked(theme) }
                    }
                }
                Section("Listening") {
                    for (strictness in Strictness.entries) {
                        PaperChoice(strictness.title, selected = strictness == state.strictness, detail = strictness.detail) {
                            actions.strictnessPicked(strictness)
                        }
                    }
                }
                Section("Sound buttons") {
                    PaperToggle(
                        "Dots and dashes under words",
                        "A dot for each sound, a dash for letters that make one sound together.",
                        checked = state.profile.soundButtons,
                        onChange = actions.soundButtonsToggled,
                    ) {
                        SoundMarksExamples(size = 26f, modifier = Modifier.padding(top = 14.dp, bottom = 4.dp))
                    }
                }
                Section("Help voice") { VoiceRow(state, actions) }
                Section("Sounds") {
                    PaperToggle(
                        "Sound effects",
                        "The chime when a sentence is finished.",
                        checked = state.soundOn,
                        onChange = actions.soundToggled,
                    )
                }
                Section("Backup") { BackupRow(state, actions.backupToggled) }
                Section("Speech log") { SpeechLogRow(state, actions) }
                Section("Testing") {
                    PaperChip(height = 48.dp, onClick = actions.resetOnboarding) {
                        Text("Reset onboarding", style = LocalTypography.current.ui(15.sp), color = paper.ink)
                    }
                    PaperChip(height = 48.dp, onClick = actions.resetJourney) {
                        Text("Reset reading journey", style = LocalTypography.current.ui(15.sp), color = paper.ink)
                    }
                    PaperChip(height = 48.dp, onClick = actions.unlockEverything) {
                        Text("Unlock everything", style = LocalTypography.current.ui(15.sp), color = paper.ink)
                    }
                }
            }
        }
    }
}

@Composable
private fun Section(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            title.uppercase(),
            style = LocalTypography.current.ui(13.sp).copy(letterSpacing = 0.14.em),
            color = LocalPaper.current.muted,
            modifier = Modifier.padding(horizontal = 4.dp).semantics {
                heading()
                contentDescription = title
            },
        )
        content()
    }
}

@Composable
private fun SettingsName(name: String, actions: SettingsActions) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    var wasFocused by remember { mutableStateOf(false) }
    BasicTextField(
        value = name,
        onValueChange = actions.nameChanged,
        singleLine = true,
        textStyle = type.display(22.sp).copy(color = paper.ink),
        cursorBrush = SolidColor(paper.ink),
        keyboardOptions = KeyboardOptions(
            capitalization = KeyboardCapitalization.Words,
            autoCorrectEnabled = false,
            imeAction = ImeAction.Done,
        ),
        keyboardActions = KeyboardActions(onDone = { actions.nameSubmitted() }),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .paperField()
            .onFocusChanged {
                if (wasFocused && !it.isFocused) actions.nameSubmitted()
                wasFocused = it.isFocused
            }
            .semantics { contentDescription = "Name or nickname" },
        decorationBox = { field ->
            Box(Modifier.padding(horizontal = 16.dp), contentAlignment = Alignment.CenterStart) {
                if (name.isEmpty()) Text("Name or nickname", style = type.display(22.sp), color = paper.muted)
                field()
            }
        },
    )
}

@Composable
private fun VoiceRow(state: SettingsState, actions: SettingsActions) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    var open by remember { mutableStateOf(false) }
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.weight(1f)) {
            Row(
                Modifier
                    .semantics { contentDescription = "Help voice, ${state.voiceName}" }
                    .pressable({ open = true })
                    .fillMaxWidth()
                    .height(56.dp)
                    .paperField()
                    .padding(horizontal = 16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(state.voiceName, style = type.display(19.sp), color = paper.ink, modifier = Modifier.weight(1f))
                ChevronGlyph(paper.muted)
            }
            DropdownMenu(expanded = open, onDismissRequest = { open = false }, containerColor = paper.paper) {
                DropdownMenuItem(
                    text = { Text("Automatic", style = type.ui(16.sp), color = paper.ink) },
                    onClick = {
                        open = false
                        actions.voicePicked(null)
                    },
                )
                for (voice in state.voices) {
                    DropdownMenuItem(
                        text = { Text(voice.label, style = type.ui(16.sp), color = paper.ink) },
                        onClick = {
                            open = false
                            actions.voicePicked(voice.id)
                        },
                    )
                }
            }
        }
        Spacer(Modifier.width(12.dp))
        Box(
            Modifier
                .size(56.dp)
                .semantics { contentDescription = "Hear the help voice" }
                .pressable(actions.hearVoice)
                .paperChip(CircleShape, rim = 3.dp),
            contentAlignment = Alignment.Center,
        ) {
            SpeakerGlyph(LocalPaper.current.ink)
        }
    }
}

@Composable
private fun SpeechLogRow(state: SettingsState, actions: SettingsActions) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    PaperToggle(
        "Keep a log of what's heard",
        "Words only, never sound, kept on this device until the app closes. Nothing is sent anywhere.",
        checked = state.speechLogOn,
        onChange = actions.speechLogToggled,
    )
    Row(Modifier.padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(
            if (state.speechLogLines == 1) "1 line" else "${state.speechLogLines} lines",
            style = type.ui(15.sp, FontWeight.Medium),
            color = paper.muted,
            modifier = Modifier.weight(1f),
        )
        if (state.speechLogLines > 0) {
            PaperChip(onClick = actions.speechLogExported) {
                Text("Export", style = type.ui(15.sp), color = paper.ink)
            }
            Spacer(Modifier.width(12.dp))
            PaperChip(onClick = actions.speechLogCleared) {
                Text("Clear", style = type.ui(15.sp), color = paper.ink)
            }
        }
    }
}

@Composable
private fun ReadingWith(friend: Friend, selected: Boolean, onClick: () -> Unit) {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    ChoiceSurface(
        selected = selected,
        onClick = onClick,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.width(56.dp), contentAlignment = Alignment.Center) { FriendSticker(friend, 52.dp) }
            Spacer(Modifier.width(14.dp))
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(friend.friendName, style = type.display(19.sp), color = paper.ink)
                Text("${friend.stage} · ${friend.examples.joinToString(", ")}", style = type.ui(14.sp), color = paper.muted)
            }
        }
    }
}

@Composable
private fun BackupRow(state: SettingsState, onChange: (Boolean) -> Unit) {
    val note = when {
        state.backupOn ->
            "Android backs up about once a day, while the device is charging and on Wi-Fi, if its own backup is on in the " +
                "Settings app."

        state.backupWasOn ->
            "Backups have stopped. Android's next backup takes your reader's name and progress out of your Google account."

        else -> null
    }
    PaperToggle(
        "Back up to your Google account",
        "Keeps your reader's name and progress safe for a new phone or tablet. It's stored in your own Google account. " +
            "We never see it.",
        checked = state.backupOn,
        onChange = onChange,
    ) {
        if (note != null) {
            Text(
                note,
                style = LocalTypography.current.ui(14.sp),
                color = LocalPaper.current.muted,
                modifier = Modifier.padding(top = 12.dp),
            )
        }
    }
}
