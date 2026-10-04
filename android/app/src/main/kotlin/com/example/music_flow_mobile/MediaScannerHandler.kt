package com.example.music_flow_mobile

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.media.MediaScannerConnection
import android.net.Uri
import android.provider.MediaStore
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MediaScannerHandler(private val activity: Activity) {
    companion object {
        private const val CHANNEL = "com.example.music_flow_mobile/media_scanner"
        private const val TAG = "MediaScanner"
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        MediaScannerConnection.scanFile(
                            activity,
                            arrayOf(path),
                            null
                        ) { _, _ -> result.success(true) }
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                "scanFileWithCover" -> {
                    val path = call.argument<String>("path")
                    val coverList = call.argument<List<Int>>("coverBytes")
                    val coverBytes = coverList?.let { list -> ByteArray(list.size) { list[it].toByte() } }

                    if (path == null) {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                        return@setMethodCallHandler
                    }

                    var coverFilePath: String? = null
                    if (coverBytes != null) {
                        try {
                            val audioFile = File(path)
                            val coverFile = File(audioFile.parent, audioFile.nameWithoutExtension + ".jpg")
                            coverFile.writeBytes(coverBytes)
                            coverFilePath = coverFile.absolutePath
                            Log.d(TAG, "Cover art saved to: $coverFilePath")
                        } catch (e: Exception) {
                            Log.w(TAG, "Failed to save cover file: ${e.message}")
                        }
                    }

                    MediaScannerConnection.scanFile(
                        activity,
                        arrayOf(path),
                        null
                    ) { _, uri ->
                        if (uri != null && coverBytes != null) {
                            try {
                                val resolver = activity.contentResolver
                                val cursor = resolver.query(
                                    uri,
                                    arrayOf(MediaStore.Audio.Media.ALBUM_ID),
                                    null, null, null
                                )
                                val albumId = cursor?.use {
                                    if (it.moveToFirst()) {
                                        it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID))
                                    } else null
                                }

                                if (albumId != null) {
                                    val albumArtUri = ContentUris.withAppendedId(
                                        Uri.parse("content://media/external/audio/albumart"),
                                        albumId
                                    )
                                    try {
                                        resolver.openOutputStream(albumArtUri, "w")?.use { os ->
                                            os.write(coverBytes)
                                            os.flush()
                                        }
                                        Log.d(TAG, "Album art written for album_id=$albumId")
                                    } catch (e: Exception) {
                                        Log.w(TAG, "openOutputStream failed: ${e.message}, trying insert")
                                        if (coverFilePath != null) {
                                            try {
                                                val values = ContentValues().apply {
                                                    put("album_id", albumId)
                                                    put("_data", coverFilePath)
                                                }
                                                resolver.insert(
                                                    Uri.parse("content://media/external/audio/albumart"),
                                                    values
                                                )
                                                Log.d(TAG, "Album art inserted via ContentValues")
                                            } catch (e2: Exception) {
                                                Log.w(TAG, "ContentValues insert also failed: ${e2.message}")
                                            }
                                        }
                                    }
                                } else {
                                    Log.w(TAG, "Could not find album_id for uri=$uri")
                                }
                            } catch (e: Exception) {
                                Log.w(TAG, "Error setting album art: ${e.message}")
                            }
                        }
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
