import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:device_identifier_plugin/device_identifier_plugin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    // 设置Android平台的文件存储名称(如果需要存储文件标识ID的话)
    DeviceIdentifierPlugin.instance.setAndroidFileStorage(
      androidFileName: 'device_id',
    );
  } else if (Platform.isIOS) {
    // 设置iOS平台的Keychain服务名称
    // 这将用于存储Keychain UUID等信息
    DeviceIdentifierPlugin.instance.setKeychainServiceAndAccount(
      service: 'com.example.device_identifier_plugin',
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _deviceIdentifierPlugin = DeviceIdentifierPlugin.instance;

  // 设备标识符数据
  String _bestIdentifier = '';
  Map<String, dynamic> _deviceIdentifier = {};
  String? _fileBasedId;
  bool _isEmulator = false;
  Map<String, String?> _deviceInfo = {};
  String? _trackingAuthStatus;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _deviceIdentifierPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;
    setState(() {
      _platformVersion = platformVersion;
    });
  }

  /// API示例
  void _apiExample() {
    // 获取支持的设备标识符，具体支持哪些请点开查看接口注释
    _deviceIdentifierPlugin.getSupportedIdentifiers().then((value) {
      print('Device Identifier: $value');
    });

    // 获取最优标识符
    _deviceIdentifierPlugin.getBestDeviceIdentifier().then((value) {
      print('Best Device Identifier: $value');
    });

    // 检查是否为模拟器
    _deviceIdentifierPlugin.isEmulator().then((value) {
      print('Is Emulator: $value');
    });

    // 获取设备信息，具体有哪些信息请点开查看接口注释
    _deviceIdentifierPlugin.getDeviceInfo().then((value) {
      print('Device Info: $value');
    });

    // 获取文件存储标识符（Android特有）
    if (Platform.isAndroid) {
      // 生成并返回文件存储标识符
      _deviceIdentifierPlugin.generateFileDeviceIdentifier().then((value) {
        print('File-Based Device Identifier: $value');
      });

      // 获取文件存储标识符，如果没有生成过则返回null
      _deviceIdentifierPlugin.getFileDeviceIdentifier().then((value) {
        print('File-Based Device Identifier: $value');
      });

      // 是否存在文件标识符ID
      _deviceIdentifierPlugin.hasFileDeviceIdentifier().then((value) {
        print('Has File-Based Device Identifier: $value');
      });

      // 删除文件存储标识符
      _deviceIdentifierPlugin.deleteFileDeviceIdentifier().then((value) {
        print('File-Based Device Identifier deleted: $value');
      });

      // 检查是否有外部存储权限
      _deviceIdentifierPlugin.hasExternalStoragePermission().then((value) {
        print('Has External Storage Permission: $value');
      });

      // 请求外部存储权限（请求之前最好弹窗提示用户）
      _deviceIdentifierPlugin.requestExternalStoragePermission().then((value) {
        print('Requested External Storage Permission');
      });

      // 获取广告ID，需要谷歌服务的支持，并且需要添加相关权限
      // 在AndroidManifest.xml中添加：
      // <uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
      _deviceIdentifierPlugin.getAdvertisingIdForAndroid().then((value) {
        print('Advertising ID: $value');
      });

      // 获取Android ID，不一定会有值
      _deviceIdentifierPlugin.getAndroidId().then((value) {
        print('Android ID: $value');
      });
    }

    if (Platform.isIOS) {
      // 获取IDFA（广告追踪标识符）
      // 注意：需要在Info.plist中添加NSUserTrackingUsageDescription描述
      // 并且需要用户授权才能获取IDFA
      _deviceIdentifierPlugin.getAdvertisingIdForiOS().then((value) {
        print('IDFA: $value');
      });

      // 请求获取广告追踪授权
      // 注意：需要在Info.plist中添加NSUserTrackingUsageDescription描述
      // 返回的状态可能是 'authorized', 'denied', 'restricted', 'notDetermined'
      _deviceIdentifierPlugin.requestTrackingAuthorization().then((status) {
        print('Tracking Authorization Status: $status');
      });

      // 获取IDFV（应用内设备标识符）
      _deviceIdentifierPlugin.getAppleIDFV().then((value) {
        print('IDFV: $value');
      });

      // 获取Keychain UUID，如果没有生成过则返回null
      _deviceIdentifierPlugin.getKeychainUUID().then((value) {
        print('Keychain UUID: $value');
      });

      // 生成并返回Keychain UUID
      _deviceIdentifierPlugin.generateKeychainUUID().then((value) {
        print('Keychain UUID: $value');
      });

      // 是否存在Keychain UUID
      _deviceIdentifierPlugin.hasKeychainUUID().then((value) {
        print('Has Keychain UUID: $value');
      });
    }
  }

  // 获取所有设备信息
  Future<void> _getAllDeviceInfo(BuildContext ctx) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取最优标识符
      final bestId = await _deviceIdentifierPlugin.getBestDeviceIdentifier();
      print(
        'Best Device Identifier: runTimeType=${bestId.runtimeType}  value=$bestId',
      );

      // 获取支持的设备标识符
      final deviceId = await _deviceIdentifierPlugin.getSupportedIdentifiers();
      print(
        'Device Identifier: runTimeType=${deviceId.runtimeType}  value=$deviceId',
      );

      // 获取文件存储标识符（Android特有）
      String? fileId;
      if (Platform.isAndroid) {
        fileId = await _deviceIdentifierPlugin.generateFileDeviceIdentifier();
        print(
          'File-Based Device Identifier: runTimeType=${fileId.runtimeType}  value=$fileId',
        );
      }

      // 检查是否为模拟器
      final isEmulator = await _deviceIdentifierPlugin.isEmulator();
      print('Is Emulator: $isEmulator');

      // 获取设备信息
      final deviceInfo = await _deviceIdentifierPlugin.getDeviceInfo();
      print(
        'Device Info: runTimeType=${deviceInfo.runtimeType}  value=$deviceInfo',
      );

      setState(() {
        _bestIdentifier = bestId;
        _deviceIdentifier = deviceId;
        _fileBasedId = fileId;
        _isEmulator = isEmulator;
        _deviceInfo = deviceInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to get device info: $e', ctx);
    }
  }

  // 请求追踪授权（iOS特有）
  Future<void> _requestTrackingAuthorization(BuildContext ctx) async {
    if (!Platform.isIOS) {
      _showSnackBar('This feature is only available on iOS', ctx);
      return;
    }

    try {
      final status =
          await _deviceIdentifierPlugin.requestTrackingAuthorization();
      setState(() {
        _trackingAuthStatus = status;
        _showSnackBar(
          'Tracking authorization status: ${status ?? 'Unknown'}',
          ctx,
        );
      });
      // 重新获取设备信息以更新IDFA状态
      _getAllDeviceInfo(ctx);
    } catch (e) {
      setState(() {
        _showErrorDialog('Failed to request tracking authorization: $e', ctx);
      });
    }
  }

  /// 获取文件标识ID
  /// 仅在Android平台上有效
  void _getFileDeviceIdentifier(BuildContext ctx) async {
    try {
      if (!Platform.isAndroid) {
        _showSnackBar('This feature is only available on Android', ctx);
        return;
      }
      final result = await _deviceIdentifierPlugin.getFileDeviceIdentifier();
      if (result != null && result.isNotEmpty) {
        _showSnackBar('File-based ID: $result', ctx);
      } else {
        _showSnackBar('File-based ID is not available', ctx);
      }
      setState(() {
        _fileBasedId = result ?? 'Not available';
      });
    } catch (e) {
      _showErrorDialog('Failed to get file device identifier: $e', ctx);
    }
  }

  /// 请求Android平台的文件读写权限
  /// 仅在Android平台上有效
  void _requestExternalStoragePermission(BuildContext ctx) async {
    try {
      if (!Platform.isAndroid) {
        _showSnackBar('This feature is only available on Android', ctx);
        return;
      }
      final hasPermission =
          await _deviceIdentifierPlugin.hasExternalStoragePermission();
      if (hasPermission) {
        _showSnackBar("已经拥有文件读写权限", ctx);
        return;
      }
      // 用一个对话框提前提示用户需要请求权限
      _showRequestPermissionDialog(ctx);
    } catch (e) {
      _showErrorDialog('Failed to request permission: $e', ctx);
      return;
    }
  }

  /// 是否拥有文件读写权限
  /// 仅在Android平台上有效
  void _checkExternalStoragePermission(BuildContext ctx) async {
    try {
      if (!Platform.isAndroid) {
        _showSnackBar('This feature is only available on Android', ctx);
        return;
      }
      final hasPermission =
          await _deviceIdentifierPlugin.hasExternalStoragePermission();
      _showSnackBar(
        hasPermission
            ? 'Yes, I currently have permission'
            : "No, you don't have permission at this time",
        ctx,
      );
    } catch (e) {
      _showErrorDialog('Failed to check permission: $e', ctx);
    }
  }

  /// 删除Android下的文件存储ID
  /// 仅在Android平台上有效
  void _deleteFileDeviceIdentifier(BuildContext ctx) async {
    try {
      if (!Platform.isAndroid) {
        _showSnackBar('This feature is only available on Android', ctx);
        return;
      }
      final result = await _deviceIdentifierPlugin.deleteFileDeviceIdentifier();
      if (result) {
        _showSnackBar('File-based ID deleted successfully', ctx);
        _getAllDeviceInfo(ctx); // 重新获取信息
      } else {
        _showSnackBar('Failed to delete file-based ID', ctx);
      }
    } catch (e) {
      _showErrorDialog('Failed to delete file-based ID: $e', ctx);
    }
  }

  void _showSnackBar(String message, BuildContext ctx) {
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorDialog(String message, BuildContext ctx) {
    if (!mounted) return;
    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // 格式化设备标识符显示
  String _formatDeviceIdentifier() {
    final identifier = _deviceIdentifier;
    final lines = <String>[];

    if (Platform.isIOS) {
      // iOS 字段
      if (identifier.containsKey('iosDeviceID') &&
          identifier['iosDeviceID'] != null) {
        lines.add('iOS Device ID: ${identifier['iosDeviceID']}');
      }
      if (identifier.containsKey('idfv') && identifier['idfv'] != null) {
        lines.add('IDFV: ${identifier['idfv']}');
      }
      if (identifier.containsKey('idfa') && identifier['idfa'] != null) {
        lines.add('IDFA: ${identifier['idfa']}');
      }
      if (identifier.containsKey('keychainUUID') &&
          identifier['keychainUUID'] != null) {
        final keychainUUID = identifier['keychainUUID']!;
        lines.add('Keychain UUID: $keychainUUID');
      }
      if (identifier.containsKey('launchUUID') &&
          identifier['launchUUID'] != null) {
        final launchUUID = identifier['launchUUID']!;
        lines.add('Launch UUID: $launchUUID');
      }
    } else {
      // Android 字段
      if (identifier.containsKey('androidId') &&
          identifier['androidId'] != null) {
        lines.add('Android ID: ${identifier['androidId']}');
      }
      if (identifier.containsKey('advertisingId') &&
          identifier['advertisingId'] != null) {
        lines.add('Advertising ID: ${identifier['advertisingId']}');
      }
      if (identifier.containsKey('installUuid') &&
          identifier['installUuid'] != null) {
        lines.add('Install UUID: ${identifier['installUuid']}');
      }
      if (identifier.containsKey('buildSerial') &&
          identifier['buildSerial'] != null) {
        lines.add('Build Serial: ${identifier['buildSerial']}');
      }
    }

    // 通用字段
    if (identifier.containsKey('deviceFingerprint') &&
        identifier['deviceFingerprint'] != null) {
      lines.add('Device Fingerprint: ${identifier['deviceFingerprint']}');
    }
    if (identifier.containsKey('combinedId') &&
        identifier['combinedId'] != null) {
      lines.add('Combined ID: ${identifier['combinedId']}');
    }
    lines.add('Limit Ad Tracking: ${identifier['isLimitAdTrackingEnabled']}');

    return lines.isEmpty ? 'No identifiers available' : lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Identifier Plugin Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Device Identifier Plugin Example'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform: $_platformVersion',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      // 操作按钮
                      Builder(
                        builder: (ctx) {
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              // 获取所有设备信息
                              ElevatedButton(
                                onPressed: () {
                                  _getAllDeviceInfo(ctx);
                                },
                                child: const Text('获取所有设备信息'),
                              ),
                              // 删除Android下的文件存储ID
                              ElevatedButton(
                                onPressed: () {
                                  _deleteFileDeviceIdentifier(ctx);
                                },
                                child: const Text('删除文件存储标识符(Android)'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  _checkExternalStoragePermission(ctx);
                                },
                                child: const Text('是否有读写文件权限(Android)'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  _requestExternalStoragePermission(ctx);
                                },
                                child: const Text('请求读写文件权限(Android)'),
                              ),
                              // 获取文件ID
                              ElevatedButton(
                                onPressed: () async {
                                  _getFileDeviceIdentifier(ctx);
                                },
                                child: const Text('读取文件标识id(Android)'),
                              ),
                              if (Platform.isIOS) ...[
                                ElevatedButton(
                                  onPressed: () {
                                    _requestTrackingAuthorization(ctx);
                                  },
                                  child: const Text('请求获取广告追踪授权(iOS)'),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // iOS 追踪授权状态
                      if (Platform.isIOS && _trackingAuthStatus != null)
                        _buildInfoCard(
                          'Tracking Authorization Status',
                          _trackingAuthStatus!,
                          Icons.security,
                          _getTrackingAuthColor(_trackingAuthStatus!),
                        ),

                      // 最优标识符
                      _buildInfoCard(
                        'Best Identifier',
                        _bestIdentifier.isEmpty
                            ? 'Tap "Get All Info" to load'
                            : _bestIdentifier,
                        Icons.star,
                        Colors.orange,
                      ),

                      // 设备标识符详情
                      _buildInfoCard(
                        'Device Identifiers',
                        _formatDeviceIdentifier(),
                        Icons.fingerprint,
                        Colors.blue,
                      ),

                      // 文件存储ID（仅Android）
                      if (Platform.isAndroid)
                        _buildInfoCard(
                          'File-Based ID (Android)',
                          _fileBasedId ?? 'Not available or not loaded',
                          Icons.folder,
                          Colors.green,
                        ),

                      // 模拟器检测
                      _buildInfoCard(
                        'Device Type',
                        _isEmulator ? 'Emulator/Simulator' : 'Real Device',
                        _isEmulator
                            ? Icons.computer
                            : (Platform.isIOS
                                ? Icons.phone_iphone
                                : Icons.phone_android),
                        _isEmulator ? Colors.red : Colors.green,
                      ),

                      // 设备信息
                      _buildInfoCard(
                        'Device Information',
                        _deviceInfo.isEmpty
                            ? 'Tap "Get All Info" to load'
                            : _deviceInfo.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('\n'),
                        Icons.info,
                        Colors.purple,
                      ),

                      // 权限状态
                      // _buildInfoCard(
                      //   'Permission Status',
                      //   _permissions.isEmpty
                      //       ? 'Tap "Get All Info" to load'
                      //       : _permissions.entries
                      //           .map((e) => '${e.key}: ${e.value}')
                      //           .join('\n'),
                      //   Icons.security,
                      //   Colors.amber,
                      // ),

                      // 存储策略（仅Android）
                      // if (Platform.isAndroid && _storageStrategy.isNotEmpty)
                      //   _buildInfoCard(
                      //     'Storage Strategy (Android)',
                      //     _storageStrategy.entries
                      //         .map((e) => '${e.key}: ${e.value}')
                      //         .join('\n'),
                      //     Icons.storage,
                      //     Colors.teal,
                      //   ),

                      // // 文件存储信息（仅Android）
                      // if (Platform.isAndroid && _fileStorageInfo.isNotEmpty)
                      //   _buildInfoCard(
                      //     'File Storage Info (Android)',
                      //     _fileStorageInfo.entries
                      //         .map((e) => '${e.key}: ${e.value}')
                      //         .join('\n'),
                      //     Icons.description,
                      //     Colors.brown,
                      //   ),
                    ],
                  ),
                ),
      ),
    );
  }

  // 获取追踪授权状态对应的颜色
  Color _getTrackingAuthColor(String status) {
    switch (status) {
      case 'authorized':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'restricted':
        return Colors.orange;
      case 'notDetermined':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            '提示',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '需要获取文件读写管理权限，以便生成用户识别ID，点击确定后开始请求权限。',
            style: TextStyle(fontSize: 15),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _deviceIdentifierPlugin
                    .requestExternalStoragePermission();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
