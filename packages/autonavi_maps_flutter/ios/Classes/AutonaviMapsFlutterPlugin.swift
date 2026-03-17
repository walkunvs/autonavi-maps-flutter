import Flutter
import AMapFoundationKit

public class AutonaviMapsFlutterPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = AMapFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "plugins.autonavi.flutter/amap_map")
    }
}
