package com.hoptales.android.data

import android.database.sqlite.SQLiteDatabase
import com.hoptales.android.HopTalesApplication
import com.hoptales.content.Basket
import com.hoptales.content.Friend
import com.hoptales.content.Journey
import com.hoptales.content.Progress
import com.hoptales.content.Slot
import com.hoptales.content.StoryLibrary
import org.junit.Assert.assertEquals
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
class ProgressStoreTest {
    @get:Rule
    val folder = TemporaryFolder()

    private val app get() = RuntimeEnvironment.getApplication() as HopTalesApplication
    private val database by lazy { HopTalesDatabase(app, File(folder.root, "hoptales.db").path, legacy = null) }

    private fun store() = ProgressStore(database, app.library)

    @Test
    fun anEmptyDatabaseReadsAsFreshProgress() {
        assertEquals(Progress(), store().load())
    }

    @Test
    fun whatIsSavedComesBackNextLaunch() {
        val progress = Progress(
            stars = 41,
            completedSentences = mapOf("castle-road" to 3),
            wordsRead = mapOf("castle-road" to 18, "pond" to 4),
            journey = Journey.starting(Friend.FROG).copy(storiesRead = setOf("castle-road")),
            baskets = mapOf(Friend.FROG to Basket(total = 5, golden = 1)),
            outfits = mapOf(Friend.FROG to mapOf(Slot.HEAD to "straw-hat"), Friend.BUNNY to emptyMap()),
        )
        store().save(progress)
        assertEquals(progress, store().load())
    }

    @Test
    fun onlyTheStoriesThatChangedAreWritten() {
        store().save(Progress(completedSentences = mapOf("a" to 1, "b" to 2), wordsRead = mapOf("a" to 3, "b" to 4)))
        val db = database.writableDatabase
        val before = changes(db)
        db.inTransaction {
            ProgressTable.write(
                this,
                Progress(completedSentences = mapOf("a" to 1, "b" to 5), wordsRead = mapOf("a" to 3, "b" to 9)),
                existing = ProgressTable.read(this),
            )
        }
        assertEquals(1, changes(db) - before)
    }

    @Test
    fun aResetStoryIsRemoved() {
        store().save(Progress(completedSentences = mapOf("a" to 1), wordsRead = mapOf("a" to 3)))
        store().save(Progress())
        assertEquals(Progress(), store().load())
    }

    @Test
    fun startingAJourneyIsSaved() {
        store().startJourney(Friend.CRAB)
        assertEquals(Friend.CRAB, store().load().journey.activeFriend)
    }

    @Test
    fun aResetJourneyStaysResetNextLaunch() {
        val story = app.library.stories(Journey().level).first()
        val finished = Progress(
            completedSentences = mapOf(story.id to story.sentences.size),
            journey = Journey(storiesRead = setOf(story.id)),
        )
        store().save(finished)
        store().save(finished.copy(journey = Journey()))
        assertEquals(emptySet<String>(), store().load().journey.storiesRead)
    }

    @Test
    fun aJourneySavedBeforeStoriesReadCountsTheStoriesAlreadyFinished() {
        val story = app.library.stories(Journey().level).first()
        store().save(Progress(completedSentences = mapOf(story.id to story.sentences.size)))
        val journey = """
            {"level":1,"steps":0,"met":["bunny"],"activeFriend":"bunny","bigStoryAttempts":0,
            "trail":0,"storiesReadWell":0,"recentHelpRates":[],"cleanStreak":0}
        """.trimIndent()
        database.writableDatabase.execSQL(
            """INSERT INTO "progress" ("id", "stars", "journey", "baskets", "outfits") VALUES (?, 0, ?, '[]', '[]')""",
            arrayOf(ProgressTable.ONLY, journey),
        )
        assertEquals(setOf(story.id), store().load().journey.storiesRead)
    }

    @Test
    fun aProgressFileFromBeforeTheDatabaseCountsTheStoriesAlreadyFinished() {
        val story = app.library.stories(Journey().level).first()
        val legacy = folder.newFolder("files")
        val progress = Progress(completedSentences = mapOf(story.id to story.sentences.size))
        File(legacy, "progress.json").writeText(StoryLibrary.json.encodeToString(Progress.serializer(), progress))
        val database = HopTalesDatabase(app, File(folder.root, "legacy.db").path, legacy, app.library)
        assertEquals(setOf(story.id), ProgressStore(database, app.library).load().journey.storiesRead)
    }

    private fun changes(db: SQLiteDatabase) = db.rawQuery("SELECT total_changes()", null).use {
        it.moveToFirst()
        it.getInt(0)
    }
}
