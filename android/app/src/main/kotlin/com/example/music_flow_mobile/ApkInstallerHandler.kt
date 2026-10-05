package com.example.music_flow_mobile

import android.content.Context
import android.content.Intent
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
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
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
        } else {
            result.notImplemented()
        }
    }
}
