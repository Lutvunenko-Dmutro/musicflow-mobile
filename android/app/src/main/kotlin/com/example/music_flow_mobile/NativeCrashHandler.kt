package com.example.music_flow_mobile

import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class NativeCrashHandler(private val context: Context) {
    companion object {
        private const val TAG = "NativeCrashHandler"
        private const val CHANNEL = "com.example.music_flow_mobile/native_crash"
        private const val CRASH_FILE_NAME = "pending_native_crash.json"
        private const val DEFAULT_SERVER_URL = "http://localhost:8080"
        private var isInstalled = false

        fun install(context: Context) {
            if (isInstalled) return
            isInstalled = true

            val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
            Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
                try {
                    Log.e(TAG, "🚨 Перехоплено нативний збій Android!", throwable)
                    val crashData = buildCrashJson(context, thread, throwable)

                    // 1. Зберігаємо у локальний файл для надійності
                    saveCrashToFile(context, crashData)

                    // 2. Спробуємо негайно відправити по HTTP на сервер
                    sendCrashSync(context, crashData)
                } catch (e: Exception) {
                    Log.e(TAG, "Помилка обробки нативного збою", e)
                } finally {
                    defaultHandler?.uncaughtException(thread, throwable)
                }
            }
            Log.i(TAG, "🛡️ NativeCrashHandler успішно встановлено")
        }

        private fun buildCrashJson(context: Context, thread: Thread, throwable: Throwable): JSONObject {
            val json = JSONObject()
            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
                timeZone = TimeZone.getDefault()
            }
            val timestamp = sdf.format(Date())

            val pInfo = try {
                context.packageManager.getPackageInfo(context.packageName, 0)
            } catch (e: Exception) {
                null
            }
            val versionName = pInfo?.versionName ?: "1.0.0"
            val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pInfo?.longVersionCode ?: 1
            } else {
                @Suppress("DEPRECATION")
                pInfo?.versionCode ?: 1
            }

            json.put("device", "android ${Build.MODEL} (Android ${Build.VERSION.RELEASE}, API ${Build.VERSION.SDK_INT})")
            json.put("appVersion", "$versionName+$versionCode")
            json.put("timestamp", timestamp)
            json.put("error", "${throwable.javaClass.name}: ${throwable.message ?: "No message"}")
            json.put("stackTrace", Log.getStackTraceString(throwable))
            json.put("source", "AndroidNativeJava")

            val logs = JSONArray().apply {
                put("🚨 Фатальний виняток у нативному потоці Android: ${thread.name} (id: ${thread.id})")
                put("Thread state: ${thread.state}")
            }
            json.put("recentLogs", logs)

            return json
        }

        private fun saveCrashToFile(context: Context, json: JSONObject) {
            try {
                val file = File(context.filesDir, CRASH_FILE_NAME)
                file.writeText(json.toString(2))
                Log.i(TAG, "Звіт нативного крашу збережено: ${file.absolutePath}")
            } catch (e: Exception) {
                Log.e(TAG, "Не вдалося зберегти нативний звіт у файл", e)
            }
        }

        private fun getServerUrl(context: Context): String {
            return try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val url = prefs.getString("flutter.telemetry_server_url", null)
                if (!url.isNullOrBlank()) url.trim().removeSuffix("/") else DEFAULT_SERVER_URL
            } catch (e: Exception) {
                DEFAULT_SERVER_URL
            }
        }

        private fun sendCrashSync(context: Context, json: JSONObject) {
            val serverUrl = getServerUrl(context) + "/api/telemetry/crash-report"
            val syncThread = Thread {
                try {
                    val url = URL(serverUrl)
                    val conn = (url.openConnection() as HttpURLConnection).apply {
                        requestMethod = "POST"
                        connectTimeout = 1500
                        readTimeout = 1500
                        doOutput = true
                        setRequestProperty("Content-Type", "application/json; charset=utf-8")
                    }
                    OutputStreamWriter(conn.outputStream, "UTF-8").use { writer ->
                        writer.write(json.toString())
                        writer.flush()
                    }
                    val code = conn.responseCode
                    Log.i(TAG, "Відповідь сервера на нативний звіт: $code")
                    conn.disconnect()
                } catch (e: Exception) {
                    Log.w(TAG, "Синхронна відправка нативного крашу не вдалася: ${e.message}")
                }
            }
            syncThread.start()
            try {
                syncThread.join(1600)
            } catch (_: InterruptedException) {}
        }
    }

    fun register(messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingNativeCrash" -> {
                    val file = File(context.filesDir, CRASH_FILE_NAME)
                    if (file.exists()) {
                        try {
                            val content = file.readText()
                            result.success(content)
                        } catch (e: Exception) {
                            result.error("READ_ERROR", e.message, null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                "clearPendingNativeCrash" -> {
                    val file = File(context.filesDir, CRASH_FILE_NAME)
                    if (file.exists()) {
                        file.delete()
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
