package com.example.music_flow_mobile

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.audiofx.AudioEffect
import android.media.audiofx.Visualizer
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class VisualizerHandler(private val activity: Activity) {
    companion object {
        private const val METHOD_CHANNEL = "com.example.music_flow_mobile/visualizer_method"
        private const val EVENT_CHANNEL = "com.example.music_flow_mobile/visualizer_event"
    }

    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var captureWaveform = true
    private var captureFft = false

    private val visualizerListener = object : Visualizer.OnDataCaptureListener {
        var lastTimeWave = 0L
        var lastTimeFft = 0L

        override fun onWaveFormDataCapture(visualizer: Visualizer, waveform: ByteArray, samplingRate: Int) {
            if (!captureWaveform) return
            val now = System.currentTimeMillis()
            if (now - lastTimeWave >= 32) {
                lastTimeWave = now
                activity.runOnUiThread {
                    eventSink?.success(waveform)
                }
            }
        }

        override fun onFftDataCapture(visualizer: Visualizer, fft: ByteArray, samplingRate: Int) {
            if (!captureFft) return
            val now = System.currentTimeMillis()
            if (now - lastTimeFft >= 32) {
                lastTimeFft = now
                activity.runOnUiThread {
                    eventSink?.success(fft)
                }
            }
        }
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVisualizer" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    if (ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
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
                "openSystemEqualizer" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    openSystemEqualizer(sessionId, result)
                }
                "setVisualizerCore" -> {
                    val core = call.argument<String>("core") ?: "software"
                    if (core == "hardware") {
                        captureWaveform = false
                        captureFft = true
                    } else {
                        captureWaveform = true
                        captureFft = false
                    }
                    visualizer?.let {
                        it.enabled = false
                        val captureRate = Math.min(Visualizer.getMaxCaptureRate(), 30000)
                        it.setDataCaptureListener(visualizerListener, captureRate, captureWaveform, captureFft)
                        it.enabled = true
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun openSystemEqualizer(sessionId: Int, result: MethodChannel.Result) {
        try {
            val broadcastIntent = Intent(AudioEffect.ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION).apply {
                putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
                putExtra(AudioEffect.EXTRA_PACKAGE_NAME, activity.packageName)
                putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
            }
            activity.sendBroadcast(broadcastIntent)
        } catch (_: Exception) {}

        var opened = false
        val panelIntent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL).apply {
            putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
            putExtra(AudioEffect.EXTRA_PACKAGE_NAME, activity.packageName)
            putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
        }
        if (panelIntent.resolveActivity(activity.packageManager) != null) {
            try {
                activity.startActivityForResult(panelIntent, 0)
                opened = true
            } catch (_: Exception) {}
        }

        if (!opened) {
            try {
                val miuiIntent = Intent().apply {
                    setClassName("com.miui.misound", "com.miui.misound.HeadsetSettingsActivity")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                if (miuiIntent.resolveActivity(activity.packageManager) != null) {
                    activity.startActivity(miuiIntent)
                    opened = true
                }
            } catch (_: Exception) {}
        }

        if (!opened) {
            try {
                val soundSettingsIntent = Intent(Settings.ACTION_SOUND_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                activity.startActivity(soundSettingsIntent)
                opened = true
            } catch (_: Exception) {}
        }

        if (opened) {
            result.success(true)
        } else {
            result.error("NOT_FOUND", "Could not open sound settings", null)
        }
    }

    private fun startVisualizer(sessionId: Int) {
        stopVisualizer()
        try {
            visualizer = Visualizer(sessionId).apply {
                captureSize = Visualizer.getCaptureSizeRange()[1]
                val captureRate = Math.min(Visualizer.getMaxCaptureRate(), 30000)
                setDataCaptureListener(visualizerListener, captureRate, captureWaveform, captureFft)
                enabled = true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun stopVisualizer() {
        try {
            visualizer?.enabled = false
            visualizer?.release()
            visualizer = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
