# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-08-04

### Changed

- Support up to Android SDK 21

---

## [0.0.9] - 2025-07-23

### Changed

- Remove unnecessary debug logs
- Android platform supports obtaining DRM ID [Digital Rights Management Identifier (Widevine id)]

---

## [0.0.8] - 2025-07-18

### Changed

- Added clearer documentation description
- Added clearer comments to [DeviceIdentifierPlugin] for easier use

---

## [0.0.7] - 2025-07-17

### Changed

- Removed some useless comments
- Eliminated some warnings
- Added the ability to set the keychain service name and account name under iOS
- Completed the document description

---

## [0.0.6] - 2025-07-16

### Changed

- Optimized Android device identifier retrieval: Added handling for null fields when obtaining Android identifiers (such as Android ID, Advertising ID, Install UUID, device fingerprint, serial number, etc.), ensuring more robust results and preventing exceptions or incomplete data due to null values.
- Improved compatibility and stability of the plugin on certain devices and special system environments.

---

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/hicyh/device_identifier_plugin/issues)
- Documentation: See README.md for detailed usage instructions
- Examples: Check the example/ directory for complete implementation
