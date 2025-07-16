# 权限配置指南

## 🔧 重要说明

**device_identifier_plugin 插件本身不声明任何权限**，这是 Flutter 插件开发的最佳实践。所有权限都需要由使用插件的应用根据实际需求在自己的 `AndroidManifest.xml` 中声明。

## 📱 Flutter应用集成权限配置

使用 `device_identifier_plugin` 插件的Flutter应用需要在 `android/app/src/main/AndroidManifest.xml` 中添加以下权限：

### 🟢 基础权限 (推荐)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- 基础网络权限 - 获取广告ID需要 -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Google Advertising ID 权限 (Android 13+) -->
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" />

    <application
        android:label="your_app_name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- 您的Activity配置 -->
        
    </application>

</manifest>
```

### 🟡 可选权限 (按需添加)

```xml
<!-- 设备序列号权限 (仅在需要时添加) -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" />

<!-- 外部存储权限 (仅在使用文件存储功能时添加) -->
<!-- Android 6.0 - Android 10 (API 23-29) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Android 11+ (API 30+) 如果需要访问外部存储根目录 -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" 
    tools:ignore="ScopedStorage" />
```

## 📊 权限功能对应表

| 权限 | 对应功能 | 必需性 | 运行时申请 | 说明 |
|------|----------|--------|------------|------|
| `INTERNET` | 获取广告ID | **必需** | 否 | 插件核心功能 |
| `ACCESS_NETWORK_STATE` | 网络状态检查 | **推荐** | 否 | 提高稳定性 |
| `AD_ID` | 广告ID访问 | **推荐** | 否 | Android 13+ |
| `READ_PHONE_STATE` | 获取设备序列号 | 可选 | 是 | Android 10+ 基本不可用 |
| `WRITE_EXTERNAL_STORAGE` | 文件存储标识符 | 可选 | 是 | 文件存储功能 |
| `READ_EXTERNAL_STORAGE` | 读取文件标识符 | 可选 | 是 | 文件存储功能 |
| `MANAGE_EXTERNAL_STORAGE` | Android 11+外部存储 | 可选 | 特殊权限 | 需要用户手动授权 |

## 🎯 权限配置策略

### 最小权限配置 (推荐)
```xml
<!-- 只添加基础权限，满足大部分使用场景 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="com.google.android.gms.permission.AD_ID" />
```

**可获得的标识符：**
- ✅ Android ID
- ✅ 广告ID (需要网络)
- ✅ 安装UUID
- ✅ 设备指纹
- ✅ 组合ID
- ❌ 设备序列号
- ❌ 文件存储ID

### 完整功能配置
```xml
<!-- 添加所有权限，获得完整功能 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="com.google.android.gms.permission.AD_ID" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage" />
```

**可获得的标识符：**
- ✅ 所有类型的设备标识符

## 🔒 隐私和合规考虑

### 权限申请最佳实践

1. **按需申请**: 只添加应用实际使用功能所需的权限
2. **用户说明**: 在隐私政策中说明权限用途
3. **优雅降级**: 插件会自动处理权限缺失的情况

### 代码示例 - 权限检查

```dart
// 检查当前权限状态
final permissions = await DeviceIdentifierPlugin().getPermissionStatus();

if (permissions['READ_PHONE_STATE'] == true) {
  // 可以获取设备序列号
  print('可以获取设备序列号');
} else {
  // 使用其他标识符
  print('使用其他设备标识符');
}

if (permissions['WRITE_EXTERNAL_STORAGE'] == true) {
  // 可以使用文件存储功能
  final fileId = await plugin.getFileBasedDeviceIdentifier();
} else {
  // 使用内存存储的标识符
  final bestId = await plugin.getBestDeviceIdentifier();
}
```

## 📱 iOS权限配置

iOS 平台目前不支持，无需配置权限。

## ⚠️ 常见问题

**Q: 为什么插件本身不声明权限？**
A: 这是 Flutter 插件开发的最佳实践：
- 避免强制所有使用者申请不需要的权限
- 让应用开发者根据实际需求配置权限
- 符合应用商店的最小权限原则

**Q: 不添加某些权限会影响插件功能吗？**
A: 不会导致崩溃，插件会优雅降级：
- 无网络权限：无法获取广告ID，使用其他标识符
- 无存储权限：无法使用文件存储功能，使用内存标识符
- 无电话权限：无法获取设备序列号，使用其他标识符

**Q: Android 11+ 的 MANAGE_EXTERNAL_STORAGE 权限很难获得？**
A: 确实如此，建议：
- 优先使用不需要此权限的标识符 (Android ID、设备指纹等)
- 只在确实需要跨应用持久化时才申请此权限
- 提供明确的用户说明

**Q: 权限被拒绝后如何处理？**
A: 插件已内置优雅降级机制：
- 会自动选择可用的最佳标识符
- 提供权限状态检查 API
- 不会因权限问题崩溃

## 🎉 示例项目

可以参考插件的示例项目 (`example/android/app/src/main/AndroidManifest.xml`) 查看完整的权限配置示例。 