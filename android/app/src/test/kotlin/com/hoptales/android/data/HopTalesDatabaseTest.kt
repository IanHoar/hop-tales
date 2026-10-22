package com.hoptales.android.data

import android.database.sqlite.SQLiteDatabase
import com.hoptales.content.Basket
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Profile
import com.hoptales.content.Progress
import com.hoptales.content.Slot
import com.hoptales.content.StoryLibrary
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class HopTalesDatabaseTest {
    @get:Rule
    val folder = TemporaryFolder()

    private val context get() = RuntimeEnvironment.getApplication()

    private fun database(legacy: File? = null) = HopTalesDatabase(context, File(folder.root, "hoptales.db").path, legacy)

    @Test
    fun theTablesMatchTheIOSSchema() {
        val ios = SQLiteDatabase.create(null)
        for (statement in iosStatements()) ios.execSQL(statement)
        val android = database().readableDatabase
        for (table in listOf("profiles", "progress", "storyProgress")) {
            assertEquals(table, columns(ios, table), columns(android, table))
        }
        assertEquals(tables(ios), tables(android))
    }

    @Test
    fun aVersionOneDatabaseGainsThePlusOfferColumn() {
        val path = File(folder.root, "hoptales.db").path
        SQLiteDatabase.openOrCreateDatabase(path, null).use { old ->
            for (statement in HopTalesDatabase.SCHEMA) old.execSQL(statement)
            old.execSQL("""INSERT INTO "profiles" ("id", "childName") VALUES ('profile', 'Maya')""")
            old.version = 1
        }
        val db = database().writableDatabase
        assertEquals(Profile("Maya"), ProfileTable.read(db))
        ProfileTable.write(db, Profile("Maya", plusOffered = true))
        assertEquals(true, ProfileTable.read(db)?.plusOffered)
    }

    @Test
    fun progressAndProfileFromBeforeTheDatabaseAreImported() {
        val legacy = folder.newFolder("files")
        val progress = Progress(
            stars = 12,
            completedSentences = mapOf("pond" to 2),
            wordsRead = mapOf("pond" to 7),
            journey = Journey.starting(Friend.FROG),
            baskets = mapOf(Friend.FROG to Basket(total = 5, golden = 1, inBasket = 5)),
            outfits = mapOf(Friend.FROG to mapOf(Slot.HEAD to "straw-hat")),
        )
        val maya = Profile("Maya", Friend.HARE, Profile.Accent.BRITISH, voiceID = "v1", soundButtons = true)
        File(legacy, "progress.json").writeText(StoryLibrary.json.encodeToString(Progress.serializer(), progress))
        File(legacy, "profile.json").writeText(StoryLibrary.json.encodeToString(Profile.serializer(), maya))

        val database = database(legacy)
        assertEquals(progress, ProgressTable.read(database.readableDatabase))
        assertEquals(maya, ProfileTable.read(database.readableDatabase))
        assertFalse(File(legacy, "progress.json").exists())
        assertFalse(File(legacy, "profile.json").exists())
    }

    @Test
    fun theImportRunsOnlyOnce() {
        val legacy = folder.newFolder("files")
        database(legacy).readableDatabase.close()
        File(legacy, "progress.json").writeText(StoryLibrary.json.encodeToString(Progress.serializer(), Progress(stars = 9)))
        assertEquals(Progress(), ProgressTable.read(database(legacy).readableDatabase))
        assertTrue(File(legacy, "progress.json").exists())
    }

    @Test
    fun aDamagedFileIsLeftWhereItIs() {
        val legacy = folder.newFolder("files")
        File(legacy, "progress.json").writeText("{not json")
        assertEquals(Progress(), ProgressTable.read(database(legacy).readableDatabase))
        assertTrue(File(legacy, "progress.json").exists())
    }

    @Test
    fun aFreshInstallStartsEmpty() {
        val database = database(folder.newFolder("files"))
        assertEquals(Progress(), ProgressTable.read(database.readableDatabase))
        assertEquals(null, ProfileTable.read(database.readableDatabase))
    }

    @Test
    fun dictionariesAreStoredTheWaySwiftEncodesThem() {
        assertEquals(
            """["frog",{"total":5,"golden":1,"filled":0,"inBasket":0}]""",
            Columns.baskets(mapOf(Friend.FROG to Basket(total = 5, golden = 1))),
        )
        assertEquals("""["frog",["head","hat"]]""", Columns.outfits(mapOf(Friend.FROG to mapOf(Slot.HEAD to "hat"))))
        assertEquals(mapOf(Friend.FROG to Basket(total = 5, golden = 1)), Columns.baskets("""["frog",{"total":5,"golden":1}]"""))
        assertEquals(mapOf(Friend.FROG to mapOf(Slot.HEAD to "hat")), Columns.outfits("""["frog",["head","hat"]]"""))
    }

    @Test
    fun theJourneyKeepsEveryFieldSwiftExpects() {
        val text = Columns.journey(Journey())
        val fields = listOf(
            "level", "steps", "met", "activeFriend", "bigStoryAttempts", "trail", "storiesReadWell", "recentHelpRates",
            "cleanStreak", "storiesRead",
        )
        for (field in fields) assertTrue(field, "\"$field\"" in text)
        assertEquals(Journey.starting(Friend.CRAB), Columns.journey(Columns.journey(Journey.starting(Friend.CRAB))))
    }

    @Test
    fun aThemeChosenOnIOSSurvivesAnAndroidSave() {
        val db = database().writableDatabase
        db.execSQL("""INSERT INTO "profiles" ("id", "childName", "theme") VALUES ('profile', 'Maya', 'dark')""")
        val saved = ProfileTable.read(db)!!
        assertEquals(Profile.Theme.DARK, saved.theme)
        ProfileTable.write(db, saved.copy(childName = "Mia"))
        db.rawQuery("""SELECT "theme", "childName" FROM "profiles"""", null).use {
            it.moveToFirst()
            assertEquals("dark", it.getString(0))
            assertEquals("Mia", it.getString(1))
        }
    }

    @Test
    fun aThemeIsWrittenWithTheIOSRawValues() {
        val db = database().writableDatabase
        for (theme in Profile.Theme.entries) {
            ProfileTable.write(db, Profile("Maya", theme = theme))
            db.rawQuery("""SELECT "theme" FROM "profiles"""", null).use {
                it.moveToFirst()
                assertEquals(theme.raw, it.getString(0))
            }
            assertEquals(theme, ProfileTable.read(db)!!.theme)
        }
        assertEquals(listOf("device", "light", "dark"), Profile.Theme.entries.map { it.raw })
    }

    private fun iosStatements(): List<String> {
        val source = File(System.getProperty("hoptales.database")!!).readText()
        return Regex("\"\"\"(.*?)\"\"\"", RegexOption.DOT_MATCHES_ALL).findAll(source)
            .map { it.groupValues[1].trim().removeSuffix("STRICT").trim() }
            .filter { it.startsWith("CREATE") || it.startsWith("ALTER") }
            .toList()
            .also { assertTrue(it.isNotEmpty()) }
    }

    private fun tables(db: SQLiteDatabase): Set<String> =
        db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'", null)
            .use { buildSet { while (it.moveToNext()) add(it.getString(0)) } }

    private fun columns(db: SQLiteDatabase, table: String): List<String> = db.rawQuery("PRAGMA table_info(\"$table\")", null).use {
        buildList {
            while (it.moveToNext()) {
                add(listOf(it.getString(1), it.getString(2), it.getInt(3), it.getString(4), it.getInt(5)).joinToString("|"))
            }
        }
    }
}
