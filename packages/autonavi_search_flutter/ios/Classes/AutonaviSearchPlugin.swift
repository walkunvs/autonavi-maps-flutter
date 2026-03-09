import Flutter

public class AutonaviSearchPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "plugins.autonavi.flutter/search",
            binaryMessenger: registrar.messenger()
        )
        let handler = SearchChannelHandler()
        registrar.addMethodCallDelegate(handler, channel: channel)
    }
}
