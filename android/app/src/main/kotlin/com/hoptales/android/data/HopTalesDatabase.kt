package com.hoptales.android.data

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import com.hoptales.content.Profile
import com.hoptales.content.Progress
import com.hoptales.content.StoryLibrary
import kotlinx.serialization.KSerializer
import java.io.File

class HopTalesDatabase(
    context: Context,
    name: String? = NAME,
    private val legacy: File? = context.filesDir,
    private val library: StoryLibrary? = null,
) : SQLiteOpenHelper(context, name, null, VERSION) {
    private val imported = mutableListOf<File>()

    init {
        setWriteAheadLoggingEnabled(false)
    }

    override fun onCreate(db: SQLiteDatabase) {
        for (statement in SCHEMA + MIGRATIONS.values.flatten()) db.execSQL(statement)
        val legacy = legacy ?: return
        val profileFile = File(legacy, LEGACY_PROFILE)
        read(profileFile, Profile.serializer())?.let {
            ProfileTable.write(db, it)
            imported += profileFile
        }
        val progressFile = File(legacy, LEGACY_PROGRESS)
        read(progressFile, Progress.serializer())?.let {
            ProgressTable.write(db, library?.let(it::restoringStoriesRead) ?: it, existing = null)
            imported += progressFile
        }
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        for ((version, statements) in MIGRATIONS) {
            if (version in (oldVersion + 1)..newVersion) statements.forEach(db::execSQL)
        }
    }

    override fun onOpen(db: SQLiteDatabase) {
        for (file in imported) file.delete()
        imported.clear()
    }

    private fun <T> read(file: File, serializer: KSerializer<T>): T? = runCatching {
        StoryLibrary.json.decodeFromString(serializer, file.readText())
    }.getOrNull()

    companion object {
        const val NAME = "hoptales.db"
        const val VERSION = 2
        const val LEGACY_PROFILE = "profile.json"
        const val LEGACY_PROGRESS = "progress.json"

        val SCHEMA = listOf(
            """
            CREATE TABLE "profiles" (
              "id" TEXT PRIMARY KEY NOT NULL,
              "childName" TEXT NOT NULL DEFAULT '',
              "startingFriend" TEXT NOT NULL DEFAULT 'bunny',
              "accent" TEXT NOT NULL DEFAULT 'en-CA',
              "voiceID" TEXT,
              "theme" TEXT NOT NULL DEFAULT 'device',
              "soundButtons" INTEGER NOT NULL DEFAULT 0
            )
            """,
            """
            CREATE TABLE "progress" (
              "id" TEXT PRIMARY KEY NOT NULL,
              "stars" INTEGER NOT NULL DEFAULT 0,
              "journey" TEXT NOT NULL,
              "baskets" TEXT NOT NULL,
              "outfits" TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE "storyProgress" (
              "id" TEXT PRIMARY KEY NOT NULL,
              "completedSentences" INTEGER NOT NULL DEFAULT 0,
              "wordsRead" INTEGER NOT NULL DEFAULT 0
            )
            """,
        ).map { it.trimIndent() }

        val MIGRATIONS = mapOf(
            2 to listOf("""ALTER TABLE "profiles" ADD COLUMN "plusOffered" INTEGER NOT NULL DEFAULT 0"""),
        )
    }
}

inline fun <T> SQLiteDatabase.inTransaction(work: SQLiteDatabase.() -> T): T {
    beginTransaction()
    try {
        return work().also { setTransactionSuccessful() }
    } finally {
        endTransaction()
    }
}
