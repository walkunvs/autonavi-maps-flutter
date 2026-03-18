package com.autonavi.location.flutter

import android.content.Context
import io.flutter.plugin.common.EventChannel

class LocationStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    private val adapter = AMapLocationAdapter(context)

    override fun onListen(args: Any?, events: EventChannel.EventSink) {
        @Suppress("UNCHECKED_CAST")
        val options = parseOptions(args as? Map<String, Any> ?: emptyMap())
        adapter.onLocation = { result -> events.success(result) }
        adapter.onError    = { code, msg -> events.error(code, msg, null) }
        adapter.startContinuous(options)
    }

    override fun onCancel(args: Any?) {
        adapter.stop()
    }

    fun getOnce(
        options: Map<String, Any>,
        onSuccess: (Map<String, Any?>) -> Unit,
        onError: (String, String?) -> Unit,
    ) {
        adapter.startOnce(parseOptions(options), onSuccess, onError)
    }

    fun updateOptions(options: Map<String, Any>) {
        adapter.updateOptions(parseOptions(options))
    }

    fun dispose() {
        adapter.stop()
    }

    private fun parseOptions(options: Map<String, Any>): LocationOptions = LocationOptions(
        accuracy       = (options["accuracy"]       as? Int)    ?: 2,
        intervalMs     = (options["intervalMs"]     as? Int)    ?: 2000,
        needAddress    = (options["needAddress"]    as? Boolean) ?: true,
        distanceFilter = (options["distanceFilter"] as? Number)?.toFloat() ?: 0f,
    )
}
