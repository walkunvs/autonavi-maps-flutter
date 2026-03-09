import Flutter
import AMapFoundationKit
import AMapLocationKit

public class AutonaviMapsFlutterPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Privacy compliance — must be called before any AMap SDK initialization
        AMapLocationClient.updatePrivacyShow(.didShow, privacyInfo: .contain)
        AMapLocationClient.updatePrivacyAgree(.did)

        let factory = AMapFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "plugins.autonavi.flutter/amap_map")
    }
}
