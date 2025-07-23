import 'dart:io';

import 'device_identifier_plugin_platform_interface.dart';

/// DeviceIdentifierPlugin - Device Identifier Plugin
///
/// Provides multiple methods to obtain device identifiers, supporting both Android and iOS platforms
/// Android: includes Android ID, GAID, install UUID, device fingerprint, serial number, and more
/// iOS: includes iOS device ID, IDFV, IDFA, Keychain UUID, device fingerprint, and more
class DeviceIdentifierPlugin {
  late String _androidFileName = 'device_id.txt';
  late String _androidFolderName = 'DeviceIdentifier';

  static final DeviceIdentifierPlugin _instance =
      DeviceIdentifierPlugin._internal();

  factory DeviceIdentifierPlugin() {
    return _instance;
  }

  DeviceIdentifierPlugin._internal();

  static DeviceIdentifierPlugin get instance => _instance;

  /// Set the file name and folder name for saving the identifier on Android external storage
  /// For example: /storage/emulated/0/DeviceIdentifier/device_id.txt
  /// [androidFileName] File name, default is 'device_id.txt'
  /// [androidFolderName] Folder name, default is 'DeviceIdentifier'
  void setAndroidFileStorage({
    String androidFileName = 'device_id.txt',
    String androidFolderName = 'DeviceIdentifier',
  }) {
    _androidFileName = androidFileName;
    _androidFolderName = androidFolderName;
  }

  /// Get platform version information
  Future<String?> getPlatformVersion() {
    return DeviceIdentifierPluginPlatform.instance.getPlatformVersion();
  }

  /// Get the optimal device identifier
  /// Always returns the most suitable device identifier for the current platform
  Future<String> getBestDeviceIdentifier() async {
    if (Platform.isAndroid) {
      // 1. Prefer to get Android ID
      final androidId =
          await DeviceIdentifierPluginPlatform.instance.getAndroidId();
      if (androidId != null && androidId.isNotEmpty) {
        return androidId;
      }
      // 2. If Android ID is not available, try to check if external storage read permission is granted
      final hasPermission =
          await DeviceIdentifierPluginPlatform.instance
              .hasExternalStoragePermission();
      if (hasPermission) {
        // If permission is granted, try to get the file-based device identifier
        final fileDeviceId =
            await DeviceIdentifierPluginPlatform.instance
                .getFileDeviceIdentifier();
        if (fileDeviceId != null && fileDeviceId.isNotEmpty) {
          return fileDeviceId;
        } else {
          // Generate a new file-based device identifier
          final generatedId =
              await DeviceIdentifierPluginPlatform.instance
                  .generateFileDeviceIdentifier();
          if (generatedId != null && generatedId.isNotEmpty) {
            return generatedId;
          }
        }
      }
      // 3. If no external storage permission or failed to get, try to get advertising ID
      final advertisingId =
          await DeviceIdentifierPluginPlatform.instance
              .getAdvertisingIdForAndroid();
      if (advertisingId != null && advertisingId.isNotEmpty) {
        return advertisingId;
      }
      // Finally, use device fingerprint to get Android identifier, this property will always have a value
      final supperIdMap =
          await DeviceIdentifierPluginPlatform.instance
              .getSupportedIdentifiers();
      final deviceFingerprint = supperIdMap['deviceFingerprint'] as String?;
      return deviceFingerprint ?? "";
    } else if (Platform.isIOS) {
      // 1. Prefer to get Keychain UUID
      final hasKeychainUUID =
          await DeviceIdentifierPluginPlatform.instance.hasKeychainUUID();
      if (hasKeychainUUID) {
        final keychainUUID =
            await DeviceIdentifierPluginPlatform.instance.getKeychainUUID();
        return keychainUUID!;
      } else {
        // If Keychain UUID is not available, try to generate a new one
        final generatedUUID =
            await DeviceIdentifierPluginPlatform.instance
                .generateKeychainUUID();
        if (generatedUUID != null && generatedUUID.isNotEmpty) {
          return generatedUUID;
        }
      }
      // 2. Get advertising identifier
      final idfa =
          await DeviceIdentifierPluginPlatform.instance
              .getAdvertisingIdForiOS();
      if (idfa != null && idfa.isNotEmpty) {
        return idfa;
      }
      // Finally, get iOS device ID, this ID will always return a value
      final supperIdMap =
          await DeviceIdentifierPluginPlatform.instance
              .getSupportedIdentifiers();
      final iosDeviceId = supperIdMap['iosDeviceID'] as String?;
      return iosDeviceId ?? "";
    } else {
      throw UnsupportedError('Unsupported platform[getBestDeviceIdentifier()]');
    }
  }

  /// Check if the current device is an emulator
  ///
  /// Determine whether it is an emulator environment by checking the device's hardware characteristics
  ///
  /// Android: includes fingerprint info, model name, manufacturer, etc.
  /// iOS: determined by compilation conditions
  ///
  /// Returns true for emulator, false for real device
  Future<bool> isEmulator() {
    return DeviceIdentifierPluginPlatform.instance.isEmulator();
  }

  /// Get basic device information
  ///
  /// Returns detailed hardware and system information of the device
  ///
  /// Android returns:
  /// - brand: device brand (e.g. Xiaomi, HUAWEI, Samsung)
  /// - model: device model (e.g. MI 10, SM-G9730)
  /// - manufacturer: device manufacturer (e.g. Xiaomi, HUAWEI, Samsung)
  /// - device: device name (internal code, e.g. "cepheus")
  /// - product: product name (e.g. "cepheus")
  /// - board: board name (e.g. "msm8998")
  /// - hardware: hardware name (e.g. "qcom")
  /// - android_version: system version (e.g. "13")
  /// - sdk_int: system SDK version (e.g. "33")
  /// - fingerprint: device fingerprint (unique string identifying a device)
  /// - is_emulator: whether it is an emulator (true/false)
  ///
  /// iOS returns:
  /// - model: device model identifier (e.g. "iPhone14,2")
  /// - name: device name (e.g. "Zhang San's iPhone")
  /// - systemName: OS name (e.g. "iOS")
  /// - systemVersion: OS version (e.g. "17.0.2")
  /// - localizedModel: localized device model (e.g. "iPhone")
  /// - isSimulator: whether it is a simulator ("true"/"false")
  /// - screenSize: screen resolution (e.g. "390x844")
  /// - screenScale: screen scale factor (e.g. "3.0")
  /// - timeZone: current time zone identifier (e.g. "Asia/Shanghai")
  /// - language: current system language (e.g. "zh", "en")
  Future<Map<String, String?>> getDeviceInfo() {
    return DeviceIdentifierPluginPlatform.instance.getDeviceInfo();
  }

  /// Get supported device identifiers
  /// Common interface for Android and iOS
  /// Android returns:
  /// - androidId: Android ID (changes on factory reset, flashing, user switch, not changed on uninstall/reinstall)
  /// - widevineDrmId: DRM ID, Digital Rights Management Identifier (Widevine id)
  /// - advertisingId: Advertising ID (user can reset manually, auto-reset about once a month, not changed on uninstall/reinstall)
  /// - installUuid: Install UUID (newly generated on each install, always changes on uninstall/reinstall)
  /// - deviceFingerprint: Device fingerprint (generated based on board name, brand, device name, hardware name, manufacturer, model, product, system version, SDK version, screen width/height/density, supported CPU architectures; may change on system update or hardware change)
  /// - buildSerial: Device serial number (hardware-level identifier, does not change unless device is replaced, but cannot be obtained without system privileges or signature)
  /// - combinedId: Combined ID (generated from androidId, advertisingId, installUuid, deviceFingerprint; changes depend on components)
  /// - isLimitAdTrackingEnabled: Whether ad tracking is limited (user setting, affects use of advertising ID)
  ///
  /// iOS returns:
  /// - iosDeviceID: iOS device ID (generated from idfv, deviceFingerprint, idfa, getDeviceInfo(); if all are empty, generated from current timestamp. Saved in keychain for reuse)
  /// - idfv: IDFV (shared among apps from the same developer, may change on uninstall/reinstall)
  /// - idfa: IDFA (requires user authorization on iOS 14.5+, not changed on uninstall/reinstall)
  /// - keychainUUID: Keychain UUID (stored in keychain, most stable identifier)
  /// - deviceFingerprint: Device fingerprint (relatively stable identifier generated from hardware info: model, system version, screen size/density, time zone, language)
  /// - launchUUID: App launch UUID (generated on each app launch, for testing)
  /// - combinedId: Combined ID (hash of multiple identifiers: idfv, keychainUUID, deviceFingerprint, idfa; if all are empty, randomly generated)
  /// - isLimitAdTrackingEnabled: Whether ad tracking is limited (ATT authorization status)
  Future<Map<String, dynamic>> getSupportedIdentifiers() {
    return DeviceIdentifierPluginPlatform.instance.getSupportedIdentifiers();
  }

  /// Get advertising identifier
  /// iOS interface
  /// Returns IDFA - Identifier for Advertisers, requires user authorization
  /// Must call [requestTrackingAuthorization] to request user authorization before obtaining
  Future<String?> getAdvertisingIdForiOS() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.getAdvertisingIdForiOS();
    } else {
      throw UnsupportedError(
        'This method is only supported on iOS platforms [getAdvertisingIdForiOS()]',
      );
    }
  }

  /// iOS only: request ad tracking permission
  ///
  /// On iOS 14.5+, user authorization is required to obtain IDFA
  ///
  /// Returns authorization status:
  /// - 'notDetermined': user has not made a choice
  /// - 'restricted': restricted (e.g. parental controls)
  /// - 'denied': user denied authorization
  /// - 'authorized': user authorized
  ///
  /// This method will pop up a system dialog to request user authorization
  /// Authorization is required to call [getAdvertisingIdForiOS]
  Future<String?> requestTrackingAuthorization() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance
          .requestTrackingAuthorization();
    } else {
      throw UnsupportedError(
        'This method is only supported on iOS platforms [requestTrackingAuthorization()]',
      );
    }
  }

  /// Set keychain service and account
  /// iOS only
  /// Used to customize keychain storage location
  /// [service] Keychain service name, default is 'com.hicyh.getdeviceid.keychain'
  /// [keyAccount] Keychain account name, default is 'device_uuid'
  /// [deviceIDAccount] Keychain device ID account name, default is 'ios_device_id'
  /// If not set, default values are used
  /// If you need to use keychain to store device identifier on iOS,
  /// please call this method before other keychain-related methods
  /// Note: This method is only valid on iOS, Android does not support keychain storage
  Future<void> setKeychainServiceAndAccount({
    String service = 'com.hicyh.getdeviceid.keychain',
    String keyAccount = 'device_uuid',
    String deviceIDAccount = 'ios_device_id',
  }) {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance
          .setKeychainServiceAndAccount(
            service: service,
            keyAccount: keyAccount,
            deviceIDAccount: deviceIDAccount,
          );
    } else {
      throw UnsupportedError(
        'This method is only supported on iOS platforms [setKeychainServiceAndAccount()]',
      );
    }
  }

  /// Get idfv
  /// iOS only
  /// Returns IDFV (Identifier for Vendor), shared among apps from the same developer
  Future<String?> getAppleIDFV() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.getAppleIDFV();
    } else {
      throw UnsupportedError(
        'This method is only supported on iOS platforms [getAppleIDFV()]',
      );
    }
  }

  /// Get Keychain UUID
  /// iOS only
  /// Returns UUID stored in keychain
  /// Returns null or empty if not stored
  Future<String?> getKeychainUUID() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.getKeychainUUID();
    } else {
      throw UnsupportedError(
        'This method is only supported on iOS platforms [getKeychainUUID()]',
      );
    }
  }

  /// Check if Keychain UUID exists
  /// iOS only
  /// Returns true if Keychain UUID exists, false otherwise
  Future<bool> hasKeychainUUID() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.hasKeychainUUID();
    } else {
      throw UnsupportedError(
        'This method is only supported on iOS platforms [hasKeychainUUID()]',
      );
    }
  }

  /// Generate Keychain UUID
  /// iOS only
  /// If already exists, returns existing UUID, otherwise generates and stores a new UUID
  Future<String?> generateKeychainUUID() {
    if (Platform.isIOS) {
      return DeviceIdentifierPluginPlatform.instance.generateKeychainUUID();
    } else {
      throw UnsupportedError(
        'This method is only supported on iOS platforms [generateKeychainUUID()]',
      );
    }
  }

  /// Get Widevine DRM ID
  /// Android only
  /// Returns Widevine DRM ID, if device does not support, returns null
  /// This ID is used for DRM content protection, not suitable for user tracking
  Future<String?> getWidevineDrmId() {
    if (Platform.isAndroid) {
      return DeviceIdentifierPluginPlatform.instance.getWidevineDrmId();
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms [getWidevineDrmId()]',
      );
    }
  }

  /// Get advertising identifier
  /// Android interface
  /// Returns GAID - Google Advertising ID, requires Google services support
  Future<String?> getAdvertisingIdForAndroid() {
    if (Platform.isAndroid) {
      return DeviceIdentifierPluginPlatform.instance
          .getAdvertisingIdForAndroid();
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms [getAdvertisingIdForAndroid()]',
      );
    }
  }

  /// Get Android ID
  /// Android only
  Future<String?> getAndroidId() {
    if (Platform.isAndroid) {
      return DeviceIdentifierPluginPlatform.instance.getAndroidId();
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms [getAndroidId()]',
      );
    }
  }

  /// Get file-based device identifier
  ///
  /// Create a file in external storage to save a unique device identifier, which remains unchanged after uninstall/reinstall
  ///
  /// Requires storage permissions:
  /// - Android 6.0-10: WRITE_EXTERNAL_STORAGE
  /// - Android 11+: MANAGE_EXTERNAL_STORAGE
  /// - iOS: not supported
  ///
  /// Call [requestExternalStoragePermission] to request permission first
  /// and call [hasExternalStoragePermission] to check before calling this method
  ///
  /// [fileName] File name, default is 'device_id.txt'
  /// [folderName] Folder name, default is 'DeviceIdentifier'
  ///
  /// Returns device identifier string, returns null if permission is insufficient or creation fails
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
        'This method is only supported on Android platforms [getFileDeviceIdentifier()]',
      );
    }
  }

  /// Generate and return file-based device identifier
  ///
  /// Create a file in external storage to save a unique device identifier, which remains unchanged after uninstall/reinstall
  ///
  /// Requires storage permissions:
  /// - Android 6.0-10: WRITE_EXTERNAL_STORAGE
  /// - Android 11+: MANAGE_EXTERNAL_STORAGE
  /// - iOS: not supported
  ///
  /// Call [requestExternalStoragePermission] to request permission first
  /// and call [hasExternalStoragePermission] to check before calling this method
  ///
  /// [fileName] File name, default is 'device_id.txt'
  /// [folderName] Folder name, default is 'DeviceIdentifier'
  ///
  /// Returns device identifier string, returns null if permission is insufficient or creation fails. Unlike [getFileDeviceIdentifier],
  /// this method will generate a new identifier if not found, while [getFileDeviceIdentifier] will not
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
        'This method is only supported on Android platforms [generateFileDeviceIdentifier()]',
      );
    }
  }

  /// Delete file-based device identifier
  ///
  /// Delete the device identifier file saved in external storage
  /// Android only
  /// [fileName] File name, default is 'device_id.txt'
  /// [folderName] Folder name, default is 'DeviceIdentifier'
  ///
  /// Returns whether deletion was successful
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
        'This method is only supported on Android platforms [deleteFileDeviceIdentifier()]',
      );
    }
  }

  /// Check if file-based device identifier exists
  ///
  /// Check if the device identifier file already exists in external storage
  /// Android only
  /// [fileName] File name, default is 'device_id.txt'
  /// [folderName] Folder name, default is 'DeviceIdentifier'
  ///
  /// Returns true if identifier exists, false otherwise
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
        'This method is only supported on Android platforms [hasFileDeviceIdentifier()]',
      );
    }
  }

  /// Request Android-specific read/write external storage permission
  /// On Android 6.0-10 requires WRITE_EXTERNAL_STORAGE
  /// On Android 11+ requires MANAGE_EXTERNAL_STORAGE
  /// Return value does not indicate whether permission is granted, need to check with [hasExternalStoragePermission]
  Future<void> requestExternalStoragePermission() {
    if (Platform.isAndroid) {
      return DeviceIdentifierPluginPlatform.instance
          .requestExternalStoragePermission();
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms [requestExternalStoragePermission()]',
      );
    }
  }

  /// Check if Android-specific external storage permission is granted
  /// Returns true if read/write external storage permission is granted, false otherwise
  Future<bool> hasExternalStoragePermission() {
    if (Platform.isAndroid) {
      return DeviceIdentifierPluginPlatform.instance
          .hasExternalStoragePermission();
    } else {
      throw UnsupportedError(
        'This method is only supported on Android platforms [hasExternalStoragePermission()]',
      );
    }
  }
}
