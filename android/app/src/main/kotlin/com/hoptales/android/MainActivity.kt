package com.hoptales.android

import android.media.AudioManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.BookScreen
import com.hoptales.android.home.FriendsScreen
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.home.JourneyMapScreen
import com.hoptales.android.home.WardrobeScreen
import com.hoptales.android.reading.ReadingScreen
import com.hoptales.content.Friend
import com.hoptales.content.Story
import com.hoptales.content.tapping
import com.hoptales.content.undressing

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        volumeControlStream = AudioManager.STREAM_MUSIC
        val app = application as HopTalesApplication
        val store = app.progressStore
        setContent {
            HopTalesTheme {
                var storyID by rememberSaveable { mutableStateOf<String?>(null) }
                var sheet by rememberSaveable { mutableStateOf<String?>(null) }
                val progress by store.progress.collectAsStateWithLifecycle()
                val route = storyID?.let(app.library::get) ?: sheet
                BackHandler(enabled = storyID == null && sheet != null) { sheet = null }
                AnimatedContent(
                    targetState = route,
                    transitionSpec = { fadeIn() togetherWith fadeOut() },
                    label = "route",
                ) { target ->
                    val friend = progress.journey.activeFriend
                    when {
                        target is Story -> ReadingScreen(
                            story = target,
                            onDone = { storyID = null },
                            onStory = { storyID = it.id },
                            onTryItOn = {
                                storyID = null
                                sheet = Sheet.wardrobe(it)
                            },
                        )

                        target == Sheet.JOURNEY -> JourneyMapScreen(
                            library = app.library,
                            journey = progress.journey,
                            onFriend = { tapped -> store.update { it.copy(journey = it.journey.readingWith(tapped)) } },
                            onBigStory = {
                                sheet = null
                                storyID = it.id
                            },
                            onDone = { sheet = null },
                        )

                        target == Sheet.FRIENDS -> FriendsScreen(
                            progress = progress,
                            wardrobe = app.wardrobe,
                            onFriend = { tapped -> store.update { it.copy(journey = it.journey.readingWith(tapped)) } },
                            onJourney = { sheet = Sheet.JOURNEY },
                            onDone = { sheet = null },
                        )

                        target is String && target.startsWith(Sheet.WARDROBE) -> {
                            val dressing = Sheet.friend(target) ?: friend
                            WardrobeScreen(
                                friend = dressing,
                                progress = progress,
                                wardrobe = app.wardrobe,
                                onItem = { item -> store.update { it.tapping(item, dressing, app.wardrobe) } },
                                onJustMe = { store.update { it.undressing(dressing) } },
                                onDone = { sheet = null },
                            )
                        }

                        target is String && target.startsWith(Sheet.BOOK) -> BookScreen(
                            library = app.library,
                            progress = progress,
                            friend = Sheet.friend(target) ?: friend,
                            onFriend = { sheet = Sheet.book(it) },
                            onDone = { sheet = null },
                        )

                        else -> HomeScreen(
                            library = app.library,
                            progress = progress,
                            onStory = { storyID = it.id },
                            onJourney = { sheet = Sheet.JOURNEY },
                            onFriends = { sheet = Sheet.FRIENDS },
                            onWardrobe = { sheet = Sheet.wardrobe(friend) },
                            onBook = { sheet = Sheet.book(friend) },
                        )
                    }
                }
            }
        }
    }
}

private object Sheet {
    const val JOURNEY = "journey"
    const val FRIENDS = "friends"
    const val WARDROBE = "wardrobe:"
    const val BOOK = "book:"

    fun wardrobe(friend: Friend) = WARDROBE + friend.key

    fun book(friend: Friend) = BOOK + friend.key

    fun friend(sheet: String): Friend? = Friend.entries.firstOrNull { sheet.endsWith(":${it.key}") }
}
