import 'dart:io';

import 'device_identifier_plugin_platform_interface.dart';

/// DeviceIdentifierPlugin - 设备标识符插件
///
/// 提供多种获取设备唯一标识符的方法，支持Android和iOS平台
/// Android：包含Android ID、广告ID、安装UUID、设备指纹、序列号等多种标识符
/// iOS：包含iOS设备ID、IDFV、IDFA、Keychain UUID、设备指纹等多种标识符
class DeviceIdentifierPlugin {
  late String _androidFileName = 'device_id.txt';
  late String _androidFolderName = 'DeviceIdentifier';

  // 单例获取
  static final DeviceIdentifierPlugin _instance =
      DeviceIdentifierPlugin._internal();

  factory DeviceIdentifierPlugin() {
    return _instance;
  }

  DeviceIdentifierPlugin._internal();

  static DeviceIdentifierPlugin get instance => _instance;

  /// 设置Android文件存储的文件名和文件夹名称
  /// [androidFileName] 文件名，默认为 'device_id.txt'
  /// [androidFolderName] 文件夹名称，默认为 'DeviceIdentifier'
  void setAndroidFileStorage({
    String androidFileName = 'device_id.txt',
    String androidFolderName = 'DeviceIdentifier',
  }) {
    _androidFileName = androidFileName;
    _androidFolderName = androidFolderName;
  }

  // DeviceIdentifierPlugin({
  //   String androidFileName = 'device_id.txt',
  //   String androidFolderName = 'DeviceIdentifier',
  // }) : _androidFileName = androidFileName,
  //      _androidFolderName = androidFolderName;

  /// 获取平台版本信息
  Future<String?> getPlatformVersion() {
    return DeviceIdentifierPluginPlatform.instance.getPlatformVersion();
  }

  /// 获取最优的设备标识符
  /// 必定返回一个最适合当前平台的设备标识符
  Future<String> getBestDeviceIdentifier() async {
    if (Platform.isAndroid) {
      // 1、优先获取Android ID
      final androidId =
          await DeviceIdentifierPluginPlatform.instance.getAndroidId();
      if (androidId != null && androidId.isNotEmpty) {
        return androidId;
      }
      // 2、如果Android ID不可用，尝试判断是否有外部设备读取权限
      final hasPermission =
          await DeviceIdentifierPluginPlatform.instance
              .hasExternalStoragePermission();
      if (hasPermission) {
        // 如果有权限，尝试获取基于文件的设备标识符
        final fileDeviceId =
            await DeviceIdentifierPluginPlatform.instance
                .getFileDeviceIdentifier();
        if (fileDeviceId != null && fileDeviceId.isNotEmpty) {
          return fileDeviceId;
        } else {
          // 生成新的基于文件的设备标识符
          final generatedId =
              await DeviceIdentifierPluginPlatform.instance
                  .generateFileDeviceIdentifier();
          if (generatedId != null && generatedId.isNotEmpty) {
            return generatedId;
          }
        }
      }
      // 3、如果没有外部存储权限或获取失败，尝试获取广告ID
      final advertisingId =
          await DeviceIdentifierPluginPlatform.instance
              .getAdvertisingIdForAndroid();
      if (advertisingId != null && advertisingId.isNotEmpty) {
        return advertisingId;
      }
      // TODO 最后尝试获取其他Android标识符
      return "";
    } else if (Platform.isIOS) {
      // 1、优先获取钥匙串UUID
      final hasKeychainUUID =
          await DeviceIdentifierPluginPlatform.instance.hasKeychainUUID();
      if (hasKeychainUUID) {
        final keychainUUID =
            await DeviceIdentifierPluginPlatform.instance.getKeychainUUID();
        return keychainUUID!;
      } else {
        // 如果钥匙串UUID不可用，尝试生成新的
        final generatedUUID =
            await DeviceIdentifierPluginPlatform.instance
                .generateKeychainUUID();
        if (generatedUUID != null && generatedUUID.isNotEmpty) {
          return generatedUUID;
        }
      }
      // 2、获取广告标识符
      final idfa =
          await DeviceIdentifierPluginPlatform.instance
              .getAdvertisingIdForiOS();
      if (idfa != null && idfa.isNotEmpty) {
        return idfa;
      }
      // TODO 最后尝试获取其他iOS标识符
      return "";
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// 检查当前设备是否为模拟器
  ///
  /// 通过检查设备的硬件特征来判断是否为模拟器环境
  ///
  /// Android：包括指纹信息、型号名称、制造商等
  /// iOS：通过编译条件判断是否为Simulator
  ///
  /// 返回true表示是模拟器，false表示是真实设备
  Future<bool> isEmulator() {
    return DeviceIdentifierPluginPlatform.instance.isEmulator();
  }

  /// 获取设备基本信息
  ///
  /// 返回设备的详细硬件和系统信息
  ///
  /// Android返回如下：
  /// - brand: 设备品牌（如 Xiaomi、HUAWEI、Samsung）
  /// - model: 设备型号（如 MI 10、SM-G9730）
  /// - manufacturer: 设备制造商（如 Xiaomi、HUAWEI、Samsung）
  /// - device: 设备名称（设备内部代号，如 "cepheus"）
  /// - product: 产品名称（如 "cepheus"）
  /// - board: 主板名称（如 "msm8998"）
  /// - hardware: 硬件名称（如 "qcom"）
  /// - android_version: 系统版本号（如 "13"）
  /// - sdk_int: 系统SDK版本号（如 "33"）
  /// - fingerprint: 设备指纹（唯一标识一台设备的字符串）
  /// - is_emulator: 是否为模拟器（true/false）
  ///
  /// iOS返回如下：
  /// - model: 设备型号标识符（如 "iPhone14,2"）
  /// - name: 设备名称（如 "张三的iPhone"）
  /// - systemName: 操作系统名称（如 "iOS"）
  /// - systemVersion: 操作系统版本号（如 "17.0.2"）
  /// - localizedModel: 本地化设备型号（如 "iPhone"）
  /// - isSimulator: 是否为模拟器（"true"/"false"）
  /// - screenSize: 屏幕分辨率（如 "390x844"）
  /// - screenScale: 屏幕缩放因子（如 "3.0"）
  /// - timeZone: 当前时区标识符（如 "Asia/Shanghai"）
  /// - language: 当前系统语言（如 "zh"、"en"）
  Future<Map<String, String?>> getDeviceInfo() {
    return DeviceIdentifierPluginPlatform.instance.getDeviceInfo();
  }

  /// 获取设备支持的标识符
  /// Android和iOS通用接口
  /// Android会返回：
  /// - androidId: Android ID（工厂重置、刷机、切换用户时会变化，卸载重装不变）
  /// - advertisingId: 广告ID（用户可手动重置，约每月自动重置一次，卸载重装不变）
  /// - installUuid: 安装UUID（每次安装都会生成新的，卸载重装必然变化）
  /// - deviceFingerprint: 设备指纹（基于硬件信息，相对稳定，系统更新或硬件变化时可能变化）
  /// - buildSerial: 设备序列号（硬件级别标识符，除非更换设备否则不变）
  /// - combinedId: 组合ID（多个标识符的组合哈希，变化取决于组成部分）
  /// - isLimitAdTrackingEnabled: 是否限制广告追踪（用户设置，影响广告ID的使用）
  ///
  /// iOS会返回：
  /// - iosDeviceID: iOS设备ID（类似Android ID的概念，最推荐用于统计）
  /// - idfv: IDFV（同一开发者应用共享，卸载重装时可能变化）
  /// - idfa: IDFA（广告标识符，iOS 14.5+ 需要用户授权，卸载重装不变）
  /// - keychainUUID: Keychain UUID（存储在钥匙串中，最稳定的标识符）
  /// - deviceFingerprint: 设备指纹（基于硬件信息生成的相对稳定标识符）
  /// - launchUUID: 应用启动UUID（每次应用启动生成，测试用）
  /// - combinedId: 组合ID（多个标识符的组合哈希）
  /// - isLimitAdTrackingEnabled: 是否限制广告追踪（ATT授权状态）
  Future<Map<String, dynamic>> getSupportedIdentifiers() {
    return DeviceIdentifierPluginPlatform.instance.getSupportedIdentifiers();
  }

  /// iOS获取广告标识符
  /// iOS接口
  /// 返回的是IDFA - Identifier for Advertisers，此ID需要用户授权
  /// 需要调用[requestTrackingAuthorization]方法请求用户授权后才能获取
  Future<String?> getAdvertisingIdForiOS() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.getAdvertisingIdForiOS();
    } else {
      throw UnsupportedError('This method is only supported on iOS platforms');
    }
  }

  /// iOS 特有方法：请求广告追踪权限
  ///
  /// 在iOS 14.5+版本中，需要用户明确授权才能获取IDFA
  ///
  /// 返回授权状态：
  /// - 'notDetermined': 用户尚未做出选择
  /// - 'restricted': 受限制（例如家长控制）
  /// - 'denied': 用户拒绝授权
  /// - 'authorized': 用户已授权
  ///
  /// 此方法会弹出系统权限对话框，请求用户授权
  /// 拥有此权限才可调用[getAdvertisingIdForiOS]方法获取IDFA
  Future<String?> requestTrackingAuthorization() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance
          .requestTrackingAuthorization();
    } else {
      throw UnsupportedError('This method is only supported on iOS platforms');
    }
  }

  /// 获取idfv
  /// iOS专属接口
  /// 返回IDFV（Identifier for Vendor），同一开发者应用共享
  Future<String?> getAppleIDFV() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.getAppleIDFV();
    } else {
      throw UnsupportedError('This method is only supported on iOS platforms');
    }
  }

  /// 获取钥匙串UUID
  /// iOS专属接口
  /// 返回存储在钥匙串中的UUID
  /// 如果未存储则返回null或空字符
  Future<String?> getKeychainUUID() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.getKeychainUUID();
    } else {
      throw UnsupportedError('This method is only supported on iOS platforms');
    }
  }

  /// 检查是否存在钥匙串UUID
  /// iOS专属接口
  /// 返回true表示存在钥匙串UUID，false表示不存在
  Future<bool> hasKeychainUUID() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.hasKeychainUUID();
    } else {
      throw UnsupportedError('This method is only supported on iOS platforms');
    }
  }

  /// 生成钥匙串UUID
  /// iOS专属接口
  /// 如果已存在则返回现有UUID，否则生成新的UUID并存储后返回
  Future<String?> generateKeychainUUID() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.generateKeychainUUID();
    } else {
      throw UnsupportedError('This method is only supported on iOS platforms');
    }
  }

  /// 获取广告标识符
  /// Android接口
  /// Android返回的是GAID - Google Advertising ID，此ID需要设备支持谷歌服务
  Future<String?> getAdvertisingIdForAndroid() {
    if (Platform.isAndroid) {
      return DeviceIdentifierPluginPlatform.instance
          .getAdvertisingIdForAndroid();
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms',
      );
    }
  }

  /// 获取Android ID
  /// Android专属接口
  Future<String?> getAndroidId() {
    if (Platform.isAndroid) {
      return DeviceIdentifierPluginPlatform.instance.getAndroidId();
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms',
      );
    }
  }

  /// 获取基于文件的设备标识符
  ///
  /// 在外部存储中创建文件来保存设备唯一标识符，卸载重装后保持不变
  ///
  /// 需要相应的存储权限：
  /// - Android 6.0-10：WRITE_EXTERNAL_STORAGE
  /// - Android 11+：MANAGE_EXTERNAL_STORAGE
  /// - iOS：不支持此功能
  ///
  /// 调用此函数之前需要先请求外部存储权限[requestExternalStoragePermission]
  /// 并取得权限[hasExternalStoragePermission]之后调用
  ///
  /// [fileName] 文件名，默认为 'device_id.txt'
  /// [folderName] 文件夹名称，默认为 'DeviceIdentifier'
  ///
  /// 返回设备标识符字符串，如果权限不足或创建失败则返回null
  Future<String?> getFileDeviceIdentifier({
    String? fileName,
    String? folderName,
  }) {
    if (Platform.isAndroid) {
      fileName ??= _androidFileName;
      folderName ??= _androidFolderName;
      return DeviceIdentifierPluginPlatform.instance.getFileDeviceIdentifier(
        fileName: fileName,
        folderName: folderName,
      );
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms',
      );
    }
  }

  /// 生成并返回基于文件的设备标识符
  ///
  /// 在外部存储中创建文件来保存设备唯一标识符，卸载重装后保持不变
  ///
  /// 需要相应的存储权限：
  /// - Android 6.0-10：WRITE_EXTERNAL_STORAGE
  /// - Android 11+：MANAGE_EXTERNAL_STORAGE
  /// - iOS：不支持此功能
  ///
  /// 调用此函数之前需要先请求外部存储权限[requestExternalStoragePermission]
  /// 并取得权限[hasExternalStoragePermission]之后调用
  ///
  /// [fileName] 文件名，默认为 'device_id.txt'
  /// [folderName] 文件夹名称，默认为 'DeviceIdentifier'
  ///
  /// 返回设备标识符字符串，如果权限不足或创建失败则返回null,与[getFileDeviceIdentifier]方法不同的是
  /// 此方法会在找不到标识符的时候生成新的标识符并返回，而[getFileDeviceIdentifier]方法不会生成新的标识符
  Future<String?> generateFileDeviceIdentifier({
    String? fileName,
    String? folderName,
  }) {
    if (Platform.isAndroid) {
      fileName ??= _androidFileName;
      folderName ??= _androidFolderName;
      return DeviceIdentifierPluginPlatform.instance
          .generateFileDeviceIdentifier(
            fileName: fileName,
            folderName: folderName,
          );
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms',
      );
    }
  }

  /// 删除基于文件的设备标识符
  ///
  /// 删除外部存储中保存的设备标识符文件
  /// Android专属接口
  /// [fileName] 文件名，默认为 'device_id.txt'
  /// [folderName] 文件夹名称，默认为 'DeviceIdentifier'
  ///
  /// 返回是否删除成功
  Future<bool> deleteFileDeviceIdentifier({
    String? fileName,
    String? folderName,
  }) {
    if (Platform.isAndroid) {
      fileName ??= _androidFileName;
      folderName ??= _androidFolderName;
      return DeviceIdentifierPluginPlatform.instance.deleteFileDeviceIdentifier(
        fileName: fileName,
        folderName: folderName,
      );
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms',
      );
    }
  }

  /// 检查是否存在基于文件的设备标识符
  ///
  /// 检查外部存储中是否已存在设备标识符文件
  /// Android专属接口
  /// [fileName] 文件名，默认为 'device_id.txt'
  /// [folderName] 文件夹名称，默认为 'DeviceIdentifier'
  ///
  /// 返回true表示存在标识符，false表示不存在
  Future<bool> hasFileDeviceIdentifier({String? fileName, String? folderName}) {
    if (Platform.isAndroid) {
      fileName ??= _androidFileName;
      folderName ??= _androidFolderName;
      return DeviceIdentifierPluginPlatform.instance.hasFileDeviceIdentifier(
        fileName: fileName,
        folderName: folderName,
      );
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms',
      );
    }
  }

  /// 请求Android特有的读写外部存储权限
  /// 在Android 6.0-10版本中需要WRITE_EXTERNAL_STORAGE权限
  /// 在Android 11+版本中需要MANAGE_EXTERNAL_STORAGE权限
  /// 返回值不代表权限是否已授予，需要另行调用检查权限的接口[hasExternalStoragePermission]
  Future<void> requestExternalStoragePermission() {
    if (Platform.isAndroid) {
      return DeviceIdentifierPluginPlatform.instance
          .requestExternalStoragePermission();
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms',
      );
    }
  }

  /// 检查Android特有的外部存储权限是否已被授予
  /// 返回true表示已授予读写外部存储权限，false表示未授予
  Future<bool> hasExternalStoragePermission() {
    if (Platform.isAndroid) {
      return DeviceIdentifierPluginPlatform.instance
          .hasExternalStoragePermission();
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms',
      );
    }
  }
}
