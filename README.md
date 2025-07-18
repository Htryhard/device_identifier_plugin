# Device Identifier Plugin

[![pub package](https://img.shields.io/pub/v/device_identifier_plugin.svg)](https://pub.dev/packages/device_identifier_plugin)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-blue.svg)](https://pub.dev/packages/device_identifier_plugin)

> 📖 [中文文档请点这里 (README_zh.md)](README_zh.md)

A comprehensive Flutter plugin for obtaining various device identifiers, supporting both Android and iOS platforms.

---

## Features

### Android Supported Identifiers

- **Android ID**: Unique device identifier (recommended)
- **Advertising ID**: Google Advertising Identifier (GAID)
- **Install UUID**: Unique ID generated on app installation
- **Device Fingerprint**: Identifier generated based on hardware info
- **Build Serial**: Device serial number (requires permission)
- **File-based ID**: Persistent ID stored in external storage
- **Combined ID**: Hash of multiple identifiers

### iOS Supported Identifiers

- **iOS Device ID**: Concept similar to Android ID (recommended)
- **IDFV**: Identifier for Vendor, shared among the same developer's apps
- **IDFA**: Advertising Identifier (requires user authorization)
- **Keychain UUID**: Stable identifier stored in the keychain
- **Device Fingerprint**: Identifier generated based on hardware info
- **Launch UUID**: Temporary ID generated on each app launch
- **Combined ID**: Hash of multiple identifiers

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  device_identifier_plugin: ^0.0.8
```

Then run:

```sh
flutter pub get
```

---

## Platform Setup

### Android

#### Configure AndroidManifest.xml

Add the following permissions to your `android/app/src/main/AndroidManifest.xml` as needed:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
     <!-- Note, don't forget the line xmlns:tools='xxxxx' above -->
      <!-- Basic permissions -->
      <uses-permission android:name="android.permission.INTERNET" />
      <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

      <!-- For serial number (optional) -->
      <uses-permission android:name="android.permission.READ_PHONE_STATE" />

      <!-- If you need to obtain a Google Advertising ID (optional) -->
      <uses-permission android:name="com.google.android.gms.permission.AD_ID" />

      <!-- For file-based ID (optional) -->
      <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
      <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

      <!-- Android 11+ File access, if file storage device identifier is required (optional) -->
      <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
              tools:ignore="ScopedStorage" />


      <application>
        ...
      </application>

</manifest>
```

#### Configure app/build.gradle, minimum supported SDK 23

```gradle

 android {                                                                                     
   defaultConfig {                                                                             
     minSdkVersion 23                                                                          
   }                                                                                           
 } 

```

> Tip: If you need to obtain GAID, your device must support Google services

### iOS

Add the following to your `ios/Runner/Info.plist` for advertising tracking:

Privacy - Tracking Usage Description

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This app would like to access IDFA for analytics and personalized ads.</string>
```

Please check whether there is an AppTrackingTransparency.framework in this path:
`Xcode - Build Phases - Link Binary With Libraries add AppTrackingTransparency.framework`

The minimum supported version for iOS is 14. Please modify it in `Podfile`

```podfile

platform :ios, '14.0'

```

---

## Usage

Import the package:

```dart
import 'package:device_identifier_plugin/device_identifier_plugin.dart';
```

### Singleton Access

```dart
final deviceIdentifier = DeviceIdentifierPlugin.instance;
```

### Get the Best Device Identifier

```dart
String bestId = await deviceIdentifier.getBestDeviceIdentifier();
print('Best Device ID: $bestId');
```

### Check if Device is an Emulator

```dart
bool isEmulator = await deviceIdentifier.isEmulator();
print('Is Emulator: $isEmulator');
```

### Get Device Info

```dart
Map<String, String?> deviceInfo = await deviceIdentifier.getDeviceInfo();
print('Device Info: $deviceInfo');
```

### Get Supported Identifiers

```dart
Map<String, dynamic> identifiers = await deviceIdentifier.getSupportedIdentifiers();
print('Supported Identifiers: $identifiers');
```

### Get Platform Version

```dart
String? platformVersion = await deviceIdentifier.getPlatformVersion();
print('Platform Version: $platformVersion');
```

### Android-specific: File-based Device Identifier

```dart
// Request storage permission first
await deviceIdentifier.requestExternalStoragePermission();

bool hasPermission = await deviceIdentifier.hasExternalStoragePermission();
if (hasPermission) {
  // Get file-based device identifier
  String? fileId = await deviceIdentifier.getFileDeviceIdentifier();
  print('File Device ID: $fileId');

  // Generate a new file-based device identifier if needed
  String? generatedId = await deviceIdentifier.generateFileDeviceIdentifier();
  print('Generated File Device ID: $generatedId');

  // Check if file-based device identifier exists
  bool exists = await deviceIdentifier.hasFileDeviceIdentifier();
  print('File Device ID Exists: $exists');

  // Delete file-based device identifier
  bool deleted = await deviceIdentifier.deleteFileDeviceIdentifier();
  print('File Device ID Deleted: $deleted');
}
```

### Android-specific: Get Android ID and Advertising ID

```dart
if (Platform.isAndroid) {
  String? androidId = await deviceIdentifier.getAndroidId();
  print('Android ID: $androidId');

  String? advertisingId = await deviceIdentifier.getAdvertisingIdForAndroid();
  print('Advertising ID: $advertisingId');
}
```

### iOS-specific: Advertising ID and Tracking Authorization

```dart
if (Platform.isIOS) {
  // Request tracking authorization (iOS 14.5+)
  String? status = await deviceIdentifier.requestTrackingAuthorization();
  print('Tracking Authorization Status: $status');

  // Get IDFA (after authorization)
  String? idfa = await deviceIdentifier.getAdvertisingIdForiOS();
  print('IDFA: $idfa');
}
```

### iOS-specific: Keychain UUID

```dart
if (Platform.isIOS) {
  bool exists = await deviceIdentifier.hasKeychainUUID();
  String? uuid = await deviceIdentifier.getKeychainUUID();
  if (!exists) {
    uuid = await deviceIdentifier.generateKeychainUUID();
  }
  print('Keychain UUID: $uuid');
}
```

### iOS-specific: Get Apple IDFV

```dart
if (Platform.isIOS) {
  String? idfv = await deviceIdentifier.getAppleIDFV();
  print('Apple IDFV: $idfv');
}
```

### iOS-specific: Set Keychain Service and Account

```dart
if (Platform.isIOS) {
  await deviceIdentifier.setKeychainServiceAndAccount(
    service: 'com.example.myapp.keychain',
    keyAccount: 'my_device_uuid',
    deviceIDAccount: 'my_ios_device_id',
  );
  print('Custom keychain service and account set.');
}
```

---

## API Reference

| Method | Return Type | Description | Platform |
|--------|-------------|-------------|----------|
| `getPlatformVersion()` | `Future<String?>` | Get platform version | Android, iOS |
| `getBestDeviceIdentifier()` | `Future<String>` | Get the best device identifier for the current platform | Android, iOS |
| `isEmulator()` | `Future<bool>` | Check if the device is an emulator | Android, iOS |
| `getDeviceInfo()` | `Future<Map<String, String?>>` | Get detailed device info | Android, iOS |
| `getSupportedIdentifiers()` | `Future<Map<String, dynamic>>` | Get all supported identifiers | Android, iOS |
| `getAdvertisingIdForiOS()` | `Future<String?>` | Get IDFA (requires user authorization) | iOS |
| `requestTrackingAuthorization()` | `Future<String?>` | Request tracking authorization (iOS 14.5+) | iOS |
| `getAppleIDFV()` | `Future<String?>` | Get IDFV (Identifier for Vendor) | iOS |
| `getKeychainUUID()` | `Future<String?>` | Get Keychain UUID | iOS |
| `hasKeychainUUID()` | `Future<bool>` | Check if Keychain UUID exists | iOS |
| `generateKeychainUUID()` | `Future<String?>` | Generate and store a new Keychain UUID | iOS |
| `setKeychainServiceAndAccount({String service, String keyAccount, String deviceIDAccount})` | `Future<void>` | Set custom keychain service and account | iOS |
| `getAdvertisingIdForAndroid()` | `Future<String?>` | Get Google Advertising ID (GAID) | Android |
| `getAndroidId()` | `Future<String?>` | Get Android ID | Android |
| `getFileDeviceIdentifier({String? fileName, String? folderName})` | `Future<String?>` | Get file-based device identifier | Android |
| `generateFileDeviceIdentifier({String? fileName, String? folderName})` | `Future<String?>` | Generate and store a new file-based device identifier | Android |
| `deleteFileDeviceIdentifier({String? fileName, String? folderName})` | `Future<bool>` | Delete file-based device identifier | Android |
| `hasFileDeviceIdentifier({String? fileName, String? folderName})` | `Future<bool>` | Check if file-based device identifier exists | Android |
| `requestExternalStoragePermission()` | `Future<void>` | Request external storage permission | Android |
| `hasExternalStoragePermission()` | `Future<bool>` | Check if external storage permission is granted | Android |

---

## Privacy & Compliance

- **iOS**: Fully supports App Tracking Transparency (ATT) and requires user authorization for IDFA.
- **Android**: Handles runtime permissions for storage and complies with Google Play policies for advertising ID.
- **General**: Only collect device identifiers when necessary and inform users about the purpose.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## Contribution

Contributions are welcome! Please submit issues or pull requests via [GitHub](https://github.com/Htryhard/device_identifier_plugin).
