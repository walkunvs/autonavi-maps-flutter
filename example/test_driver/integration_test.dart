// Host-side integration test driver.
//
// Run with:
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/map_rendering_test.dart \
//     --device-id <device-id>
//
// The onScreenshot callback runs on the HOST, so screenshots are written
// directly to the host filesystem (not into the device/simulator sandbox).
//
// Android note: Android screenshots are captured on the device via PixelCopy
// (see MainActivity.kt) and saved to the app's external files directory.
// They are NOT routed through this callback.  CI retrieves them with `adb pull`
// after the test completes.  Only iOS screenshots go through onScreenshot.

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (
        String name,
        List<int> bytes, [
        Map<String, Object?>? args,
      ]) async {
        final dir = Directory('integration_test/screenshots');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        File('${dir.path}/$name.png').writeAsBytesSync(bytes);
        return true;
      },
    );
