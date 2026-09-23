package com.example.music_flow_mobile

import android.Manifest
import android.content.pm.PackageManager
import android.media.audiofx.Visualizer
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: AudioServiceActivity() {
    private val METHOD_CHANNEL = "com.example.music_flow_mobile/visualizer_method"
    private val EVENT_CHANNEL = "com.example.music_flow_mobile/visualizer_event"

    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVisualizer" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                        startVisualizer(sessionId)
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "Record audio permission not granted", null)
                    }
                }
                "stopVisualizer" -> {
                    stopVisualizer()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.music_flow_mobile/media_scanner").setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        android.media.MediaScannerConnection.scanFile(
                            this@MainActivity,
                            arrayOf(path),
                            null
                        ) { _, _ -> result.success(true) }
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                "scanFileWithCover" -> {
                    val path = call.argument<String>("path")
                    val title = call.argument<String>("title") ?: ""
                    val artist = call.argument<String>("artist") ?: ""
                    val coverList = call.argument<List<Int>>("coverBytes")
                    val coverBytes = coverList?.let { list -> ByteArray(list.size) { list[it].toByte() } }

                    if (path == null) {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                        return@setMethodCallHandler
                    }

                    // 1. Save cover art as a .jpg file next to the audio file
                    var coverFilePath: String? = null
                    if (coverBytes != null) {
                        try {
                            val audioFile = java.io.File(path)
                            val coverFile = java.io.File(audioFile.parent, audioFile.nameWithoutExtension + ".jpg")
                            coverFile.writeBytes(coverBytes)
                            coverFilePath = coverFile.absolutePath
                            android.util.Log.d("MediaScanner", "Cover art saved to: $coverFilePath")
                        } catch (e: Exception) {
                            android.util.Log.w("MediaScanner", "Failed to save cover file: ${e.message}")
                        }
                    }

                    // 2. Scan the audio file
                    android.media.MediaScannerConnection.scanFile(
                        this@MainActivity,
                        arrayOf(path),
                        null
                    ) { _, uri ->
                        if (uri != null && coverBytes != null) {
                            try {
                                val resolver = contentResolver
                                // 3. Query MediaStore to find the album_id for this audio file
                                val cursor = resolver.query(
                                    uri,
                                    arrayOf(android.provider.MediaStore.Audio.Media.ALBUM_ID),
                                    null, null, null
                                )
                                val albumId = cursor?.use {
                                    if (it.moveToFirst()) {
                                        it.getLong(it.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media.ALBUM_ID))
                                    } else null
                                }

                                if (albumId != null) {
                                    // 4. Write cover art to MediaStore album art URI
                                    val albumArtUri = android.content.ContentUris.withAppendedId(
                                        android.net.Uri.parse("content://media/external/audio/albumart"),
                                        albumId
                                    )
                                    try {
                                        resolver.openOutputStream(albumArtUri, "w")?.use { os ->
                                            os.write(coverBytes)
                                            os.flush()
                                        }
                                        android.util.Log.d("MediaScanner", "Album art written for album_id=$albumId")
                                    } catch (e: Exception) {
                                        android.util.Log.w("MediaScanner", "openOutputStream failed: ${e.message}, trying insert")
                                        // Fallback: try ContentValues insert
                                        if (coverFilePath != null) {
                                            try {
                                                val values = android.content.ContentValues().apply {
                                                    put("album_id", albumId)
                                                    put("_data", coverFilePath)
                                                }
                                                resolver.insert(
                                                    android.net.Uri.parse("content://media/external/audio/albumart"),
                                                    values
                                                )
                                                android.util.Log.d("MediaScanner", "Album art inserted via ContentValues")
                                            } catch (e2: Exception) {
                                                android.util.Log.w("MediaScanner", "ContentValues insert also failed: ${e2.message}")
                                            }
                                        }
                                    }
                                } else {
                                    android.util.Log.w("MediaScanner", "Could not find album_id for uri=$uri")
                                }
                            } catch (e: Exception) {
                                android.util.Log.w("MediaScanner", "Error setting album art: ${e.message}")
                            }
                        }
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

    }

    private fun startVisualizer(sessionId: Int) {
        stopVisualizer()
        try {
            visualizer = Visualizer(sessionId)
            visualizer?.captureSize = Visualizer.getCaptureSizeRange()[1] // Max capture size
            val captureRate = Math.min(Visualizer.getMaxCaptureRate(), 30000)
            visualizer?.setDataCaptureListener(object : Visualizer.OnDataCaptureListener {
                var lastTime = 0L
                override fun onWaveFormDataCapture(visualizer: Visualizer, waveform: ByteArray, samplingRate: Int) {
                    val now = System.currentTimeMillis()
                    // Throttle to ~30 FPS (32ms) to prevent flooding the Flutter bridge
                    if (now - lastTime >= 32) {
                        lastTime = now
                        runOnUiThread {
                            eventSink?.success(waveform)
                        }
                    }
                }

                override fun onFftDataCapture(visualizer: Visualizer, fft: ByteArray, samplingRate: Int) {}
            }, captureRate, true, false)
            
            visualizer?.enabled = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopVisualizer() {
        try {
            visualizer?.enabled = false
            visualizer?.release()
            visualizer = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
