import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'device_identifier_plugin_platform_interface.dart';

/// An implementation of [DeviceIdentifierPluginPlatform] that uses method channels.
class MethodChannelDeviceIdentifierPlugin
    extends DeviceIdentifierPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'com.hicyh.device_identifier_plugin',
  );

  /// 获取平台版本
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  /// 检查是否为模拟器
  /// Android和iOS通用接口
  @override
  Future<bool> isEmulator() async {
    final result = await methodChannel.invokeMethod<bool>('isEmulator');
    if (result == null) {
      return false; // 默认返回false，表示不是模拟器
    }
    return result;
  }

  /// 获取设备信息
  /// Android和iOS通用接口
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
  @override
  Future<Map<String, String?>> getDeviceInfo() async {
    final result = await methodChannel.invokeMethod('getDeviceInfo');
    if (result == null) return {};
    return Map<String, String?>.from(result as Map);
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
  @override
  Future<Map<String, dynamic>> getSupportedIdentifiers() async {
    final result = await methodChannel.invokeMethod('getSupportedIdentifiers');
    // print("---------> $result");
    if (result == null) return {};
    return Map<String, dynamic>.from(result as Map);
  }

  /// 获取广告标识符
  /// iOS接口
  /// 返回的是IDFA - Identifier for Advertisers，此ID需要用户授权
  @override
  Future<String?> getAdvertisingIdForiOS() async {
    final result = await methodChannel.invokeMethod<String?>(
      'getAdvertisingIdForiOS',
    );
    return result;
  }

  /// 设置钥匙串的服务和账户名称
  /// iOS专属接口
  /// 用于自定义钥匙串存储位置
  /// [service] 钥匙串服务名称，默认为 'com.hicyh.getdeviceid.keychain'
  /// [keyAccount] 钥匙串账户名称，默认为 'device_uuid'
  /// [deviceIDAccount] 钥匙串设备ID账户名称，默认为 'ios_device_id'
  /// 如果不设置则使用默认值
  /// 如果需要在iOS中使用钥匙串存储设备标识符，
  /// 请在调用其他钥匙串相关方法之前先调用此方法设置服务和账户名称
  /// 注意：此方法仅在iOS平台上有效，Android平台不支持钥匙串存储
  @override
  Future<void> setKeychainServiceAndAccount({
    String service = 'com.hicyh.getdeviceid.keychain',
    String keyAccount = 'device_uuid',
    String deviceIDAccount = 'ios_device_id',
  }) {
    return methodChannel.invokeMethod('setKeychainServiceAndAccount', {
      'service': service,
      'keyUUIDAccount': keyAccount,
      'deviceIDAccount': deviceIDAccount,
    });
  }

  /// iOS 特有方法：请求广告追踪权限
  ///
  /// 在iOS 14.5+版本中，需要用户明确授权才能获取IDFA
  @override
  Future<String?> requestTrackingAuthorization() async {
    final result = await methodChannel.invokeMethod<String>(
      'requestTrackingAuthorization',
    );
    return result;
  }

  /// 获取idfv
  /// iOS专属接口
  /// 返回IDFV（Identifier for Vendor），同一开发者应用共享
  @override
  Future<String?> getAppleIDFV() async {
    final result = await methodChannel.invokeMethod<String?>('getAppleIDFV');
    return result;
  }

  /// 获取钥匙串UUID
  /// iOS专属接口
  /// 返回存储在钥匙串中的UUID，最稳定的标识符
  /// 如果未存储则返回null
  @override
  Future<String?> getKeychainUUID() async {
    final result = await methodChannel.invokeMethod<String?>('getKeychainUUID');
    return result;
  }

  /// 检查是否存在钥匙串UUID
  /// iOS专属接口
  /// 返回true表示存在钥匙串UUID，false表示不存在
  @override
  Future<bool> hasKeychainUUID() async {
    final result = await methodChannel.invokeMethod<bool?>('hasKeychainUUID');
    return result ?? false;
  }

  /// 生成钥匙串UUID
  /// iOS专属接口
  /// 如果已成在则返回现有UUID，否则生成新的UUID并存储
  @override
  Future<String?> generateKeychainUUID() async {
    final result = await methodChannel.invokeMethod<String?>(
      'generateKeychainUUID',
    );
    return result;
  }

  /// 获取广告标识符
  /// Android接口
  /// Android返回的是GAID - Google Advertising ID，此ID需要设备支持谷歌服务
  @override
  Future<String?> getAdvertisingIdForAndroid() async {
    final result = await methodChannel.invokeMethod<String?>(
      'getAdvertisingIdForAndroid',
    );
    return result;
  }

  /// 获取Android ID
  /// Android专属接口
  @override
  Future<String?> getAndroidId() async {
    final result = await methodChannel.invokeMethod<String?>('getAndroidId');
    return result;
  }

  /// 获取基于文件的设备标识符
  /// Android专属接口
  /// [folderName] 文件夹名称，默认为 'DeviceIdentifier'
  /// [fileName] 文件名，默认为 'device_id.txt'
  /// 返回设备ID或null，如果为null则表示未找到或未生成
  @override
  Future<String?> getFileDeviceIdentifier({
    String fileName = 'device_id.txt',
    String folderName = 'DeviceIdentifier',
  }) async {
    final result = await methodChannel.invokeMethod<String>(
      'getFileDeviceIdentifier',
      {'fileName': fileName, 'folderName': folderName},
    );
    return result;
  }

  /// 生成并返回基于文件的设备标识符
  /// Android专属接口
  /// [folderName] 文件夹名称，默认为 'DeviceIdentifier'
  /// [fileName] 文件名，默认为 'device_id.txt'
  /// 返回生成的设备ID字符串，如果权限不足或创建失败则返回null
  @override
  Future<String?> generateFileDeviceIdentifier({
    String fileName = 'device_id.txt',
    String folderName = 'DeviceIdentifier',
  }) async {
    final result = await methodChannel.invokeMethod<String>(
      'generateFileDeviceIdentifier',
      {'fileName': fileName, 'folderName': folderName},
    );
    return result;
  }

  /// 删除文件存储的设备标识符
  /// Android专属接口
  @override
  Future<bool> deleteFileDeviceIdentifier({
    String fileName = 'device_id.txt',
    String folderName = 'DeviceIdentifier',
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'deleteFileBasedDeviceIdentifier',
      {'fileName': fileName, 'folderName': folderName},
    );
    return result ?? false;
  }

  /// 检查是否存在文件存储的设备标识符
  /// Android专属接口
  @override
  Future<bool> hasFileDeviceIdentifier({
    String fileName = 'device_id.txt',
    String folderName = 'DeviceIdentifier',
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'hasFileBasedDeviceIdentifier',
      {'fileName': fileName, 'folderName': folderName},
    );
    return result ?? false;
  }

  @override
  Future<void> requestExternalStoragePermission() async {
    await methodChannel.invokeMethod('requestExternalStoragePermission');
  }

  @override
  Future<bool> hasExternalStoragePermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'hasExternalStoragePermission',
    );
    return result ?? false;
  }
}
