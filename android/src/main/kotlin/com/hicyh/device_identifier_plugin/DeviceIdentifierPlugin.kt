package com.hicyh.device_identifier_plugin

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.widget.Toast
import androidx.core.content.ContextCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
//import com.hjq.permissions.XXPermissions
//import com.hjq.permissions.permission.PermissionLists
//import com.hjq.permissions.permission.base.IPermission
//import com.hjq.permissions.OnPermissionCallback

/** DeviceIdentifierPlugin */
class DeviceIdentifierPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private lateinit var deviceIdentifierManager: DeviceIdentifierManager
  private var activity: Activity? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    deviceIdentifierManager = DeviceIdentifierManager.getInstance(context)
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.hicyh.device_identifier_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "getSupportedIdentifiers" -> {
        // 使用 IO 调度器处理耗时操作，然后切换到主线程返回结果
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val deviceIdentifier = deviceIdentifierManager.getDeviceIdentifier()
            val resultMap = mapOf(
              "androidId" to deviceIdentifier.androidId,
              "advertisingId" to deviceIdentifier.advertisingId,
              "installUuid" to deviceIdentifier.installUuid,
              "deviceFingerprint" to deviceIdentifier.deviceFingerprint,
              "buildSerial" to deviceIdentifier.buildSerial,
              "combinedId" to deviceIdentifier.combinedId,
              "isLimitAdTrackingEnabled" to deviceIdentifier.isLimitAdTrackingEnabled
            )
            // 切换到主线程返回结果
            withContext(Dispatchers.Main) {
              result.success(resultMap)
            }
          } catch (e: Exception) {
            // 切换到主线程返回错误
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to get device identifier: ${e.message}", null)
            }
          }
        }
      }
      "getAdvertisingIdForAndroid" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val advertisingResult = deviceIdentifierManager.getAdvertisingIdInfo()
            withContext(Dispatchers.Main) {
              result.success(advertisingResult.first)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to getAdvertisingIdForAndroid: ${e.message}", null)
            }
          }
        }
      }
      "getAndroidId" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val androidId = deviceIdentifierManager.getAndroidId()
            withContext(Dispatchers.Main) {
              result.success(androidId)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to get Android ID: ${e.message}", null)
            }
          }
        }
      }
      "getBestDeviceIdentifier" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val bestIdentifier = deviceIdentifierManager.getBestDeviceIdentifier()
            withContext(Dispatchers.Main) {
              result.success(bestIdentifier)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to get best device identifier: ${e.message}", null)
            }
          }
        }
      }
      "getFileDeviceIdentifier" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fileName = call.argument<String>("fileName") ?: "device_id.txt"
            val folderName = call.argument<String>("folderName") ?: "DeviceIdentifier"
            val fileBasedId = deviceIdentifierManager.getFileBasedDeviceIdentifier(fileName, folderName)
            withContext(Dispatchers.Main) {
              result.success(fileBasedId)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to get file based device identifier: ${e.message}", null)
            }
          }
        }
      }
      "generateFileDeviceIdentifier" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fileName = call.argument<String>("fileName") ?: "device_id.txt"
            val folderName = call.argument<String>("folderName") ?: "DeviceIdentifier"
            val fileBasedId = deviceIdentifierManager.generateFileDeviceIdentifier(fileName, folderName)
            withContext(Dispatchers.Main) {
              result.success(fileBasedId)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to get file based device identifier: ${e.message}", null)
            }
          }
        }
      }
      "deleteFileBasedDeviceIdentifier" -> {
        // 文件操作虽然相对较快，但仍然使用 IO 调度器保持一致性
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fileName = call.argument<String>("fileName") ?: "device_id.txt"
            val folderName = call.argument<String>("folderName") ?: "DeviceIdentifier"
            val deleted = deviceIdentifierManager.deleteFileBasedDeviceIdentifier(fileName, folderName)
            withContext(Dispatchers.Main) {
              result.success(deleted)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to delete file based device identifier: ${e.message}", null)
            }
          }
        }
      }
      "hasFileBasedDeviceIdentifier" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fileName = call.argument<String>("fileName") ?: "device_id.txt"
            val folderName = call.argument<String>("folderName") ?: "DeviceIdentifier"
            val exists = deviceIdentifierManager.hasFileBasedDeviceIdentifier(fileName, folderName)
            withContext(Dispatchers.Main) {
              result.success(exists)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to check file based device identifier: ${e.message}", null)
            }
          }
        }
      }
      "isEmulator" -> {
        // 这个操作比较快，可以直接在主线程执行，但为了一致性也使用协程
        CoroutineScope(Dispatchers.Default).launch {
          try {
            val isEmulator = deviceIdentifierManager.isEmulator()
            withContext(Dispatchers.Main) {
              result.success(isEmulator)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to check if device is emulator: ${e.message}", null)
            }
          }
        }
      }
      "getDeviceInfo" -> {
        CoroutineScope(Dispatchers.Default).launch {
          try {
            val deviceInfo = deviceIdentifierManager.getDeviceInfo()
            withContext(Dispatchers.Main) {
              result.success(deviceInfo)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to get device info: ${e.message}", null)
            }
          }
        }
      }
      "clearCachedIdentifiers" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            deviceIdentifierManager.clearCachedIdentifiers()
            withContext(Dispatchers.Main) {
              result.success(true)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to clear cached identifiers: ${e.message}", null)
            }
          }
        }
      }
      "getPermissionStatus" -> {
        CoroutineScope(Dispatchers.Default).launch {
          try {
            val permissionStatus = deviceIdentifierManager.getPermissionStatus()
            withContext(Dispatchers.Main) {
              result.success(permissionStatus)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to get permission status: ${e.message}", null)
            }
          }
        }
      }
      "getStorageStrategy" -> {
        CoroutineScope(Dispatchers.Default).launch {
          try {
            val storageStrategy = deviceIdentifierManager.getStorageStrategy()
            withContext(Dispatchers.Main) {
              result.success(storageStrategy)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to get storage strategy: ${e.message}", null)
            }
          }
        }
      }
      "getFileStorageInfo" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fileStorageInfo = deviceIdentifierManager.getFileStorageInfo()
            withContext(Dispatchers.Main) {
              result.success(fileStorageInfo)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("DEVICE_IDENTIFIER_ERROR", "Failed to get file storage info: ${e.message}", null)
            }
          }
        }
      }
      // 安卓请求外部存储权限
      "requestExternalStoragePermission" -> {
//        XXPermissions.with(context).permission(PermissionLists.getWriteExternalStoragePermission())
//          .request(object :OnPermissionCallback{
//          override fun onGranted(permissions: MutableList<IPermission>, allGranted: Boolean) {
//            // 获取权限成功
//          }
//            override fun onDenied(permissions: MutableList<IPermission>, doNotAskAgain: Boolean) {
//              super.onDenied(permissions, doNotAskAgain)
//              if (doNotAskAgain) {
//                // 被永久拒绝就跳转到应用权限系统设置页面
//                XXPermissions.startPermissionActivity(context, permissions)
//              }else{
//                // 获取权限失败
//              }
//            }
//        })
        if (activity != null){
          requestStoragePermission(activity!!)
          // 必须要有一个返回值
          result.success(null)
        }else{
          result.error("STORAGE_PERMISSION_ERROR", "Activity is null", null)
        }
      }
      "hasExternalStoragePermission" -> {
        result.success(hasStoragePermission())
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  // 检查是否有读写外部存储权限
  private fun hasStoragePermission(): Boolean {
//    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
//      // Android 11+ 检查 MANAGE_EXTERNAL_STORAGE 权限
//      android.provider.Settings.canDrawOverlays(context)
//    } else {
//      val writeGranted = android.content.pm.PackageManager.PERMISSION_GRANTED ==
//              context.checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
//      val readGranted = android.content.pm.PackageManager.PERMISSION_GRANTED ==
//              context.checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE)
//      writeGranted && readGranted
//    }
    return when {
      // Android 11+ 检查 MANAGE_EXTERNAL_STORAGE 权限
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
        val result = Environment.isExternalStorageManager()
        // Toast.makeText(context, "Android 11+ $result", Toast.LENGTH_SHORT).show()
        System.out.println("Android 11+ has storage permission: $result")
        return result
      }
      // Android 10 检查传统权限但考虑分区存储
      Build.VERSION.SDK_INT == Build.VERSION_CODES.Q -> {
//        Toast.makeText(context, "Android 10", Toast.LENGTH_SHORT).show()
        ContextCompat.checkSelfPermission(
          context,
          android.Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
      }
      // Android 6.0-9.0 检查传统权限
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
//        Toast.makeText(context, "Android 6~9", Toast.LENGTH_SHORT).show()
        ContextCompat.checkSelfPermission(
          context,
          android.Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
      }
      // Android 6.0以下不需要运行时权限
      else -> true
    }
  }

  // 请求读写外部存储权限（需在 Activity 中调用）
  private fun requestStoragePermission(activity: Activity, requestCode: Int = 1001) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      // Android 11+ 跳转到设置页面让用户授权“管理所有文件”
      val intent = android.content.Intent(android.provider.Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
      intent.data = android.net.Uri.parse("package:" + activity.packageName)
      activity.startActivity(intent)
    } else {
      // Android 10及以下，直接请求权限
      androidx.core.app.ActivityCompat.requestPermissions(
        activity,
        arrayOf(
          android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
          android.Manifest.permission.READ_EXTERNAL_STORAGE
        ),
        requestCode
      )
    }
  }


}
