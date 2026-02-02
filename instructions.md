# 📱 Flutter Barcode Scanner Setup Guide

Using `mobile_scanner: ^7.1.3`

---

## 🧩 1. Add Dependency

In your `pubspec.yaml` file:

```yaml
dependencies:
  mobile_scanner: ^7.1.3
```

Then run:

```bash
flutter pub get
```

---

## ⚙️ 2. Android Configuration

### (a) Add Camera Permission

Open: `android/app/src/main/AndroidManifest.xml`

Add this line **above** `<application>` tag:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### (b) Optional: Reduce App Size (Use Unbundled MLKit)

If you want to reduce APK size, open:
`android/gradle.properties`

Add:

```
dev.steenbakker.mobile_scanner.useUnbundled=true
```

This downloads the MLKit barcode scanner at runtime (saves ~5–8 MB).

---

## 🍎 3. iOS Configuration

Open: `ios/Runner/Info.plist`
Add these permission keys:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photos access to get QR code from photo library</string>
```

✅ Make sure in Xcode → **Signing & Capabilities** → “Camera” is enabled.

---

## 🧠 6. Usage Example (Simple)

Create a file: `barcode_scanner_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String? barcodeValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Scanner')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                setState(() {
                  barcodeValue = barcode.rawValue ?? 'Unknown';
                });
              }
            },
          ),
          if (barcodeValue != null)
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black54,
                child: Text(
                  barcodeValue!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 🧹 8. Lifecycle Handling (Optional Advanced)

If you want to handle camera pause/resume when app minimized, use `WidgetsBindingObserver`.

Example in documentation:
[https://pub.dev/packages/mobile_scanner](https://pub.dev/packages/mobile_scanner)

---

**Author:** Muhammad Fazlul Karim Rafi
**Package:** [mobile_scanner (steenbakker.dev)](https://pub.dev/packages/mobile_scanner)
