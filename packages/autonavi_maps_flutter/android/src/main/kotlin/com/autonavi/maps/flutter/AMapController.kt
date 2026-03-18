package com.autonavi.maps.flutter

import android.content.Context
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class AMapController(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    params: Map<String, Any>,
) : PlatformView, MethodChannel.MethodCallHandler {

    private val adapter = AMapSDKAdapter(context)
    private val channel = MethodChannel(messenger, "plugins.autonavi.flutter/amap_map_$viewId")

    init {
        channel.setMethodCallHandler(this)

        // Wire adapter event callbacks → Flutter channel
        adapter.onCameraMove   = { args -> channel.invokeMethod("camera#onMove", args) }
        adapter.onCameraIdle   = { channel.invokeMethod("camera#onIdle", null) }
        adapter.onMapTap       = { args -> channel.invokeMethod("map#onTap", args) }
        adapter.onMapLongPress = { args -> channel.invokeMethod("map#onLongPress", args) }
        adapter.onMarkerTap    = { id -> channel.invokeMethod("marker#onTap", mapOf("markerId" to id)) }

        // Initial state
        @Suppress("UNCHECKED_CAST")
        (params["initialCameraPosition"] as? Map<String, Any>)?.let { adapter.applyInitialCamera(it) }

        @Suppress("UNCHECKED_CAST")
        (params["options"] as? Map<String, Any>)?.let { adapter.applyOptions(it) }

        @Suppress("UNCHECKED_CAST")
        (params["markersToAdd"] as? List<Map<String, Any>>)?.forEach { adapter.addMarker(it) }

        @Suppress("UNCHECKED_CAST")
        (params["polylinesToAdd"] as? List<Map<*, *>>)?.let {
            adapter.handlePolylineUpdates(mapOf("polylinesToAdd" to it))
        }

        @Suppress("UNCHECKED_CAST")
        (params["polygonsToAdd"] as? List<Map<*, *>>)?.let {
            adapter.handlePolygonUpdates(mapOf("polygonsToAdd" to it))
        }

        @Suppress("UNCHECKED_CAST")
        (params["circlesToAdd"] as? List<Map<*, *>>)?.let {
            adapter.handleCircleUpdates(mapOf("circlesToAdd" to it))
        }
    }

    override fun getView(): View = adapter.nativeView()

    override fun dispose() {
        channel.setMethodCallHandler(null)
        adapter.destroy()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "map#update" -> {
                @Suppress("UNCHECKED_CAST")
                call.argument<Map<String, Any>>("options")?.let { adapter.applyOptions(it) }
                result.success(null)
            }
            "map#moveCamera" -> {
                @Suppress("UNCHECKED_CAST")
                adapter.applyCameraUpdate(call.arguments as Map<*, *>, animated = false)
                result.success(null)
            }
            "map#animateCamera" -> {
                @Suppress("UNCHECKED_CAST")
                adapter.applyCameraUpdate(call.arguments as Map<*, *>, animated = true)
                result.success(null)
            }
            "map#getCameraPosition" -> result.success(adapter.currentCameraPosition())
            "map#getLatLng" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<*, *>
                result.success(adapter.latLng(
                    fromScreen = (args["x"] as Number).toInt(),
                    y = (args["y"] as Number).toInt()
                ))
            }
            "map#getScreenCoordinate" -> {
                @Suppress("UNCHECKED_CAST")
                result.success(adapter.screenCoordinate(forLatLng = call.arguments as Map<*, *>))
            }
            "map#takeSnapshot" -> {
                adapter.takeSnapshot { bytes -> result.success(bytes) }
            }
            "markers#update" -> {
                @Suppress("UNCHECKED_CAST")
                adapter.handleMarkerUpdates(call.arguments as Map<*, *>)
                result.success(null)
            }
            "markers#showInfoWindow" -> {
                adapter.showInfoWindow(call.argument<String>("markerId") ?: "")
                result.success(null)
            }
            "markers#hideInfoWindow" -> {
                adapter.hideInfoWindow(call.argument<String>("markerId") ?: "")
                result.success(null)
            }
            "markers#isInfoWindowShown" -> {
                result.success(adapter.isInfoWindowShown(call.argument<String>("markerId") ?: ""))
            }
            "polylines#update" -> {
                @Suppress("UNCHECKED_CAST")
                adapter.handlePolylineUpdates(call.arguments as Map<*, *>)
                result.success(null)
            }
            "polygons#update" -> {
                @Suppress("UNCHECKED_CAST")
                adapter.handlePolygonUpdates(call.arguments as Map<*, *>)
                result.success(null)
            }
            "circles#update" -> {
                @Suppress("UNCHECKED_CAST")
                adapter.handleCircleUpdates(call.arguments as Map<*, *>)
                result.success(null)
            }
            "coordinate#convertFromWGS84" -> {
                @Suppress("UNCHECKED_CAST")
                result.success(adapter.convertFromWGS84(call.arguments as Map<*, *>))
            }
            else -> result.notImplemented()
        }
    }
}
