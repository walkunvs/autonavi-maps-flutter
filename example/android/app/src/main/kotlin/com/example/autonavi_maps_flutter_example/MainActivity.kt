package com.example.autonavi_maps_flutter_example

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
        // Signal-based screenshot: write a request file to app-specific external
        // storage; the CI host polls for it, calls `adb exec-out screencap -p`,
        // then writes a done file.  This approach works on every Android emulator
        // regardless of GPU mode (SwiftShader, ANGLE, etc.) because screencap
        // reads directly from SurfaceFlinger.
        val base = getExternalFilesDir(null)
        if (base == null) {
            Log.e(TAG, "External storage unavailable; skipping $name")
            result.success(null)
            return
        }

        val signalFile = File(base, "screenshot_request.txt")
        val doneFile   = File(base, "screenshot_done.txt")
        doneFile.delete() // clear any stale done flag from a previous call

        try {
            signalFile.writeText(name)
            Log.i(TAG, "Screenshot request: $name → ${signalFile.absolutePath}")
        } catch (e: Exception) {
            Log.e(TAG, "Cannot write signal for $name: ${e.message}")
            result.success(null)
            return
        }

        // Poll on a background thread so the Flutter UI thread stays unblocked.
        Thread {
            var elapsed = 0
            while (!doneFile.exists() && elapsed < 10_000) {
                Thread.sleep(200)
                elapsed += 200
            }
            if (doneFile.exists()) {
                doneFile.delete()
                Log.i(TAG, "Screenshot $name done (${elapsed}ms)")
            } else {
                signalFile.delete()
                Log.w(TAG, "Screenshot $name timed out after 10 s")
            }
            runOnUiThread { result.success(null) }
        }.start()
    }
}
