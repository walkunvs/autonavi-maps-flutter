package com.autonavi.location.flutter

import android.content.Context
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationClientOption.AMapLocationMode
import io.flutter.plugin.common.EventChannel

class LocationStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    private var client: AMapLocationClient? = null
    private var currentOptions: Map<String, Any> = emptyMap()

    override fun onListen(args: Any?, events: EventChannel.EventSink) {
        @Suppress("UNCHECKED_CAST")
        val options = args as? Map<String, Any> ?: emptyMap()
        currentOptions = options

        client = AMapLocationClient(context).apply {
            setLocationOption(buildOption(options))
            setLocationListener { result ->
                if (result.errorCode == 0) {
                    events.success(buildResultMap(result))
                } else {
                    events.error(
                        "LOCATION_ERROR_${result.errorCode}",
                        result.errorInfo,
                        null
                    )
                }
            }
            startLocation()
        }
    }

    override fun onCancel(args: Any?) {
        client?.stopLocation()
        client?.onDestroy()
        client = null
    }

    fun getOnce(
        options: Map<String, Any>,
        onSuccess: (Map<String, Any?>) -> Unit,
        onError: (String, String?) -> Unit,
    ) {
        val onceClient = AMapLocationClient(context)
        onceClient.setLocationOption(buildOption(options).apply { isOnceLocation = true })
        onceClient.setLocationListener { result ->
            onceClient.onDestroy()
            if (result.errorCode == 0) {
                onSuccess(buildResultMap(result))
            } else {
                onError("LOCATION_ERROR_${result.errorCode}", result.errorInfo)
            }
        }
        onceClient.startLocation()
    }

    fun updateOptions(options: Map<String, Any>) {
        currentOptions = options
        client?.setLocationOption(buildOption(options))
    }

    fun dispose() {
        client?.stopLocation()
        client?.onDestroy()
        client = null
    }

    private fun buildOption(options: Map<String, Any>): AMapLocationClientOption {
        val accuracyIndex = (options["accuracy"] as? Int) ?: 2
        val mode = when (accuracyIndex) {
            0 -> AMapLocationMode.Battery_Saving
            1 -> AMapLocationMode.Device_Sensors
            else -> AMapLocationMode.Hight_Accuracy
        }

        return AMapLocationClientOption().apply {
            locationMode = mode
            isNeedAddress = options["needAddress"] as? Boolean ?: true
            interval = (options["intervalMs"] as? Int)?.toLong() ?: 2000L
            isOnceLocation = options["onceLocation"] as? Boolean ?: false
            deviceModeDistanceFilter = (options["distanceFilter"] as? Number)?.toFloat() ?: 0f
        }
    }

    private fun buildResultMap(result: com.amap.api.location.AMapLocation): Map<String, Any?> =
        mapOf(
            "latitude" to result.latitude,
            "longitude" to result.longitude,
            "accuracy" to result.accuracy.toDouble(),
            "altitude" to result.altitude,
            "speed" to result.speed.toDouble(),
            "heading" to result.bearing.toDouble(),
            "timestamp" to result.time,
            "address" to result.address,
            "country" to result.country,
            "province" to result.province,
            "city" to result.city,
            "district" to result.district,
            "street" to result.street,
            "streetNum" to result.streetNum,
            "cityCode" to result.cityCode,
            "adCode" to result.adCode,
            "poiName" to result.poiName,
            "aoiName" to result.aoiName,
        )
}
