package com.example.music_flow_mobile

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class ApkInstallerHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    private val channelName = "com.example.music_flow_mobile/installer"

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, channelName).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "installApk") {
            val filePath = call.argument<String>("filePath")
            if (filePath == null) {
                result.error("INVALID_PATH", "File path is null", null)
                return
            }
            try {
                val file = File(filePath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                    return
                }

                // Перевірка дозволу на встановлення з невідомих джерел для Android 8.0+
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    if (!context.packageManager.canRequestPackageInstalls()) {
                        val manageIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = Uri.parse("package:${context.packageName}")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(manageIntent)
                        result.error("PERMISSION_REQUIRED", "Будь ласка, дозвольте встановлення оновлень для Music Flow у Налаштуваннях", null)
                        return
                    }
                }

                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
                }
                context.startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                result.error("INSTALL_ERROR", e.message, null)
            }
        } else if (call.method == "getAppVersion") {
            try {
                val pInfo = context.packageManager.getPackageInfo(context.packageName, 0)
                val versionName = pInfo.versionName ?: "1.0.0"
                val versionCode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                    pInfo.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    pInfo.versionCode.toLong()
                }
                result.success(mapOf(
                    "versionName" to versionName,
                    "versionCode" to versionCode
                ))
            } catch (e: Exception) {
                result.error("VERSION_ERROR", e.message, null)
            }
        } else if (call.method == "showUpdateNotification") {
            try {
                val title = call.argument<String>("title") ?: "Доступне оновлення MusicFlow"
                val message = call.argument<String>("message") ?: "Натисніть, щоб переглянути оновлення"
                showSystemNotification(title, message)
                result.success(true)
            } catch (e: Exception) {
                result.error("NOTIFICATION_ERROR", e.message, null)
            }
        } else {
            result.notImplemented()
        }
    }

    private fun showSystemNotification(title: String, message: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        val channelId = "music_flow_updates_channel"

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                channelId,
                "Оновлення додатку",
                android.app.NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Сповіщення про нові версії MusicFlow"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        } else {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = android.app.PendingIntent.getActivity(context, 1002, intent, flags)
        val icon = context.applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.stat_notify_sync

        val notification = androidx.core.app.NotificationCompat.Builder(context, channelId)
            .setSmallIcon(icon)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(androidx.core.app.NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(1002, notification)
    }
}
