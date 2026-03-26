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
// Android note: convertFlutterSurfaceToImage() only captures the Flutter
// software layer; AMap's OpenGL ES tiles render directly to the GPU
// framebuffer and appear black in those bytes. We therefore attempt an ADB
// screencap (which reads the GPU framebuffer) and only fall back to the
// Flutter-surface bytes when ADB is unavailable (e.g. on an iOS macOS runner).

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

        // Prefer an ADB screencap so that hardware-accelerated (OpenGL ES)
        // content is included.  Falls back to Flutter-surface bytes when adb
        // is not available or the emulator is not reachable (iOS runners, etc).
        List<int> screenshot = bytes;
        try {
          final result = await Process.run(
            'adb',
            ['-s', 'emulator-5554', 'exec-out', 'screencap', '-p'],
            stdoutEncoding: null, // binary output → Uint8List
          );
          if (result.exitCode == 0) {
            final dynamic raw = result.stdout;
            if (raw is List<int> && raw.length > 8) {
              screenshot = raw;
            }
          }
        } catch (_) {
          // adb not found or emulator unreachable — use Flutter bytes.
        }

        File('${dir.path}/$name.png').writeAsBytesSync(screenshot);
        return true;
      },
    );
