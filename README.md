# Device Identifier Plugin

[![pub package](https://img.shields.io/pub/v/device_identifier_plugin.svg)](https://pub.dev/packages/device_identifier_plugin)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-blue.svg)](https://pub.dev/packages/device_identifier_plugin)

一个全面的Flutter插件，提供多种获取设备唯一标识符的方法，同时支持Android和iOS平台。

## 功能特性

### Android 支持的标识符
- **Android ID**: 设备的唯一标识符（推荐）
- **广告ID**: Google广告标识符
- **安装UUID**: 应用安装时生成的唯一ID
- **设备指纹**: 基于硬件信息生成的标识符
- **序列号**: 设备序列号（需要权限）
- **文件存储ID**: 存储在外部存储中的持久化ID
- **组合ID**: 多种标识符的组合哈希

### iOS 支持的标识符
- **iOS设备ID**: 类似Android ID的概念（推荐）
- **IDFV**: 同一开发者应用共享的标识符
- **IDFA**: 广告标识符（需要用户授权）
- **Keychain UUID**: 存储在钥匙串中的稳定标识符
- **设备指纹**: 基于硬件信息生成的标识符
- **启动UUID**: 每次应用启动生成的临时ID
- **组合ID**: 多种标识符的组合哈希

## 安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  device_identifier_plugin: ^1.0.0
```

然后运行：

```bash
flutter pub get
```

## 平台配置

### Android 配置

在 `android/app/src/main/AndroidManifest.xml` 中添加必要的权限：

```xml
<!-- 基础权限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- 获取序列号需要的权限 (可选) -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" />

<!-- 外部存储权限 (可选，用于文件存储ID) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Android 11+ 管理外部存储权限 (可选) -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

### iOS 配置

在 `ios/Runner/Info.plist` 中添加广告追踪权限描述：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This app would like to access IDFA for analytics and personalized ads. This identifier is used to provide better app experience and relevant advertisements.</string>
```

## 使用方法

### 基础用法

```dart
import 'package:device_identifier_plugin/device_identifier_plugin.dart';

final _deviceIdentifierPlugin = DeviceIdentifierPlugin();

// 获取最优的设备标识符
String? bestId = await _deviceIdentifierPlugin.getBestDeviceIdentifier();
print('Best Device ID: $bestId');

// 获取完整的设备标识符信息
DeviceIdentifier deviceId = await _deviceIdentifierPlugin.getDeviceIdentifier();
print('Device Identifier: $deviceId');
```

### 高级用法

```dart
// 检查是否为模拟器
bool isEmulator = await _deviceIdentifierPlugin.isEmulator();

// 获取设备基本信息
Map<String, String> deviceInfo = await _deviceIdentifierPlugin.getDeviceInfo();

// 获取权限状态
Map<String, bool> permissions = await _deviceIdentifierPlugin.getPermissionStatus();

// 清除缓存的标识符
bool cleared = await _deviceIdentifierPlugin.clearCachedIdentifiers();
```

### Android 特有功能

```dart
// 获取基于文件的设备标识符
String? fileBasedId = await _deviceIdentifierPlugin.getFileBasedDeviceIdentifier();

// 删除文件存储的标识符
bool deleted = await _deviceIdentifierPlugin.deleteFileBasedDeviceIdentifier();

// 检查文件标识符是否存在
bool exists = await _deviceIdentifierPlugin.hasFileBasedDeviceIdentifier();

// 获取存储策略信息
Map<String, String> strategy = await _deviceIdentifierPlugin.getStorageStrategy();

// 获取文件存储详细信息
Map<String, dynamic> storageInfo = await _deviceIdentifierPlugin.getFileStorageInfo();
```

### iOS 特有功能

```dart
import 'dart:io';

// 请求广告追踪权限 (iOS 14.5+)
if (Platform.isIOS) {
  String? authStatus = await _deviceIdentifierPlugin.requestTrackingAuthorization();
  print('Tracking Authorization: $authStatus');
  // 可能的返回值: 'notDetermined', 'restricted', 'denied', 'authorized'
}
```

### 平台特定的标识符访问

```dart
DeviceIdentifier identifier = await _deviceIdentifierPlugin.getDeviceIdentifier();

if (Platform.isAndroid) {
  // Android 特有字段
  print('Android ID: ${identifier.androidId}');
  print('Advertising ID: ${identifier.advertisingId}');
  print('Install UUID: ${identifier.installUuid}');
  print('Build Serial: ${identifier.buildSerial}');
} else if (Platform.isIOS) {
  // iOS 特有字段
  print('iOS Device ID: ${identifier.iosDeviceID}');
  print('IDFV: ${identifier.idfv}');
  print('IDFA: ${identifier.idfa}');
  print('Keychain UUID: ${identifier.keychainUUID}');
  print('Launch UUID: ${identifier.launchUUID}');
}

// 通用字段
print('Device Fingerprint: ${identifier.deviceFingerprint}');
print('Combined ID: ${identifier.combinedId}');
print('Limit Ad Tracking: ${identifier.isLimitAdTrackingEnabled}');

// 使用便利方法获取最佳标识符
String? bestId = identifier.getBestIdentifier();
print('Best Identifier: $bestId');
```

## API 参考

### 主要方法

| 方法 | 返回类型 | 描述 | 平台支持 |
|------|----------|------|----------|
| `getPlatformVersion()` | `Future<String?>` | 获取平台版本信息 | Android, iOS |
| `getDeviceIdentifier()` | `Future<DeviceIdentifier>` | 获取完整设备标识符 | Android, iOS |
| `getBestDeviceIdentifier()` | `Future<String?>` | 获取最优设备标识符 | Android, iOS |
| `isEmulator()` | `Future<bool>` | 检查是否为模拟器 | Android, iOS |
| `getDeviceInfo()` | `Future<Map<String, String>>` | 获取设备基本信息 | Android, iOS |
| `clearCachedIdentifiers()` | `Future<bool>` | 清除缓存标识符 | Android, iOS |
| `getPermissionStatus()` | `Future<Map<String, bool>>` | 获取权限状态 | Android, iOS |

### Android 特有方法

| 方法 | 返回类型 | 描述 |
|------|----------|------|
| `getFileBasedDeviceIdentifier()` | `Future<String?>` | 获取文件存储标识符 |
| `deleteFileBasedDeviceIdentifier()` | `Future<bool>` | 删除文件存储标识符 |
| `hasFileBasedDeviceIdentifier()` | `Future<bool>` | 检查文件标识符是否存在 |
| `getStorageStrategy()` | `Future<Map<String, String>>` | 获取存储策略信息 |
| `getFileStorageInfo()` | `Future<Map<String, dynamic>>` | 获取文件存储详细信息 |

### iOS 特有方法

| 方法 | 返回类型 | 描述 |
|------|----------|------|
| `requestTrackingAuthorization()` | `Future<String?>` | 请求广告追踪权限 |

## 隐私和合规性

### iOS 合规性
- **App Tracking Transparency (ATT)**: 插件完全支持iOS 14.5+的ATT框架
- **用户授权**: 获取IDFA前会请求用户明确授权
- **隐私描述**: 必须在Info.plist中添加`NSUserTrackingUsageDescription`

### Android 合规性
- **权限管理**: 支持Android 6.0+的运行时权限
- **存储访问**: 兼容Android 11+的分区存储
- **广告ID**: 遵循Google Play政策关于广告ID的使用规范

### 通用建议
1. 仅在必要时收集设备标识符
2. 明确告知用户收集目的
3. 遵循当地隐私法规（如GDPR、CCPA等）
4. 定期更新隐私政策

## 示例应用

查看 `example/` 目录获取完整的示例应用，展示了所有功能的使用方法。

运行示例：

```bash
cd example
flutter run
```

## 故障排除

### 常见问题

1. **iOS IDFA 返回空值**
   - 检查是否添加了`NSUserTrackingUsageDescription`
   - 确认用户已授权追踪权限
   - 验证应用是否在真机上测试

2. **Android 文件存储失败**
   - 检查是否添加了存储权限
   - 在Android 11+上请求`MANAGE_EXTERNAL_STORAGE`权限
   - 验证外部存储是否可用

3. **权限被拒绝**
   - 引导用户到设置中手动开启权限
   - 提供明确的权限用途说明

### 调试技巧

启用详细日志输出：

```dart
// 在获取设备信息前添加错误处理
try {
  DeviceIdentifier identifier = await _deviceIdentifierPlugin.getDeviceIdentifier();
  print('Success: $identifier');
} catch (e) {
  print('Error: $e');
}
```

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交issue和pull request来改进这个插件。

## 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解版本更新信息。

