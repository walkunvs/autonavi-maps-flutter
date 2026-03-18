import Flutter
import AMapLocationKit

public class AutonaviLocationPlugin: NSObject, FlutterPlugin {

    private var methodChannel: FlutterMethodChannel?
    private var streamHandler: LocationStreamHandler?

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Privacy compliance
        AMapLocationManager.updatePrivacyShow(.didShow, privacyInfo: .contain)
        AMapLocationManager.updatePrivacyAgree(.did)

        let instance = AutonaviLocationPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "plugins.autonavi.flutter/location_method",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        instance.methodChannel = methodChannel

        let streamHandler = LocationStreamHandler()
        instance.streamHandler = streamHandler

        let eventChannel = FlutterEventChannel(
            name: "plugins.autonavi.flutter/location",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(streamHandler)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "location#getOnce":
            streamHandler?.getOnce(options: args) { locationResult in
                result(locationResult)
            }
        case "location#updateOptions":
            streamHandler?.updateOptions(args)
            result(nil)
        case "geofence#addCircle",
             "geofence#remove",
             "geofence#removeAll":
            // Geofence implementation placeholder
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
