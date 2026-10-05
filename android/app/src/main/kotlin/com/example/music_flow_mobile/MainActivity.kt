package com.example.music_flow_mobile

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: AudioServiceActivity() {
    private lateinit var visualizerHandler: VisualizerHandler
    private lateinit var mediaScannerHandler: MediaScannerHandler
    private lateinit var apkInstallerHandler: ApkInstallerHandler
    private lateinit var nativeCrashHandler: NativeCrashHandler

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        NativeCrashHandler.install(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        NativeCrashHandler.install(applicationContext)

        nativeCrashHandler = NativeCrashHandler(this).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }

        visualizerHandler = VisualizerHandler(this).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }

        mediaScannerHandler = MediaScannerHandler(this).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }

        apkInstallerHandler = ApkInstallerHandler(this).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onDestroy() {
        visualizerHandler.stopVisualizer()
        super.onDestroy()
    }
}
