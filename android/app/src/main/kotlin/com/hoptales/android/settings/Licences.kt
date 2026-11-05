package com.hoptales.android.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.hoptales.android.design.LocalPaper
import com.hoptales.android.design.LocalTypography
import com.hoptales.android.design.pressable
import com.hoptales.android.home.SheetHeader
import com.hoptales.content.Phonics

data class Licence(val name: String, val copyright: String)

object Licences {
    const val APACHE = "licences/apache-2.0.txt"

    val all = listOf(
        Licence("Vosk speech recognition", "Copyright 2019 Alpha Cephei Inc."),
        Licence("Vosk small English model", "Copyright 2020 Alpha Cephei Inc."),
        Licence("Kaldi", "Copyright Johns Hopkins University and the Kaldi authors"),
        Licence("OpenFst", "Copyright Google Inc. and the OpenFst authors"),
        Licence("Java Native Access", "Copyright Timothy Wall and the JNA authors"),
    )
}

@Composable
fun SettingsFooter() {
    val paper = LocalPaper.current
    val type = LocalTypography.current
    var isReading by rememberSaveable { mutableStateOf(false) }
    Column(Modifier.padding(horizontal = 4.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(Phonics.STANDARD, style = type.ui(13.sp), color = paper.muted)
        Text(
            "Open-source licences",
            style = type.ui(13.sp, FontWeight.SemiBold).copy(textDecoration = TextDecoration.Underline),
            color = paper.muted,
            modifier = Modifier.pressable({ isReading = true }),
        )
    }
    if (isReading) LicenceText { isReading = false }
}

@Composable
private fun LicenceText(done: () -> Unit) {
    val paper = LocalPaper.current
    val context = LocalContext.current
    val text = remember { context.assets.open(Licences.APACHE).bufferedReader().use { it.readText() } }
    val insets = WindowInsets.safeDrawing.asPaddingValues()
    Dialog(onDismissRequest = done, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Column(Modifier.fillMaxSize().background(paper.page).padding(top = insets.calculateTopPadding())) {
            SheetHeader("Licences", done)
            Column(
                Modifier
                    .verticalScroll(rememberScrollState())
                    .padding(start = 20.dp, end = 20.dp, bottom = insets.calculateBottomPadding() + 24.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Text(
                    "Hop Tales listens on this device with open-source software, used under the Apache License 2.0.",
                    style = LocalTypography.current.ui(14.sp),
                    color = paper.muted,
                )
                for (licence in Licences.all) {
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(licence.name, style = LocalTypography.current.ui(16.sp), color = paper.ink)
                        Text(licence.copyright, style = LocalTypography.current.ui(14.sp), color = paper.muted)
                    }
                }
                Text(
                    text,
                    style = LocalTypography.current.ui(13.sp).copy(fontFamily = FontFamily.Monospace),
                    color = paper.ink,
                )
            }
        }
    }
}
