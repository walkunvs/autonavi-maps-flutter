# autonavi-maps-flutter

A Flutter plugin ecosystem for AutoNavi (高德地图) Maps, providing a complete suite of mapping, location, and search capabilities for Android and iOS.

## Packages

| Package | Version | Description |
|---------|---------|-------------|
| [`autonavi_maps_flutter`](packages/autonavi_maps_flutter) | 0.1.0 | Map rendering, camera control, overlays |
| [`autonavi_location_flutter`](packages/autonavi_location_flutter) | 0.1.0 | Location stream, geofencing |
| [`autonavi_search_flutter`](packages/autonavi_search_flutter) | 0.1.0 | POI search, geocoding, route planning |

## Roadmap

| Package | Status |
|---------|--------|
| autonavi_maps_flutter | ✅ Available |
| autonavi_location_flutter | ✅ Available |
| autonavi_search_flutter | ✅ Available |
| autonavi_navi_flutter | 🔄 Planned — requires separate AutoNavi Nav SDK license |

## Getting Started

### 1. Add dependencies

```yaml
dependencies:
  # Map rendering
  autonavi_maps_flutter: ^0.1.0

  # Location services (optional)
  autonavi_location_flutter: ^0.1.0

  # Search services (optional)
  autonavi_search_flutter: ^0.1.0
```

### 2. Configure API Key

Register at [AutoNavi Developer Console](https://console.amap.com/dev/key/app) to obtain your API key.

**Android** — `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <meta-data
        android:name="com.amap.api.v2.apikey"
        android:value="${AMAP_API_KEY}"/>
</application>

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS** — `ios/Runner/AppDelegate.swift`:
```swift
import AMapFoundationKit

@main
class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AMapServices.shared().apiKey = "YOUR_API_KEY"
        return super.application(application, didFinishLaunchingWithOptions: options)
    }
}
```

### 3. Usage

```dart
import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';
import 'package:autonavi_location_flutter/autonavi_location_flutter.dart';
import 'package:autonavi_search_flutter/autonavi_search_flutter.dart';

// Display map
AutonaviWidget(
  initialCameraPosition: CameraPosition(
    target: LatLng(39.909187, 116.397451),
    zoom: 12,
  ),
  onMapCreated: (controller) async {
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(31.224, 121.469), 14),
    );
  },
  markers: {
    Marker(
      markerId: const MarkerId('hq'),
      position: const LatLng(39.909187, 116.397451),
      infoWindow: const InfoWindow(title: '天安门'),
    ),
  },
);

// Continuous location
AutonaviLocation.onLocationChanged.listen((result) {
  print('${result.city} ${result.address}');
});

// POI search
final pois = await AutonaviSearch.searchKeyword(
  keyword: '咖啡',
  city: '上海',
);

// Route planning
final route = await AutonaviSearch.drivingRoute(
  origin: LatLng(31.224, 121.469),
  destination: LatLng(31.197, 121.481),
);
```

## Development

This repository uses [Melos](https://melos.invertase.dev) to manage the monorepo.

```bash
# Install Melos (declared in root pubspec.yaml)
dart pub get

# Bootstrap all packages
dart run melos bootstrap

# Run analysis
dart run melos run analyze

# Run tests
dart run melos run test

# Format code
dart run melos run format
```

## Important Notes

### Privacy Compliance

All packages require privacy consent initialization before use:

**Android:**
```kotlin
AMapLocationClient.updatePrivacyShow(context, true, true)
AMapLocationClient.updatePrivacyAgree(context, true)
```

**iOS:**
```swift
AMapLocationClient.updatePrivacyAgree(.did)
AMapLocationClient.updatePrivacyShow(.didShow, privacyInfo: .contain)
```

### Coordinate System

AutoNavi uses GCJ-02 (Mars Coordinates). GPS coordinates have ~300-500m offset and must be converted:

```dart
final gcj02 = await AutonaviMaps.convertFromWGS84(wgs84LatLng);
```

### API Key Security

Use `--dart-define` to inject the API key without hardcoding:

```bash
flutter run --dart-define=AMAP_API_KEY=your_key_here
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE).
