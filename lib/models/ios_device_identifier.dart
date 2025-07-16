class IosDeviceIdentifier {
  /// iOS设备ID: 类似Android ID的概念，最推荐用于统计
  final String iosDeviceID;

  /// IDFV: 同一开发者应用共享，卸载重装时可能变化
  final String? idfv;

  /// IDFA: 广告标识符，iOS 14.5+ 需要用户授权，卸载重装不变
  final String? idfa;

  /// Keychain UUID: 存储在钥匙串中，最稳定的标识符
  final String? keychainUUID;

  /// 设备指纹: 基于硬件信息生成的相对稳定标识符
  final String? deviceFingerprint;

  /// 应用启动UUID: 每次应用启动生成，测试用
  final String launchUUID;

  /// 组合ID: 多个标识符的组合哈希
  final String? combinedId;

  /// 是否限制广告追踪: ATT授权状态
  final bool isLimitAdTrackingEnabled;

  /// 设备基本信息
  final Map<String, String> deviceInfo;

  const IosDeviceIdentifier({
    required this.iosDeviceID,
    this.idfv,
    this.idfa,
    this.keychainUUID,
    this.deviceFingerprint,
    required this.launchUUID,
    this.combinedId,
    this.isLimitAdTrackingEnabled = false,
    required this.deviceInfo,
  });

  factory IosDeviceIdentifier.fromJson(Map<String, dynamic> json) {
    return IosDeviceIdentifier(
      iosDeviceID: json['iosDeviceID'],
      idfv: json['idfv'],
      idfa: json['idfa'],
      keychainUUID: json['keychainUUID'],
      deviceFingerprint: json['deviceFingerprint'],
      launchUUID: json['launchUUID'],
      combinedId: json['combinedId'],
      isLimitAdTrackingEnabled: json['isLimitAdTrackingEnabled'] ?? false,
      deviceInfo: Map<String, String>.from(json['deviceInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iosDeviceID': iosDeviceID,
      'idfv': idfv,
      'idfa': idfa,
      'keychainUUID': keychainUUID,
      'deviceFingerprint': deviceFingerprint,
      'launchUUID': launchUUID,
      'combinedId': combinedId,
      'isLimitAdTrackingEnabled': isLimitAdTrackingEnabled,
      'deviceInfo': deviceInfo,
    };
  }

  @override
  String toString() {
    return 'IosDeviceIdentifier{iosDeviceID: $iosDeviceID, idfv: $idfv, idfa: $idfa, keychainUUID: $keychainUUID, deviceFingerprint: $deviceFingerprint, launchUUID: $launchUUID, combinedId: $combinedId, isLimitAdTrackingEnabled: $isLimitAdTrackingEnabled, deviceInfo: $deviceInfo}';
  }
}
