package com.hoptales.android.data

import android.content.Context
import androidx.core.content.edit
import com.hoptales.speech.Strictness

class ListeningPreferences(context: Context) {
    private val preferences = context.getSharedPreferences("settings", Context.MODE_PRIVATE)

    var strictness: Strictness
        get() = Strictness.entries.firstOrNull { it.key == preferences.getString(STRICTNESS, null) } ?: Strictness.GENTLE
        set(value) = preferences.edit { putString(STRICTNESS, value.key) }

    var hasAskedForMicrophone: Boolean
        get() = preferences.getBoolean(ASKED, false)
        set(value) = preferences.edit { putBoolean(ASKED, value) }

    private val Strictness.key get() = name.lowercase()

    private companion object {
        const val STRICTNESS = "matching-strictness"
        const val ASKED = "microphone-asked"
    }
}
