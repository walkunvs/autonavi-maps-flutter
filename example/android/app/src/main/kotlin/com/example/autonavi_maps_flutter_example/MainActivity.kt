package com.example.autonavi_maps_flutter_example

import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.view.PixelCopy
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val screenshotChannel = "com.example.autonavi/screenshot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, screenshotChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "captureAndSave") {
                    val name = call.arguments as? String
                    if (name == null) {
                        result.error("INVALID_ARG", "Screenshot name must be a String", null)
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
            result.error("UNSUPPORTED", "PixelCopy requires API 26+", null)
            return
        }

        val decorView = window.decorView
        val bitmap = Bitmap.createBitmap(
            decorView.width,
            decorView.height,
            Bitmap.Config.ARGB_8888
        )

        val thread = HandlerThread("PixelCopyThread")
        thread.start()

        PixelCopy.request(window, bitmap, { copyResult ->
            thread.quitSafely()
            runOnUiThread {
                if (copyResult == PixelCopy.SUCCESS) {
                    try {
                        val dir = File(getExternalFilesDir(null), "screenshots")
                        dir.mkdirs()
                        val file = File(dir, "$name.png")
                        FileOutputStream(file).use { out ->
                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                        }
                        result.success(file.absolutePath)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    } finally {
                        bitmap.recycle()
                    }
                } else {
                    bitmap.recycle()
                    result.error("PIXEL_COPY_FAILED", "PixelCopy result: $copyResult", null)
                }
            }
        }, Handler(thread.looper))
    }
}
