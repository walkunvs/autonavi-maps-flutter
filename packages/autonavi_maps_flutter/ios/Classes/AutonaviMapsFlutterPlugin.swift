import Flutter
import AMapFoundationKit
import MAMapKit

public class AutonaviMapsFlutterPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Privacy compliance — must be called before any AMap SDK initialisation.
        MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        MAMapView.updatePrivacyAgree(.didAgree)

        let factory = AMapFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "plugins.autonavi.flutter/amap_map")
    }
}
