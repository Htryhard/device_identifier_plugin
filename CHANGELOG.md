# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-21

### Added - iOS Platform Support
- **🎉 Major Release**: Added comprehensive iOS platform support
- **iOS Device Identifiers**:
  - iOS Device ID: A stable, Android ID-like identifier for iOS
  - IDFV (Identifier for Vendor): Shared across apps from the same developer
  - IDFA (Identifier for Advertisers): Advertising identifier with user consent
  - Keychain UUID: Most stable identifier stored in iOS Keychain
  - Device Fingerprint: Hardware-based identifier
  - Launch UUID: Session-based temporary identifier
  - Combined ID: Hash combination of multiple identifiers

- **iOS Specific Features**:
  - App Tracking Transparency (ATT) framework support
  - Automatic iOS 14.5+ compliance
  - Request tracking authorization dialog
  - Keychain-based persistent storage
  - Real device vs Simulator detection

- **Cross-Platform API**:
  - Updated `DeviceIdentifier` model with iOS fields
  - Platform-specific method filtering
  - Unified `getBestDeviceIdentifier()` for both platforms
  - Enhanced device information collection

### Updated
- **Flutter Plugin Architecture**:
  - Updated platform interface with iOS methods
  - Enhanced method channel implementation
  - Improved error handling and async support
  - Added comprehensive documentation

- **Example Application**:
  - Complete rewrite with platform-specific UI
  - iOS tracking authorization demo
  - Enhanced device information display
  - Platform-aware feature toggles
  - Real-time permission status updates

- **Documentation**:
  - Comprehensive README with iOS setup instructions
  - Privacy compliance guidelines
  - Platform-specific usage examples
  - API reference documentation

### Technical Details
- **iOS Native Implementation**:
  - Swift 5.0+ with async/await support
  - Security framework for Keychain access
  - AdSupport framework for IDFA
  - AppTrackingTransparency for iOS 14.5+ compliance
  - CommonCrypto for SHA-256 hashing
  - os.log for comprehensive logging

- **iOS Configuration**:
  - Updated podspec with required frameworks
  - Added NSUserTrackingUsageDescription to Info.plist
  - Minimum iOS 12.0 deployment target

### Privacy & Compliance
- **iOS Privacy Features**:
  - Full ATT framework integration
  - User consent management
  - Privacy description strings
  - Graceful degradation when permissions denied

- **Cross-Platform Privacy**:
  - Consistent privacy API across platforms
  - Permission status checking
  - User-friendly error messages
  - Best practices documentation

### Breaking Changes
- Updated `DeviceIdentifier` model with new iOS fields
- Platform interface now includes iOS-specific methods
- Minimum Flutter SDK requirements updated for async/await support

## [0.0.1] - 2024-XX-XX

### Added - Initial Android Release
- Android platform support with comprehensive device identifier collection
- Android ID, Advertising ID, Install UUID, Device Fingerprint, Build Serial
- File-based device identifier with external storage
- Permission management and storage strategy detection
- Device information and emulator detection
- Comprehensive example application
- Permission setup guide and documentation

---

## Migration Guide from 0.x to 1.0.0

### For Existing Android Users
Your existing code will continue to work without changes. The `DeviceIdentifier` model now includes additional iOS fields that will be `null` on Android devices.

### For New iOS Users
1. Add the NSUserTrackingUsageDescription to your Info.plist
2. Request tracking authorization if needed:
   ```dart
   if (Platform.isIOS) {
     String? status = await plugin.requestTrackingAuthorization();
   }
   ```

### Updated Model Usage
```dart
DeviceIdentifier identifier = await plugin.getDeviceIdentifier();

// Use platform check for specific fields
if (Platform.isIOS) {
  print('iOS Device ID: ${identifier.iosDeviceID}');
  print('IDFA: ${identifier.idfa}');
} else if (Platform.isAndroid) {
  print('Android ID: ${identifier.androidId}');
}

// Or use the convenience method
String? bestId = identifier.getBestIdentifier();
```

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/hicyh/device_identifier_plugin/issues)
- Documentation: See README.md for detailed usage instructions
- Examples: Check the example/ directory for complete implementation
