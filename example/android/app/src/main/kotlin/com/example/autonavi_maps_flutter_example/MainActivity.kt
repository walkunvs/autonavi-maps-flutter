package com.example.autonavi_maps_flutter_example

import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.PixelCopy
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "ScreenshotChannel"
        private const val CHANNEL = "com.example.autonavi/screenshot"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "captureAndSave") {
                    val name = call.arguments as? String ?: run {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    captureAndSave(name, result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun captureAndSave(name: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.w(TAG, "PixelCopy requires API 26+, skipping $name")
            result.success(null)
            return
        }

        val view = window.decorView
        val w = view.width
        val h = view.height
        if (w <= 0 || h <= 0) {
            Log.w(TAG, "View not laid out yet (${w}x${h}), skipping $name")
            result.success(null)
            return
        }

        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)

        PixelCopy.request(
            window,
            bitmap,
            { copyResult ->
                if (copyResult == PixelCopy.SUCCESS) {
                    try {
                        val base = getExternalFilesDir(null) ?: filesDir
                        val dir = File(base, "screenshots").also { it.mkdirs() }
                        val file = File(dir, "$name.png")
                        FileOutputStream(file).use { out ->
                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                        }
                        Log.i(TAG, "Saved $name → ${file.absolutePath}")
                        result.success(file.absolutePath)
                    } catch (e: Exception) {
                        Log.e(TAG, "Save failed for $name: ${e.message}")
                        result.success(null) // don't fail the test
                    } finally {
                        bitmap.recycle()
                    }
                } else {
                    bitmap.recycle()
                    Log.e(TAG, "PixelCopy failed for $name: code=$copyResult")
                    result.success(null) // don't fail the test
                }
            },
            Handler(Looper.getMainLooper()),
        )
    }
}
