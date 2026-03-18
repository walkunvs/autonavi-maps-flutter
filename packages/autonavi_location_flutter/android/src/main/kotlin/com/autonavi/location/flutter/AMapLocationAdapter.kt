package com.autonavi.location.flutter

import android.content.Context
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationClientOption.AMapLocationMode

/**
 * Options passed to the location adapter. Plain Kotlin data class — no SDK types exposed.
 */
data class LocationOptions(
    val accuracy: Int = 2,
    val intervalMs: Int = 2000,
    val needAddress: Boolean = true,
    val distanceFilter: Float = 0f,
)

// Top-level typealias — Kotlin does not allow typealias inside class bodies.
typealias LocationResult = Map<String, Any?>

/**
 * Adapter that isolates all AMapLocationClient calls.
 * When upgrading the AMap Location SDK, only this file needs changes.
 */
class AMapLocationAdapter(private val context: Context) {

    // Callbacks set by caller
    var onLocation: ((LocationResult) -> Unit)? = null
    var onError:    ((code: String, message: String?) -> Unit)? = null

    private var client: AMapLocationClient? = null

    // MARK: - Public API

    fun startContinuous(options: LocationOptions) {
        client = AMapLocationClient(context).apply {
            setLocationOption(buildOption(options))
            setLocationListener { result ->
                if (result.errorCode == 0) {
                    onLocation?.invoke(buildResultMap(result))
                } else {
                    onError?.invoke("LOCATION_ERROR_${result.errorCode}", result.errorInfo)
                }
            }
            startLocation()
        }
    }

    fun startOnce(
        options: LocationOptions,
        onSuccess: (LocationResult) -> Unit,
        onError: (code: String, message: String?) -> Unit,
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

    fun stop() {
        client?.stopLocation()
        client?.onDestroy()
        client = null
    }

    fun updateOptions(options: LocationOptions) {
        client?.setLocationOption(buildOption(options))
    }

    // MARK: - Private helpers

    private fun buildOption(options: LocationOptions): AMapLocationClientOption {
        val mode = when (options.accuracy) {
            0    -> AMapLocationMode.Battery_Saving
            1    -> AMapLocationMode.Device_Sensors
            else -> AMapLocationMode.Hight_Accuracy
        }
        return AMapLocationClientOption().apply {
            locationMode = mode
            isNeedAddress = options.needAddress
            interval = options.intervalMs.toLong()
            deviceModeDistanceFilter = options.distanceFilter
        }
    }

    private fun buildResultMap(result: com.amap.api.location.AMapLocation): LocationResult =
        mapOf(
            "latitude"  to result.latitude,
            "longitude" to result.longitude,
            "accuracy"  to result.accuracy.toDouble(),
            "altitude"  to result.altitude,
            "speed"     to result.speed.toDouble(),
            "heading"   to result.bearing.toDouble(),
            "timestamp" to result.time,
            "address"   to result.address,
            "country"   to result.country,
            "province"  to result.province,
            "city"      to result.city,
            "district"  to result.district,
            "street"    to result.street,
            "streetNum" to result.streetNum,
            "cityCode"  to result.cityCode,
            "adCode"    to result.adCode,
            "poiName"   to result.poiName,
            "aoiName"   to result.aoiName,
        )
}
