# 分区存储功能完善指南

## 概述

本指南详细介绍了为 `device_identifier_plugin` 项目完善的分区存储功能，确保在不同 Android 版本上都能正常存储和读取设备标识符。

## 功能特点

### 1. 多策略存储支持

- **应用特定存储** (APP_SPECIFIC_STORAGE): Android 10+ 推荐，无需权限
- **分区存储** (SCOPED_STORAGE): Android 10+ 需要 MANAGE_EXTERNAL_STORAGE 权限
- **传统外部存储** (LEGACY_EXTERNAL_STORAGE): Android 9 及以下版本
- **MediaStore API** (MEDIA_STORE): Android 10+ 通过 MediaStore 访问
- **文档提供器** (DOCUMENT_PROVIDER): 需要用户交互的备选方案

### 2. 自动降级机制

系统会自动选择最适合当前 Android 版本的存储策略，并在失败时自动降级到其他策略。

### 3. 权限管理

提供完整的权限检查和请求功能，适配不同 Android 版本的权限要求。

## 文件结构

```
device_identifier_plugin/
├── android/src/main/kotlin/com/hicyh/device_identifier_plugin/
│   ├── DeviceIdentifierManager.kt (增强版)
│   └── ScopedStorageManager.kt (新增)
├── example/
│   ├── android/
│   │   └── app/
│   │       ├── src/main/
│   │       │   ├── AndroidManifest.xml (更新权限配置)
│   │       │   ├── res/xml/file_paths.xml (文件提供器配置)
│   │       │   └── kotlin/com/hicyh/device_identifier_plugin_example/
│   │       │       ├── MainActivity.kt (集成权限管理)
│   │       │       └── StoragePermissionHelper.kt (权限辅助类)
│   │       └── build.gradle (更新SDK版本)
│   └── lib/
│       ├── main.dart (添加分区存储测试入口)
│       ├── scoped_storage_test_page.dart (分区存储测试页面)
│       └── storage_permission_helper.dart (Flutter权限辅助类)
└── SCOPED_STORAGE_GUIDE.md (本文档)
```

## 核心组件

### 1. ScopedStorageManager

新增的分区存储管理器，提供以下功能：

- 多策略存储支持
- 自动策略选择和降级
- 设备标识符的创建、读取和删除
- 存储策略信息查询

### 2. StoragePermissionHelper (Android)

Kotlin 权限辅助类，提供：

- 权限状态检查
- 权限请求处理
- 不同 Android 版本的适配
- 权限描述和状态转换

### 3. StoragePermissionHelper (Flutter)

Flutter 权限辅助类，提供：

- 与 Android 权限系统的桥接
- 权限状态查询
- 权限请求接口
- 应用设置页面跳转

## 使用说明

### 1. 权限配置

在 `AndroidManifest.xml` 中已配置以下权限：

```xml
<!-- 存储权限 - 适配不同Android版本 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

<!-- Android 13+ 新权限模式 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

### 2. 使用方法

#### 获取设备标识符

```kotlin
val deviceIdentifierManager = DeviceIdentifierManager.getInstance(context)
val deviceId = deviceIdentifierManager.getFileBasedDeviceIdentifier()
```

#### 检查权限状态

```kotlin
val permissionHelper = StoragePermissionHelper(activity)
val permissions = permissionHelper.checkStoragePermissions()
```

#### 请求权限

```kotlin
permissionHelper.requestStoragePermissions()
```

### 3. Flutter 集成

在 Flutter 中使用：

```dart
// 检查权限
final permissions = await StoragePermissionHelper.checkStoragePermissions();

// 请求权限
final result = await StoragePermissionHelper.requestStoragePermissions();

// 获取设备标识符
final deviceId = await DeviceIdentifierPlugin().getFileBasedDeviceIdentifier();
```

## 不同 Android 版本的适配

### Android 6.0 - 9.0 (API 23-28)

- 使用传统外部存储
- 需要 `WRITE_EXTERNAL_STORAGE` 和 `READ_EXTERNAL_STORAGE` 权限
- 运行时权限请求

### Android 10 (API 29)

- 分区存储过渡期
- 优先使用应用特定存储
- 支持 `requestLegacyExternalStorage` 配置

### Android 11+ (API 30+)

- 完全分区存储
- 需要 `MANAGE_EXTERNAL_STORAGE` 权限访问外部存储根目录
- 优先使用应用特定存储

### Android 13+ (API 33+)

- 新的媒体权限模式
- 支持 `READ_MEDIA_*` 权限
- 更严格的权限管理

## 测试功能

### 分区存储测试页面

example 项目提供了专门的测试页面，可以：

1. 查看当前权限状态
2. 请求相应权限
3. 测试不同存储策略
4. 查看存储信息
5. 清除存储数据

### 使用方法

1. 运行 example 项目
2. 点击 "分区存储测试" 按钮
3. 使用各种功能进行测试

## 故障排除

### 权限被拒绝

1. 检查 `AndroidManifest.xml` 中的权限配置
2. 确保目标 SDK 版本正确
3. 对于 Android 11+，需要用户手动授予 `MANAGE_EXTERNAL_STORAGE` 权限

### 存储失败

1. 检查外部存储是否可用
2. 确认权限已正确授予
3. 查看日志中的错误信息
4. 尝试不同的存储策略

### 兼容性问题

1. 确保 `compileSdkVersion` 和 `targetSdkVersion` 配置正确
2. 检查设备的 Android 版本
3. 查看设备制造商的定制限制

## 性能优化

### 缓存策略

- 设备标识符首次生成后会缓存
- 支持多重备份机制
- 自动清理无效缓存

### 权限检查

- 权限状态缓存避免重复检查
- 异步权限请求不阻塞主线程
- 智能权限降级策略

## 安全考虑

### 隐私保护

- 设备标识符仅在本地生成和存储
- 不收集或传输任何个人信息
- 支持用户主动删除标识符

### 权限最小化

- 仅请求必要的权限
- 优先使用无需权限的应用特定存储
- 清晰的权限用途说明

## 未来扩展

### 计划功能

1. 云端同步支持
2. 加密存储选项
3. 更多存储策略
4. 自定义存储位置

### 维护建议

1. 定期更新 Android 版本适配
2. 监控权限政策变化
3. 收集用户反馈
4. 性能优化和安全增强

## 总结

通过本次完善，`device_identifier_plugin` 现在完全支持 Android 分区存储，能够在各个 Android 版本上稳定运行。主要改进包括：

1. ✅ 完整的分区存储适配
2. ✅ 多策略存储支持
3. ✅ 自动降级机制
4. ✅ 权限管理系统
5. ✅ 测试和调试工具
6. ✅ 详细的文档和指南

现在你可以在不同 Android 版本上安全地存储和读取设备标识符，无需担心兼容性问题。 