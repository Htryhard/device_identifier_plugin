# Device Identifier Plugin

[![pub package](https://img.shields.io/pub/v/device_identifier_plugin.svg)](https://pub.dev/packages/device_identifier_plugin)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-blue.svg)](https://pub.dev/packages/device_identifier_plugin)

一个支持 Android 和 iOS 平台的 Flutter 设备标识符插件，支持多种设备唯一标识符的获取。

---

## 功能特性

### Android 支持的标识符

- **Android ID**：唯一设备标识符（推荐）
- **Advertising ID**：Google 广告标识符（GAID）
- **Install UUID**：应用安装时生成的唯一 ID
- **Device Fingerprint**：基于硬件信息生成的标识符
- **Build Serial**：设备序列号（需要权限）
- **File-based ID**：存储于外部存储的持久化 ID
- **Combined ID**：多个标识符组合的哈希值

### iOS 支持的标识符

- **iOS Device ID**：类似 Android ID 的概念（推荐）
- **IDFV**：Vendor 标识符，同一开发者下的应用共享
- **IDFA**：广告标识符（需用户授权）
- **Keychain UUID**：存储于钥匙串的稳定标识符
- **Device Fingerprint**：基于硬件信息生成的标识符
- **Launch UUID**：每次启动生成的临时 ID
- **Combined ID**：多个标识符组合的哈希值

---

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  device_identifier_plugin: ^0.0.6
```

然后执行：

```sh
flutter pub get
```

---

## 平台配置

### Android

根据需要在 `android/app/src/main/AndroidManifest.xml` 添加如下权限：

```xml
<!-- 基础权限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- 获取序列号（可选） -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" />

<!-- 如果需要获取Google Advertising ID (可选)-->
<uses-permission android:name="com.google.android.gms.permission.AD_ID" />

<!-- 文件存储ID（可选） -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Android 11+ 文件访问，如果需要文件存储设备标识符（可选） -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
        tools:ignore="ScopedStorage" />
```

> 提示：如果需要获取GAID，还需要设备支持谷歌服务

### iOS

如需获取广告标识符，请在 `ios/Runner/Info.plist` 添加：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>本应用需要访问IDFA用于分析和个性化广告。</string>
```

请检查此路径下是否有AppTrackingTransparency.framework `Xcode - Build Phases - Link Binary With Libraries 新增 AppTrackingTransparency.framework`

---

## 使用方法

导入包：

```dart
import 'package:device_identifier_plugin/device_identifier_plugin.dart';
```

### 单例获取

```dart
final deviceIdentifier = DeviceIdentifierPlugin.instance;
```

### 获取最优设备标识符

```dart
String bestId = await deviceIdentifier.getBestDeviceIdentifier();
print('Best Device ID: $bestId');
```

### 判断是否为模拟器

```dart
bool isEmu = await deviceIdentifier.isEmulator();
print('Is Emulator: $isEmu');
```

### 获取设备信息

```dart
Map<String, String?> info = await deviceIdentifier.getDeviceInfo();
print('Device Info: $info');
```

### 获取所有支持的标识符

```dart
Map<String, dynamic> ids = await deviceIdentifier.getSupportedIdentifiers();
print('Supported Identifiers: $ids');
```

### Android 专用：文件存储设备标识符

```dart
// 先请求存储权限
await deviceIdentifier.requestExternalStoragePermission();

bool hasPermission = await deviceIdentifier.hasExternalStoragePermission();
if (hasPermission) {
  String? fileId = await deviceIdentifier.getFileDeviceIdentifier();
  print('File Device ID: $fileId');
}
```

### iOS 专用：广告标识符与追踪授权

```dart
if (Platform.isIOS) {
  // 请求追踪授权（iOS 14.5+）
  String? status = await deviceIdentifier.requestTrackingAuthorization();
  print('Tracking Authorization Status: $status');

  // 获取 IDFA（需授权后）
  String? idfa = await deviceIdentifier.getAdvertisingIdForiOS();
  print('IDFA: $idfa');
}
```

### iOS 专用：Keychain UUID

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

---

## API 参考

| 方法 | 返回类型 | 说明 | 平台 |
|------|----------|------|------|
| `getPlatformVersion()` | `Future<String?>` | 获取平台版本 | Android, iOS |
| `getBestDeviceIdentifier()` | `Future<String>` | 获取当前平台最优设备标识符 | Android, iOS |
| `isEmulator()` | `Future<bool>` | 判断是否为模拟器 | Android, iOS |
| `getDeviceInfo()` | `Future<Map<String, String?>>` | 获取详细设备信息 | Android, iOS |
| `getSupportedIdentifiers()` | `Future<Map<String, dynamic>>` | 获取所有支持的标识符 | Android, iOS |
| `getAdvertisingIdForiOS()` | `Future<String?>` | 获取 IDFA（需用户授权） | iOS |
| `requestTrackingAuthorization()` | `Future<String?>` | 请求追踪授权（iOS 14.5+） | iOS |
| `getAppleIDFV()` | `Future<String?>` | 获取 IDFV | iOS |
| `getKeychainUUID()` | `Future<String?>` | 获取 Keychain UUID | iOS |
| `hasKeychainUUID()` | `Future<bool>` | 判断 Keychain UUID 是否存在 | iOS |
| `generateKeychainUUID()` | `Future<String?>` | 生成并存储新的 Keychain UUID | iOS |
| `getAdvertisingIdForAndroid()` | `Future<String?>` | 获取 Google 广告ID | Android |
| `getAndroidId()` | `Future<String?>` | 获取 Android ID | Android |
| `getFileDeviceIdentifier()` | `Future<String?>` | 获取文件存储设备标识符 | Android |
| `generateFileDeviceIdentifier()` | `Future<String?>` | 生成并存储新的文件设备标识符 | Android |
| `deleteFileDeviceIdentifier()` | `Future<bool>` | 删除文件设备标识符 | Android |
| `hasFileDeviceIdentifier()` | `Future<bool>` | 判断文件设备标识符是否存在 | Android |
| `requestExternalStoragePermission()` | `Future<void>` | 请求外部存储权限 | Android |
| `hasExternalStoragePermission()` | `Future<bool>` | 判断外部存储权限是否已授权 | Android |

---

## 隐私与合规

- **iOS**：完全支持 App Tracking Transparency（ATT），获取 IDFA 需用户授权。
- **Android**：处理存储权限申请，遵循 Google Play 广告 ID 合规要求。
- **通用**：仅在必要时收集设备标识符，并告知用户用途。

---

## License

MIT License. 详见 [LICENSE](LICENSE)。

---

## Changelog

版本历史见 [CHANGELOG.md](CHANGELOG.md)。

---

## 贡献

欢迎贡献代码！请通过 [GitHub](https://github.com/Htryhard/device_identifier_plugin) 提交 issue 或 pull request。
