import Flutter
import AMapFoundationKit

public class AutonaviMapsFlutterPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Privacy compliance — must be called before any AMap SDK initialisation.
        AMapServices.sharedServices()?.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapServices.sharedServices()?.updatePrivacyAgree(.didAgree)

        let factory = AMapFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "plugins.autonavi.flutter/amap_map")
    }
}
