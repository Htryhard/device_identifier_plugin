#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint device_identifier_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'device_identifier_plugin'
  s.version          = '0.0.7'
  s.summary          = 'A Flutter plugin for getting device unique identifiers on Android and iOS.'
  s.description      = <<-DESC
A comprehensive Flutter plugin that provides multiple methods to obtain device unique identifiers.
Supports both Android and iOS platforms with different identifier strategies:
- Android: Android ID, Advertising ID, Install UUID, Device Fingerprint, Build Serial, File-based ID
- iOS: iOS Device ID, IDFV, IDFA, Keychain UUID, Device Fingerprint, Launch UUID
Fully compliant with the latest privacy policies and App Store guidelines.
                       DESC
  s.homepage         = 'https://github.com/hicyh/device_identifier_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'hicyh' => 'hicyh@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Required iOS frameworks
  s.frameworks = 'Security', 'AdSupport', 'AppTrackingTransparency'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'device_identifier_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
