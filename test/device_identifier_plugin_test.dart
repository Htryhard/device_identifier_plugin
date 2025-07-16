import 'package:flutter_test/flutter_test.dart';
import 'package:device_identifier_plugin/device_identifier_plugin.dart';
import 'package:device_identifier_plugin/device_identifier_plugin_platform_interface.dart';
import 'package:device_identifier_plugin/device_identifier_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDeviceIdentifierPluginPlatform
    with MockPlatformInterfaceMixin
    implements DeviceIdentifierPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> deleteFileDeviceIdentifier({
    String fileName = 'device_id.txt',
    String folderName = 'DeviceIdentifier',
  }) {
    // TODO: implement deleteFileDeviceIdentifier
    throw UnimplementedError();
  }

  @override
  Future<String?> getAndroidId() {
    // TODO: implement getAndroidId
    throw UnimplementedError();
  }

  @override
  Future<String?> getAppleIDFV() {
    // TODO: implement getAppleIDFV
    throw UnimplementedError();
  }

  @override
  Future<Map<String, String>> getDeviceInfo() {
    // TODO: implement getDeviceInfo
    throw UnimplementedError();
  }

  @override
  Future<String?> getFileDeviceIdentifier({
    String fileName = 'device_id.txt',
    String folderName = 'DeviceIdentifier',
  }) {
    // TODO: implement getFileDeviceIdentifier
    throw UnimplementedError();
  }

  @override
  Future<String?> getKeychainUUID() {
    // TODO: implement getKeychainUUID
    throw UnimplementedError();
  }

  @override
  Future<Map<String, String?>> getSupportedIdentifiers() {
    // TODO: implement getSupportedIdentifiers
    throw UnimplementedError();
  }

  @override
  Future<bool> hasExternalStoragePermission() {
    // TODO: implement hasExternalStoragePermission
    throw UnimplementedError();
  }

  @override
  Future<bool> hasFileDeviceIdentifier({
    String fileName = 'device_id.txt',
    String folderName = 'DeviceIdentifier',
  }) {
    // TODO: implement hasFileDeviceIdentifier
    throw UnimplementedError();
  }

  @override
  Future<bool> hasKeychainUUID() {
    // TODO: implement hasKeychainUUID
    throw UnimplementedError();
  }

  @override
  Future<bool> isEmulator() {
    // TODO: implement isEmulator
    throw UnimplementedError();
  }

  @override
  Future<void> requestExternalStoragePermission() {
    // TODO: implement requestExternalStoragePermission
    throw UnimplementedError();
  }

  @override
  Future<String?> requestTrackingAuthorization() {
    // TODO: implement requestTrackingAuthorization
    throw UnimplementedError();
  }

  @override
  Future<String?> generateKeychainUUID() {
    // TODO: implement saveKeychainUUID
    throw UnimplementedError();
  }

  @override
  Future<String?> generateFileDeviceIdentifier({
    String fileName = 'device_id.txt',
    String folderName = 'DeviceIdentifier',
  }) {
    // TODO: implement generateFileDeviceIdentifier
    throw UnimplementedError();
  }

  @override
  Future<String?> getAdvertisingIdForAndroid() {
    // TODO: implement getAdvertisingIdForAndroid
    throw UnimplementedError();
  }

  @override
  Future<String?> getAdvertisingIdForiOS() {
    // TODO: implement getAdvertisingIdForiOS
    throw UnimplementedError();
  }
}

void main() {
  final DeviceIdentifierPluginPlatform initialPlatform =
      DeviceIdentifierPluginPlatform.instance;

  test('$MethodChannelDeviceIdentifierPlugin is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelDeviceIdentifierPlugin>(),
    );
  });

  test('getPlatformVersion', () async {
    DeviceIdentifierPlugin deviceIdentifierPlugin = DeviceIdentifierPlugin();
    MockDeviceIdentifierPluginPlatform fakePlatform =
        MockDeviceIdentifierPluginPlatform();
    DeviceIdentifierPluginPlatform.instance = fakePlatform;

    expect(await deviceIdentifierPlugin.getPlatformVersion(), '42');
  });
}
