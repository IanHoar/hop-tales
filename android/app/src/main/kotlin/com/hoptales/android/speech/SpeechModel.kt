package com.hoptales.android.speech

import com.hoptales.speech.OnDeviceSupport

enum class SpeechModel {
    READY,
    MISSING,
    DOWNLOADING,
    UNAVAILABLE,
    ;

    val canDownload: Boolean get() = this == MISSING || this == DOWNLOADING

    companion object {
        fun of(accentTag: String, installed: List<String>, pending: List<String>, supported: List<String>): SpeechModel = when {
            OnDeviceSupport.listeningTag(accentTag, installed) != null -> READY
            OnDeviceSupport.listeningTag(accentTag, pending) != null -> DOWNLOADING
            OnDeviceSupport.listeningTag(accentTag, supported) != null -> MISSING
            else -> UNAVAILABLE
        }
    }
}
