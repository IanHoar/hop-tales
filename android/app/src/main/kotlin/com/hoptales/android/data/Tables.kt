package com.hoptales.android.data

import android.content.ContentValues
import android.database.sqlite.SQLiteDatabase
import com.hoptales.content.Basket
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Profile
import com.hoptales.content.Progress
import com.hoptales.content.Slot
import com.hoptales.content.StoryLibrary
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

object ProfileTable {
    const val ONLY = "profile"

    fun read(db: SQLiteDatabase): Profile? = db.rawQuery(
        """SELECT "childName", "startingFriend", "accent", "voiceID", "soundButtons", "theme", "plusOffered" FROM "profiles" WHERE "id" = ?""",
        arrayOf(ONLY),
    ).use { row ->
        if (!row.moveToFirst()) return null
        Profile(
            childName = row.getString(0),
            startingFriend = Friend.entries.firstOrNull { it.key == row.getString(1) } ?: Friend.BUNNY,
            accent = Profile.Accent.entries.firstOrNull { it.tag == row.getString(2) } ?: Profile.Accent.CANADIAN,
            voiceID = if (row.isNull(3)) null else row.getString(3),
            soundButtons = row.getInt(4) != 0,
            theme = Profile.Theme.of(row.getString(5)),
            plusOffered = row.getInt(6) != 0,
        )
    }

    fun write(db: SQLiteDatabase, profile: Profile) {
        if (read(db) == profile) return
        db.execSQL(
            """
            INSERT INTO "profiles" ("id", "childName", "startingFriend", "accent", "voiceID", "soundButtons", "theme", "plusOffered")
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT ("id") DO UPDATE SET
              "childName" = excluded."childName",
              "startingFriend" = excluded."startingFriend",
              "accent" = excluded."accent",
              "voiceID" = excluded."voiceID",
              "soundButtons" = excluded."soundButtons",
              "theme" = excluded."theme",
              "plusOffered" = excluded."plusOffered"
            """.trimIndent(),
            arrayOf<Any?>(
                ONLY,
                profile.childName,
                profile.startingFriend.key,
                profile.accent.tag,
                profile.voiceID,
                if (profile.soundButtons) 1 else 0,
                profile.theme.raw,
                if (profile.plusOffered) 1 else 0,
            ),
        )
    }

    fun delete(db: SQLiteDatabase) {
        db.delete("profiles", "id = ?", arrayOf(ONLY))
    }
}

object ProgressTable {
    const val ONLY = "progress"

    private data class StoryRow(val completedSentences: Int, val wordsRead: Int)

    fun read(db: SQLiteDatabase, library: StoryLibrary): Progress {
        val progress = read(db)
        val journey = db.rawQuery("""SELECT "journey" FROM "progress" WHERE "id" = ?""", arrayOf(ONLY)).use { row ->
            if (row.moveToFirst()) row.getString(0) else null
        }
        return if (journey != null && !Columns.recordsStoriesRead(journey)) progress.restoringStoriesRead(library) else progress
    }

    fun read(db: SQLiteDatabase): Progress {
        val record = db.rawQuery(
            """SELECT "stars", "journey", "baskets", "outfits" FROM "progress" WHERE "id" = ?""",
            arrayOf(ONLY),
        ).use { row ->
            if (!row.moveToFirst()) return@use null
            Progress(
                stars = row.getInt(0),
                journey = Columns.journey(row.getString(1)),
                baskets = Columns.baskets(row.getString(2)),
                outfits = Columns.outfits(row.getString(3)),
            )
        } ?: Progress()
        val stories = storyRows(db)
        return record.copy(
            completedSentences = stories.filterValues { it.completedSentences > 0 }.mapValues { it.value.completedSentences },
            wordsRead = stories.filterValues { it.wordsRead > 0 }.mapValues { it.value.wordsRead },
        )
    }

    fun write(db: SQLiteDatabase, progress: Progress, existing: Progress?) {
        val values = ContentValues().apply {
            put("id", ONLY)
            put("stars", progress.stars)
            put("journey", Columns.journey(progress.journey))
            put("baskets", Columns.baskets(progress.baskets))
            put("outfits", Columns.outfits(progress.outfits))
        }
        val unchanged = existing != null &&
            existing.stars == progress.stars &&
            existing.journey == progress.journey &&
            existing.baskets == progress.baskets &&
            existing.outfits == progress.outfits
        if (!unchanged) db.insertWithOnConflict("progress", null, values, SQLiteDatabase.CONFLICT_REPLACE)
        val rows = progress.storyRows
        val old = existing?.storyRows.orEmpty()
        for ((id, row) in rows) {
            if (old[id] == row) continue
            val story = ContentValues().apply {
                put("id", id)
                put("completedSentences", row.completedSentences)
                put("wordsRead", row.wordsRead)
            }
            db.insertWithOnConflict("storyProgress", null, story, SQLiteDatabase.CONFLICT_REPLACE)
        }
        for (id in old.keys - rows.keys) db.delete("storyProgress", "id = ?", arrayOf(id))
    }

    private fun storyRows(db: SQLiteDatabase): Map<String, StoryRow> =
        db.rawQuery("""SELECT "id", "completedSentences", "wordsRead" FROM "storyProgress"""", null).use { row ->
            buildMap { while (row.moveToNext()) put(row.getString(0), StoryRow(row.getInt(1), row.getInt(2))) }
        }

    private val Progress.storyRows: Map<String, StoryRow>
        get() = (completedSentences.keys + wordsRead.keys).associateWith {
            StoryRow(completedSentences[it] ?: 0, wordsRead[it] ?: 0)
        }
}

object Columns {
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    fun journey(journey: Journey): String = json.encodeToString(Journey.serializer(), journey)

    fun journey(text: String): Journey = runCatching { json.decodeFromString(Journey.serializer(), text) }.getOrDefault(Journey())

    fun recordsStoriesRead(journey: String): Boolean =
        runCatching { (json.parseToJsonElement(journey) as? JsonObject)?.containsKey("storiesRead") }.getOrNull() ?: true

    fun baskets(baskets: Map<Friend, Basket>): String = pairs(baskets, Friend.serializer(), Basket.serializer()).toString()

    fun baskets(text: String): Map<Friend, Basket> = unpairs(text, Friend.serializer(), Basket.serializer())

    fun outfits(outfits: Map<Friend, Map<Slot, String>>): String =
        pairs(outfits.mapValues { pairs(it.value, Slot.serializer(), String.serializer()) }, Friend.serializer(), JsonElement.serializer())
            .toString()

    fun outfits(text: String): Map<Friend, Map<Slot, String>> = unpairs(text, Friend.serializer(), JsonElement.serializer())
        .mapValues { unpairs(it.value, Slot.serializer(), String.serializer()) }

    private fun <K, V> pairs(map: Map<K, V>, key: KSerializer<K>, value: KSerializer<V>) = JsonArray(
        map.flatMap { (k, v) -> listOf(json.encodeToJsonElement(key, k), json.encodeToJsonElement(value, v)) },
    )

    private fun <K, V> unpairs(text: String, key: KSerializer<K>, value: KSerializer<V>): Map<K, V> =
        runCatching { unpairs(json.parseToJsonElement(text), key, value) }.getOrDefault(emptyMap())

    private fun <K, V> unpairs(element: JsonElement, key: KSerializer<K>, value: KSerializer<V>): Map<K, V> = when (element) {
        is JsonArray -> element.chunked(2).filter { it.size == 2 }.mapNotNull { (k, v) ->
            runCatching { json.decodeFromJsonElement(key, k) to json.decodeFromJsonElement(value, v) }.getOrNull()
        }.toMap()

        is JsonObject -> element.mapNotNull { (k, v) ->
            runCatching { json.decodeFromJsonElement(key, JsonPrimitive(k)) to json.decodeFromJsonElement(value, v) }.getOrNull()
        }.toMap()

        else -> emptyMap()
    }
}
