import Flutter
import UIKit
import AMapFoundationKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set your AutoNavi API key here or via --dart-define=AMAP_API_KEY=...
        // For security, inject via build-time configuration rather than hardcoding.
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "AMapAPIKey") as? String
            ?? "YOUR_AMAP_API_KEY_HERE"
        AMapServices.shared().apiKey = apiKey

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
