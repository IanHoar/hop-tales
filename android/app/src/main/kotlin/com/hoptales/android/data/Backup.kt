package com.hoptales.android.data

import android.app.backup.BackupAgent
import android.app.backup.BackupDataInput
import android.app.backup.BackupDataOutput
import android.app.backup.FullBackupDataOutput
import android.content.Context
import android.os.ParcelFileDescriptor
import androidx.core.content.edit
import java.io.File

class BackupChoice(private val context: Context) {
    private val preferences = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    var isOn: Boolean
        get() = preferences.getBoolean(ON, false)
        set(value) = preferences.edit(commit = true) {
            putBoolean(ON, value)
            if (value) putBoolean(WAS_ON, true)
        }

    val wasEverOn: Boolean get() = preferences.getBoolean(WAS_ON, false)

    val file: File get() = File(context.dataDir, "shared_prefs/$FILE.xml")

    private companion object {
        const val FILE = "backup"
        const val ON = "google-backup"
        const val WAS_ON = "google-backup-was-on"
    }
}

enum class BackupPlan {
    EVERYTHING,
    CHOICE_ONLY,
    NOTHING,
    ;

    companion object {
        fun of(isDeviceTransfer: Boolean, isOn: Boolean, wasEverOn: Boolean): BackupPlan = when {
            isDeviceTransfer || isOn -> EVERYTHING
            wasEverOn -> CHOICE_ONLY
            else -> NOTHING
        }
    }
}

class HopTalesBackupAgent : BackupAgent() {
    override fun onFullBackup(data: FullBackupDataOutput) {
        val choice = BackupChoice(this)
        val isDeviceTransfer = data.transportFlags and FLAG_DEVICE_TO_DEVICE_TRANSFER != 0
        when (BackupPlan.of(isDeviceTransfer, choice.isOn, choice.wasEverOn)) {
            BackupPlan.EVERYTHING -> super.onFullBackup(data)
            BackupPlan.CHOICE_ONLY -> if (choice.file.exists()) fullBackupFile(choice.file, data)
            BackupPlan.NOTHING -> Unit
        }
    }

    override fun onBackup(oldState: ParcelFileDescriptor?, data: BackupDataOutput?, newState: ParcelFileDescriptor?) = Unit

    override fun onRestore(data: BackupDataInput?, appVersionCode: Int, newState: ParcelFileDescriptor?) = Unit
}
