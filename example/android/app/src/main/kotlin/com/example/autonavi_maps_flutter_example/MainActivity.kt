package com.example.autonavi_maps_flutter_example

import android.app.Instrumentation
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
        val base = try { getExternalFilesDir(null) ?: filesDir } catch (e: Throwable) { filesDir }
        val dir = File(base, "screenshots").also { it.mkdirs() }
        val file = File(dir, "$name.png")

        // Strategy 1: UiAutomation.takeScreenshot()
        // Accessed via reflection — no compile-time dependency on androidx.test.
        // This is the most reliable approach for instrumented test environments
        // (flutter test) and captures AMap tiles regardless of GPU mode.
        val uaBitmap = takeViaUiAutomation(name)
        if (uaBitmap != null) {
            try {
                FileOutputStream(file).use { out ->
                    uaBitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                }
                Log.i(TAG, "UiAutomation saved $name → ${file.absolutePath}")
                result.success(file.absolutePath)
            } catch (e: Exception) {
                Log.e(TAG, "UiAutomation save failed for $name: ${e.message}")
                result.success(null)
            } finally {
                uaBitmap.recycle()
            }
            return
        }

        // Strategy 2: PixelCopy (API 26+).
        // Reads the hardware compositor framebuffer.  May fail on some emulator
        // GPU configurations (SwiftShader), in which case strategy 1 was already
        // attempted above.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.w(TAG, "API 26+ required for PixelCopy; no screenshot for $name")
            result.success(null)
            return
        }

        val bitmap: Bitmap
        try {
            val view = window.decorView
            val w = view.width
            val h = view.height
            if (w <= 0 || h <= 0) {
                Log.w(TAG, "View not laid out (${w}x${h}); skipping $name")
                result.success(null)
                return
            }
            bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        } catch (e: Throwable) {
            Log.e(TAG, "Bitmap setup error for $name: ${e.message}")
            result.success(null)
            return
        }

        try {
            PixelCopy.request(
                window, bitmap,
                { copyResult ->
                    if (copyResult == PixelCopy.SUCCESS) {
                        try {
                            FileOutputStream(file).use { out ->
                                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                            }
                            Log.i(TAG, "PixelCopy saved $name → ${file.absolutePath}")
                            result.success(file.absolutePath)
                        } catch (e: Exception) {
                            Log.e(TAG, "PixelCopy save failed for $name: ${e.message}")
                            result.success(null)
                        } finally {
                            bitmap.recycle()
                        }
                    } else {
                        bitmap.recycle()
                        Log.e(TAG, "PixelCopy failed for $name: code=$copyResult")
                        result.success(null)
                    }
                },
                Handler(Looper.getMainLooper()),
            )
        } catch (e: Throwable) {
            bitmap.recycle()
            Log.e(TAG, "PixelCopy.request error for $name: ${e.message}")
            result.success(null)
        }
    }

    /**
     * Obtains [android.app.UiAutomation] via reflection so the class is looked
     * up at runtime only — no compile-time dependency on androidx.test is needed.
     * Returns null if instrumentation is not available (production builds) or if
     * the screenshot call fails for any reason.
     */
    private fun takeViaUiAutomation(name: String): Bitmap? {
        return try {
            val reg = Class.forName("androidx.test.platform.app.InstrumentationRegistry")
            val instr = reg.getMethod("getInstrumentation").invoke(null) as? Instrumentation
            if (instr == null) {
                Log.w(TAG, "Instrumentation not available for $name")
                return null
            }
            val bitmap = instr.uiAutomation?.takeScreenshot()
            if (bitmap == null) Log.w(TAG, "UiAutomation.takeScreenshot() returned null for $name")
            bitmap
        } catch (e: Throwable) {
            Log.w(TAG, "UiAutomation not available for $name: ${e.message}")
            null
        }
    }
}
