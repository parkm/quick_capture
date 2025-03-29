package com.example.quick_capture

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.quick.capture/share"
    private var sharedText: String? = null
    private var sharedUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedData" -> {
                    val data = HashMap<String, String?>()
                    data["text"] = sharedText
                    data["url"] = sharedUrl
                    result.success(data)
                    // Reset after getting
                    sharedText = null
                    sharedUrl = null
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            if ("text/plain" == type) {
                // Handle text being sent
                val receivedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                receivedText?.let {
                    // If text is a URL, treat it as a URL
                    if (it.startsWith("http://") || it.startsWith("https://")) {
                        sharedUrl = it
                        sharedText = ""
                    } else {
                        sharedText = it
                        // Try to find any URL in the shared text
                        val urlRegex = Regex("https?://[^\\s]+")
                        val urlMatch = urlRegex.find(it)
                        if (urlMatch != null) {
                            sharedUrl = urlMatch.value
                        }
                    }

                    // Also check for EXTRA_SUBJECT as title or context
                    val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
                    if (subject != null && sharedText?.isEmpty() == true) {
                        sharedText = subject
                    }

                    // If we have a Flutter engine, notify it
                    flutterEngine?.let { engine ->
                        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                        val data = HashMap<String, String?>()
                        data["text"] = sharedText
                        data["url"] = sharedUrl
                        channel.invokeMethod("receivedSharedData", data)
                    }
                }
            }
        }
    }
}
