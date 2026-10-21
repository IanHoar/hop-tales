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
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.hoptales.android.HopTalesApplication
import com.hoptales.android.design.ChevronGlyph
import com.hoptales.android.design.LocalPalette
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.PaperChip
import com.hoptales.android.design.PaperChoice
import com.hoptales.android.design.PaperToggle
import com.hoptales.android.design.SpeakerGlyph
import com.hoptales.android.design.field
import com.hoptales.android.design.paperChip
import com.hoptales.android.design.pressable
import com.hoptales.android.world.SoundMarksExamples
import com.hoptales.content.Friend
import com.hoptales.content.Phonics
import com.hoptales.content.Profile
import com.hoptales.speech.Strictness

class SettingsActions(
    val nameChanged: (String) -> Unit = {},
    val nameSubmitted: () -> Unit = {},
    val accentPicked: (Profile.Accent) -> Unit = {},
    val strictnessPicked: (Strictness) -> Unit = {},
    val soundButtonsToggled: (Boolean) -> Unit = {},
    val voicePicked: (String?) -> Unit = {},
    val hearVoice: () -> Unit = {},
    val soundToggled: (Boolean) -> Unit = {},
    val resetOnboarding: () -> Unit = {},
    val done: () -> Unit = {},
)

@Composable
fun SettingsScreen(key: String, onDone: () -> Unit) {
    val app = LocalContext.current.applicationContext as HopTalesApplication
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
            accentPicked = model::accentPicked,
            strictnessPicked = model::strictnessPicked,
            soundButtonsToggled = model::soundButtonsToggled,
            voicePicked = model::voicePicked,
            hearVoice = model::hearVoice,
            soundToggled = model::soundToggled,
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
    val palette = LocalPalette.current
    val insets = WindowInsets.safeDrawing.asPaddingValues()
    Column(Modifier.fillMaxSize().background(palette.page).padding(top = insets.calculateTopPadding())) {
        SettingsHeader(actions.done)
        Box(Modifier.fillMaxSize().verticalScroll(rememberScrollState()), contentAlignment = Alignment.TopCenter) {
            Column(
                Modifier
                    .widthIn(max = 560.dp)
                    .fillMaxWidth()
                    .padding(start = 20.dp, end = 20.dp, top = 8.dp, bottom = insets.calculateBottomPadding() + 30.dp),
                verticalArrangement = Arrangement.spacedBy(28.dp),
            ) {
                Section("Reader") { SettingsName(state.childName, actions) }
                Section("Accent") {
                    for (accent in Profile.Accent.entries) {
                        PaperChoice(accent.accentName, selected = accent == state.profile.accent) { actions.accentPicked(accent) }
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
                Section("Testing") {
                    PaperChip(height = 48.dp, onClick = actions.resetOnboarding) {
                        Text("Reset onboarding", style = LocalTypography.current.ui(15.sp), color = palette.ink)
                    }
                }
                Text(Phonics.STANDARD, style = LocalTypography.current.ui(13.sp), color = palette.muted)
            }
        }
    }
}

@Composable
private fun SettingsHeader(onDone: () -> Unit) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        PaperChip(Modifier.rotate(-2f).semantics { heading() }, height = 48.dp) {
            Text("Settings", style = type.display(22.sp), color = palette.ink)
        }
        Spacer(Modifier.weight(1f))
        PaperChip(height = 48.dp, onClick = onDone) {
            Text("Done", style = type.display(17.sp), color = palette.ink)
        }
    }
}

@Composable
private fun Section(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            title.uppercase(),
            style = LocalTypography.current.caps(13.sp),
            color = LocalPalette.current.muted,
            modifier = Modifier.padding(horizontal = 4.dp).semantics { heading() },
        )
        content()
    }
}

private fun Modifier.settingsField(background: Color, rim: Color) =
    this.background(background, RoundedCornerShape(18.dp)).border(3.dp, rim, RoundedCornerShape(18.dp))

@Composable
private fun SettingsName(name: String, actions: SettingsActions) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    var wasFocused by remember { mutableStateOf(false) }
    BasicTextField(
        value = name,
        onValueChange = actions.nameChanged,
        singleLine = true,
        textStyle = type.display(22.sp).copy(color = palette.ink),
        cursorBrush = SolidColor(palette.ink),
        keyboardOptions = KeyboardOptions(
            capitalization = KeyboardCapitalization.Words,
            autoCorrectEnabled = false,
            imeAction = ImeAction.Done,
        ),
        keyboardActions = KeyboardActions(onDone = { actions.nameSubmitted() }),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .settingsField(palette.field, palette.parchmentLip)
            .onFocusChanged {
                if (wasFocused && !it.isFocused) actions.nameSubmitted()
                wasFocused = it.isFocused
            }
            .semantics { contentDescription = "Name or nickname" },
        decorationBox = { field ->
            Box(Modifier.padding(horizontal = 16.dp), contentAlignment = Alignment.CenterStart) {
                if (name.isEmpty()) Text("Name or nickname", style = type.display(22.sp), color = palette.faint)
                field()
            }
        },
    )
}

@Composable
private fun VoiceRow(state: SettingsState, actions: SettingsActions) {
    val palette = LocalPalette.current
    val type = LocalTypography.current
    var open by remember { mutableStateOf(false) }
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.weight(1f)) {
            Surface(
                onClick = { open = true },
                modifier = Modifier.fillMaxWidth().height(56.dp).semantics { contentDescription = "Help voice, ${state.voiceName}" },
                shape = RoundedCornerShape(18.dp),
                color = palette.field,
                border = BorderStroke(3.dp, palette.parchmentLip),
            ) {
                Row(Modifier.padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(state.voiceName, style = type.display(19.sp), color = palette.ink, modifier = Modifier.weight(1f))
                    ChevronGlyph(palette.muted)
                }
            }
            DropdownMenu(expanded = open, onDismissRequest = { open = false }, containerColor = palette.parchment) {
                DropdownMenuItem(
                    text = { Text("Automatic", style = type.ui(16.sp), color = palette.ink) },
                    onClick = {
                        open = false
                        actions.voicePicked(null)
                    },
                )
                for (voice in state.voices) {
                    DropdownMenuItem(
                        text = { Text(voice.name, style = type.ui(16.sp), color = palette.ink) },
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
                .paperChip(CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            SpeakerGlyph(LocalPaper.current.ink)
        }
    }
}
