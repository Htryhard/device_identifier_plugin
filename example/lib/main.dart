import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:device_identifier_plugin/device_identifier_plugin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DeviceIdentifierPlugin.instance.setAndroidFileStorage(
    androidFileName: 'device_id',
  );
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

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _deviceIdentifierPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
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

      // 获取完整设备标识符
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

  // 删除文件存储ID（Android特有）
  Future<void> _deleteFileBasedId(BuildContext ctx) async {
    if (!Platform.isAndroid) {
      _showSnackBar('This feature is only available on Android', ctx);
      return;
    }

    try {
      final success =
          await _deviceIdentifierPlugin.deleteFileDeviceIdentifier();
      _showSnackBar(
        success
            ? 'File-based ID deleted successfully'
            : 'Failed to delete file-based ID',
        ctx,
      );
      if (success) {
        _getAllDeviceInfo(ctx); // 重新获取信息
      }
    } catch (e) {
      _showErrorDialog('Failed to delete file-based ID: $e', ctx);
    }
  }

  void _showSnackBar(String message, BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorDialog(String message, BuildContext ctx) {
    print('Error: $message');
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
      title: 'Device Identifier Plugin Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Device Identifier Plugin Demo'),
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
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Builder(
                            builder: (ctx) {
                              return ElevatedButton(
                                onPressed: () {
                                  _getAllDeviceInfo(ctx);
                                },
                                child: const Text('Get All Info'),
                              );
                            },
                          ),
                          if (Platform.isAndroid) ...[
                            ElevatedButton(
                              onPressed: () {
                                _deleteFileBasedId(context);
                              },
                              child: const Text('Delete File ID'),
                            ),
                            Builder(
                              builder: (ctx) {
                                return ElevatedButton(
                                  onPressed: () async {
                                    final hasPermission =
                                        await _deviceIdentifierPlugin
                                            .hasExternalStoragePermission();
                                    _showSnackBar(
                                      hasPermission
                                          ? 'yes you get it'
                                          : 'no you do not get it',
                                      ctx,
                                    );
                                  },
                                  child: const Text('是否拥有读写文件权限'),
                                );
                              },
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await _deviceIdentifierPlugin
                                    .requestExternalStoragePermission();
                              },
                              child: const Text('请求读写文件权限'),
                            ),
                            // 获取文件ID
                            ElevatedButton(
                              onPressed: () async {
                                final result =
                                    await _deviceIdentifierPlugin
                                        .getFileDeviceIdentifier();
                                print("cyh --------> 获取文件ID: $result");
                                setState(() {
                                  _fileBasedId = result ?? 'Not available';
                                });
                              },
                              child: const Text('获取文件id'),
                            ),
                          ],
                          if (Platform.isIOS) ...[
                            ElevatedButton(
                              onPressed: () {
                                _requestTrackingAuthorization(context);
                              },
                              child: const Text('Request Tracking Auth'),
                            ),
                          ],
                        ],
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
}
