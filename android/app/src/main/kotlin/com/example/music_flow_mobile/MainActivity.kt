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
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    android.media.MediaScannerConnection.scanFile(
                        this@MainActivity,
                        arrayOf(path),
                        null,
                        null
                    )
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Path is null", null)
                }
            } else {
                result.notImplemented()
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
