package com.example.music_flow_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class ApkInstallerHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    private val channelName = "com.example.music_flow_mobile/installer"
    private val notificationChannelId = "music_flow_updates_channel"

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, channelName).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installApk" -> handleInstallApk(call, result)
            "getAppVersion" -> handleGetAppVersion(result)
            "showUpdateNotification" -> handleShowUpdateNotification(call, result)
            "showDownloadProgress" -> handleShowDownloadProgress(call, result)
            "showDownloadComplete" -> handleShowDownloadComplete(call, result)
            "cancelDownloadNotification" -> {
                val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                mgr.cancel(1003)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleInstallApk(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: return result.error("INVALID_PATH", "Path is null", null)
        try {
            val file = File(filePath)
            if (!file.exists()) return result.error("FILE_NOT_FOUND", "File missing: $filePath", null)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !context.packageManager.canRequestPackageInstalls()) {
                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                return result.error("PERMISSION_REQUIRED", "Дозвольте встановлення оновлень для Music Flow", null)
            }

            val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", e.message, null)
        }
    }

    private fun handleGetAppVersion(result: MethodChannel.Result) {
        try {
            val pInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            val vName = pInfo.versionName ?: "1.0.0"
            val vCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pInfo.longVersionCode else @Suppress("DEPRECATION") pInfo.versionCode.toLong()
            result.success(mapOf("versionName" to vName, "versionCode" to vCode))
        } catch (e: Exception) {
            result.error("VERSION_ERROR", e.message, null)
        }
    }

    private fun handleShowUpdateNotification(call: MethodCall, result: MethodChannel.Result) {
        val title = call.argument<String>("title") ?: "Доступне оновлення MusicFlow"
        val message = call.argument<String>("message") ?: "Натисніть для перегляду"
        showNotification(1002, title, message, ongoing = false, progress = -1, intent = openAppIntent())
        result.success(true)
    }

    private fun handleShowDownloadProgress(call: MethodCall, result: MethodChannel.Result) {
        val title = call.argument<String>("title") ?: "MusicFlow • Оновлення"
        val message = call.argument<String>("message") ?: ""
        val progress = call.argument<Int>("progress") ?: 0
        val indeterminate = call.argument<Boolean>("indeterminate") ?: false
        showNotification(1003, title, message, ongoing = true, progress = progress, indeterminate = indeterminate, intent = openAppIntent())
        result.success(true)
    }

    private fun handleShowDownloadComplete(call: MethodCall, result: MethodChannel.Result) {
        val title = call.argument<String>("title") ?: "Оновлення завантажено"
        val message = call.argument<String>("message") ?: "Натисніть для встановлення"
        val filePath = call.argument<String>("filePath")
        val intent = if (filePath != null) installApkIntent(filePath) else openAppIntent()
        showNotification(1003, title, message, ongoing = false, progress = -1, intent = intent)
        result.success(true)
    }

    private fun showNotification(
        id: Int, title: String, message: String, ongoing: Boolean, progress: Int,
        indeterminate: Boolean = false, intent: PendingIntent
    ) {
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                notificationChannelId, "Оновлення додатку",
                if (ongoing) NotificationManager.IMPORTANCE_LOW else NotificationManager.IMPORTANCE_DEFAULT
            ).apply { description = "Сповіщення про завантаження та оновлення MusicFlow" }
            mgr.createNotificationChannel(channel)
        }

        val icon = context.applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.stat_sys_download
        val b = NotificationCompat.Builder(context, notificationChannelId)
            .setSmallIcon(icon)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(if (ongoing) NotificationCompat.PRIORITY_LOW else NotificationCompat.PRIORITY_DEFAULT)
            .setOngoing(ongoing)
            .setOnlyAlertOnce(true)
            .setAutoCancel(!ongoing)
            .setContentIntent(intent)

        if (progress >= 0) {
            b.setProgress(100, progress.coerceIn(0, 100), indeterminate)
        }
        if (!ongoing) {
            b.setStyle(NotificationCompat.BigTextStyle().bigText(message))
        }
        mgr.notify(id, b.build())
    }

    private fun openAppIntent(): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE else PendingIntent.FLAG_UPDATE_CURRENT
        return PendingIntent.getActivity(context, 1001, intent, flags)
    }

    private fun installApkIntent(filePath: String): PendingIntent {
        val file = File(filePath)
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE else PendingIntent.FLAG_UPDATE_CURRENT
        return PendingIntent.getActivity(context, 1004, intent, flags)
    }
}
