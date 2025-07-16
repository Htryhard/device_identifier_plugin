package com.hicyh.device_identifier_plugin_example

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private lateinit var storagePermissionHelper: StoragePermissionHelper
    private var pendingResultCallback: ((Boolean, String) -> Unit)? = null
    
    companion object {
        private const val CHANNEL = "com.hicyh.device_identifier_plugin_example/storage_permission"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 初始化权限辅助类
        storagePermissionHelper = StoragePermissionHelper(this)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 设置方法通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkStoragePermissions" -> {
                    val permissions = storagePermissionHelper.checkStoragePermissions()
                    val permissionMap = permissions.mapValues { (_, status) ->
                        when (status) {
                            StoragePermissionHelper.Companion.PermissionStatus.GRANTED -> "granted"
                            StoragePermissionHelper.Companion.PermissionStatus.DENIED -> "denied"
                            StoragePermissionHelper.Companion.PermissionStatus.DENIED_FOREVER -> "denied_forever"
                            StoragePermissionHelper.Companion.PermissionStatus.NOT_REQUIRED -> "not_required"
                        }
                    }
                    result.success(permissionMap)
                }
                
                "requestStoragePermissions" -> {
                    pendingResultCallback = { granted, message ->
                        result.success(mapOf(
                            "granted" to granted,
                            "message" to message
                        ))
                    }
                    storagePermissionHelper.requestStoragePermissions()
                }
                
                "hasRequiredStoragePermissions" -> {
                    val hasPermissions = storagePermissionHelper.hasRequiredStoragePermissions()
                    result.success(hasPermissions)
                }
                
                "getPermissionStatusDescription" -> {
                    val description = storagePermissionHelper.getPermissionStatusDescription()
                    result.success(description)
                }
                
                "openAppSettings" -> {
                    storagePermissionHelper.openAppSettings()
                    result.success(null)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        storagePermissionHelper.onPermissionResult(requestCode, permissions, grantResults) { granted, message ->
            // 显示权限结果
            showToast(message)
            
            // 如果有待处理的回调，执行它
            pendingResultCallback?.invoke(granted, message)
            pendingResultCallback = null
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        storagePermissionHelper.onActivityResult(requestCode, resultCode, data) { granted, message ->
            // 显示权限结果
            showToast(message)
            
            // 如果有待处理的回调，执行它
            pendingResultCallback?.invoke(granted, message)
            pendingResultCallback = null
        }
    }
    
    /**
     * 显示Toast消息
     */
    private fun showToast(message: String) {
        runOnUiThread {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
        }
    }
}
