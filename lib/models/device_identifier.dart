class DeviceIdentifier {
  // Android 字段
  /// Android 设备的 ANDROID_ID，通常为设备唯一标识
  final String? androidId;

  /// 广告标识符（如 Google Advertising ID）
  final String? advertisingId;

  /// 应用安装时生成的唯一 UUID
  final String? installUuid;

  /// 设备指纹信息（如硬件、系统等组合生成的唯一标识）
  final String? deviceFingerprint;

  /// 设备的 Build Serial 序列号
  final String? buildSerial;

  /// 多种标识符组合生成的唯一 ID
  final String? combinedId;

  /// 是否开启了"限制广告跟踪"
  final bool isLimitAdTrackingEnabled;

  // iOS 字段
  /// iOS设备ID: 类似Android ID的概念，最推荐用于统计
  final String? iosDeviceID;

  /// IDFV: 同一开发者应用共享，卸载重装时可能变化
  final String? idfv;

  /// IDFA: 广告标识符，iOS 14.5+ 需要用户授权，卸载重装不变
  final String? idfa;

  /// Keychain UUID: 存储在钥匙串中，最稳定的标识符
  final String? keychainUUID;

  /// 应用启动UUID: 每次应用启动生成，测试用
  final String? launchUUID;

  /// 设备基本信息
  final Map<String, String>? deviceInfo;

  const DeviceIdentifier({
    // Android 字段
    this.androidId,
    this.advertisingId,
    this.installUuid,
    this.deviceFingerprint,
    this.buildSerial,
    this.combinedId,
    this.isLimitAdTrackingEnabled = false,
    // iOS 字段
    this.iosDeviceID,
    this.idfv,
    this.idfa,
    this.keychainUUID,
    this.launchUUID,
    this.deviceInfo,
  });

  factory DeviceIdentifier.fromJson(Map<String, dynamic> json) {
    return DeviceIdentifier(
      // Android 字段
      androidId: json['androidId'],
      advertisingId: json['advertisingId'],
      installUuid: json['installUuid'],
      deviceFingerprint: json['deviceFingerprint'],
      buildSerial: json['buildSerial'],
      combinedId: json['combinedId'],
      isLimitAdTrackingEnabled: json['isLimitAdTrackingEnabled'] ?? false,
      // iOS 字段
      iosDeviceID: json['iosDeviceID'],
      idfv: json['idfv'],
      idfa: json['idfa'],
      keychainUUID: json['keychainUUID'],
      launchUUID: json['launchUUID'],
      deviceInfo: json['deviceInfo'] != null
          ? Map<String, String>.from(json['deviceInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Android 字段
      'androidId': androidId,
      'advertisingId': advertisingId,
      'installUuid': installUuid,
      'deviceFingerprint': deviceFingerprint,
      'buildSerial': buildSerial,
      'combinedId': combinedId,
      'isLimitAdTrackingEnabled': isLimitAdTrackingEnabled,
      // iOS 字段
      'iosDeviceID': iosDeviceID,
      'idfv': idfv,
      'idfa': idfa,
      'keychainUUID': keychainUUID,
      'launchUUID': launchUUID,
      'deviceInfo': deviceInfo,
    };
  }

  /// 获取最佳的设备标识符
  ///
  /// 根据平台返回最适合的设备标识符：
  /// - Android: 优先返回 Android ID
  /// - iOS: 优先返回 iOS Device ID
  /// - 备选: 组合ID、设备指纹、安装UUID
  String? getBestIdentifier() {
    // iOS 平台优先使用 iOS Device ID
    if (iosDeviceID != null && iosDeviceID!.isNotEmpty) {
      return iosDeviceID;
    }

    // Android 平台优先使用 Android ID
    if (androidId != null && androidId!.isNotEmpty) {
      return androidId;
    }

    // 备选1: 组合ID
    if (combinedId != null && combinedId!.isNotEmpty) {
      return combinedId;
    }

    // 备选2: 设备指纹
    if (deviceFingerprint != null && deviceFingerprint!.isNotEmpty) {
      return deviceFingerprint;
    }

    // 备选3: Keychain UUID (iOS)
    if (keychainUUID != null && keychainUUID!.isNotEmpty) {
      return keychainUUID;
    }

    // 备选4: 安装UUID
    if (installUuid != null && installUuid!.isNotEmpty) {
      return installUuid;
    }

    // 最后备选: IDFV (iOS)
    if (idfv != null && idfv!.isNotEmpty) {
      return idfv;
    }

    return null;
  }

  /// 检查是否为iOS平台
  bool get isIOS => iosDeviceID != null || idfv != null || idfa != null;

  /// 检查是否为Android平台
  bool get isAndroid => androidId != null || buildSerial != null;

  @override
  String toString() {
    return 'DeviceIdentifier{'
        'androidId: $androidId, '
        'advertisingId: $advertisingId, '
        'installUuid: $installUuid, '
        'deviceFingerprint: $deviceFingerprint, '
        'buildSerial: $buildSerial, '
        'combinedId: $combinedId, '
        'isLimitAdTrackingEnabled: $isLimitAdTrackingEnabled, '
        'iosDeviceID: $iosDeviceID, '
        'idfv: $idfv, '
        'idfa: $idfa, '
        'keychainUUID: $keychainUUID, '
        'launchUUID: $launchUUID, '
        'deviceInfo: $deviceInfo'
        '}';
  }
}
