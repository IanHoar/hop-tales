package com.hoptales.android.data

import android.content.Context
import androidx.core.content.edit

class SoundPreference(context: Context) {
    private val preferences = context.getSharedPreferences("settings", Context.MODE_PRIVATE)

    var isOn: Boolean
        get() = preferences.getBoolean(KEY, true)
        set(value) = preferences.edit { putBoolean(KEY, value) }

    private companion object {
        const val KEY = "sound-on"
    }
}
