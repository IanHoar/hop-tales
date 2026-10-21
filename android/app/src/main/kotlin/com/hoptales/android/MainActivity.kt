package com.hoptales.android

import android.media.AudioManager
import android.os.Bundle
import androidx.activity.ComponentActivity
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
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.hoptales.android.design.HopTalesTheme
import com.hoptales.android.home.HomeScreen
import com.hoptales.android.reading.ReadingScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        volumeControlStream = AudioManager.STREAM_MUSIC
        val app = application as HopTalesApplication
        setContent {
            HopTalesTheme {
                var storyID by rememberSaveable { mutableStateOf<String?>(null) }
                val progress by app.progressStore.progress.collectAsStateWithLifecycle()
                AnimatedContent(
                    targetState = storyID?.let(app.library::get),
                    transitionSpec = { fadeIn() togetherWith fadeOut() },
                    label = "route",
                ) { story ->
                    if (story == null) {
                        HomeScreen(library = app.library, progress = progress, onStory = { storyID = it.id })
                    } else {
                        ReadingScreen(story = story, onDone = { storyID = null })
                    }
                }
            }
        }
    }
}
