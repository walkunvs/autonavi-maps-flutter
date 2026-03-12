package com.autonavi.location.flutter

import android.content.Context
import com.amap.api.location.AMapLocationClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AutonaviLocationPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var geofenceEventChannel: EventChannel
    private var streamHandler: LocationStreamHandler? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        // Privacy compliance
        AMapLocationClient.updatePrivacyShow(binding.applicationContext, true, true)
        AMapLocationClient.updatePrivacyAgree(binding.applicationContext, true)

        methodChannel = MethodChannel(
            binding.binaryMessenger,
            "plugins.autonavi.flutter/location_method"
        )
        methodChannel.setMethodCallHandler(this)

        streamHandler = LocationStreamHandler(binding.applicationContext)
        eventChannel = EventChannel(
            binding.binaryMessenger,
            "plugins.autonavi.flutter/location"
        )
        eventChannel.setStreamHandler(streamHandler)

        geofenceEventChannel = EventChannel(
            binding.binaryMessenger,
            "plugins.autonavi.flutter/geofence_events"
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        streamHandler?.dispose()
        streamHandler = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: run {
            result.error("NOT_INITIALIZED", "Plugin not initialized", null)
            return
        }

        when (call.method) {
            "location#getOnce" -> {
                @Suppress("UNCHECKED_CAST")
                val options = call.arguments as? Map<String, Any> ?: emptyMap()
                LocationStreamHandler(ctx).getOnce(
                    options,
                    onSuccess = { result.success(it) },
                    onError = { code, msg -> result.error(code, msg, null) },
                )
            }
            "location#updateOptions" -> {
                @Suppress("UNCHECKED_CAST")
                val options = call.arguments as? Map<String, Any> ?: emptyMap()
                streamHandler?.updateOptions(options)
                result.success(null)
            }
            "geofence#addCircle" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any> ?: emptyMap()
                // Geofence implementation would use AMapLocationClient's geofence API
                result.success(null)
            }
            "geofence#remove" -> {
                result.success(null)
            }
            "geofence#removeAll" -> {
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
