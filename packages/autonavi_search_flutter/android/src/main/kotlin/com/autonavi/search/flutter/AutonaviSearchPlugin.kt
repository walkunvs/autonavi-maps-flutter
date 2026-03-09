package com.autonavi.search.flutter

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class AutonaviSearchPlugin : FlutterPlugin {

    private lateinit var channel: MethodChannel
    private var channelHandler: SearchChannelHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channelHandler = SearchChannelHandler(binding.applicationContext)
        channel = MethodChannel(
            binding.binaryMessenger,
            "plugins.autonavi.flutter/search"
        )
        channel.setMethodCallHandler(channelHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        channelHandler = null
    }
}
