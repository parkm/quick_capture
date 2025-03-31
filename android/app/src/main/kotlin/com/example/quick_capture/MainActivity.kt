package com.example.quick_capture

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.net.Uri
import android.content.ContentResolver
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileOutputStream
import android.os.Environment
import java.util.UUID

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.quick.capture/share"
    private var sharedText: String? = null
    private var sharedUrl: String? = null
    private var sharedFilePaths: MutableList<String> = mutableListOf()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedData" -> {
                    val data = HashMap<String, Any?>()
                    data["text"] = sharedText
                    data["url"] = sharedUrl
                    data["filePaths"] = sharedFilePaths
                    result.success(data)
                    // Reset after getting
                    sharedText = null
                    sharedUrl = null
                    sharedFilePaths.clear()
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
                }
            } else {
                // Handle single file being sent
                handleSharedFile(intent)
            }

            // Notify Flutter engine
            notifyFlutterEngine()
        } else if (Intent.ACTION_SEND_MULTIPLE == action && type != null) {
            // Handle multiple files being sent
            handleMultipleSharedFiles(intent)
            notifyFlutterEngine()
        }
    }

    private fun handleSharedFile(intent: Intent) {
        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        uri?.let {
            if (isFileTypeSupported(it)) {
                // Create a temporary file and copy the content
                val path = copyUriToTempFile(it)
                if (path != null) {
                    sharedFilePaths.add(path)
                }
            }
        }
    }

    private fun handleMultipleSharedFiles(intent: Intent) {
        val uriList = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
        uriList?.forEach { uri ->
            if (isFileTypeSupported(uri)) {
                val path = copyUriToTempFile(uri)
                if (path != null) {
                    sharedFilePaths.add(path)
                }
            }
        }
    }

    private fun copyUriToTempFile(uri: Uri): String? {
        try {
            val contentResolver = contentResolver
            val mimeType = contentResolver.getType(uri) ?: return null
            val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType) ?: ""

            // Create a temporary file with appropriate extension
            val tempFileName = "shared_${UUID.randomUUID()}.${extension}"
            val tempFile = File(cacheDir, tempFileName)

            // Copy content from URI to the temporary file
            contentResolver.openInputStream(uri)?.use { inputStream ->
                FileOutputStream(tempFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }

            return tempFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun isFileTypeSupported(uri: Uri): Boolean {
        val extension = getFileExtension(uri)
        return extension != null && isSupportedExtension(extension)
    }

    private fun getFileExtension(uri: Uri): String? {
        val contentResolver = contentResolver
        val mimeTypeMap = MimeTypeMap.getSingleton()
        return mimeTypeMap.getExtensionFromMimeType(contentResolver.getType(uri))
    }

    private fun isSupportedExtension(extension: String): Boolean {
        val supportedExtensions = listOf(
            // Images
            "bmp", "png", "jpg", "jpeg", "gif", "svg", "webp", "avif",
            // Audio
            "mp3", "wav", "m4a", "3gp", "flac", "ogg", "oga", "opus",
            // Video
            "mp4", "webm", "ogv", "mov", "mkv",
            // PDFs
            "pdf"
        )
        return supportedExtensions.contains(extension.lowercase())
    }

    private fun notifyFlutterEngine() {
        // If we have a Flutter engine, notify it
        flutterEngine?.let { engine ->
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            val data = HashMap<String, Any?>()
            data["text"] = sharedText
            data["url"] = sharedUrl
            data["filePaths"] = sharedFilePaths
            channel.invokeMethod("receivedSharedData", data)
        }
    }
}
