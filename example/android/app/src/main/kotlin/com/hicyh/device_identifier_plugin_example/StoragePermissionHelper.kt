package com.hicyh.device_identifier_plugin_example

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * 存储权限辅助类
 * 适配不同Android版本的存储权限请求
 */
class StoragePermissionHelper(private val activity: Activity) {
    
    companion object {
        // 权限请求码
        const val REQUEST_CODE_WRITE_EXTERNAL_STORAGE = 1001
        const val REQUEST_CODE_READ_EXTERNAL_STORAGE = 1002
        const val REQUEST_CODE_MANAGE_EXTERNAL_STORAGE = 1003
        const val REQUEST_CODE_MULTIPLE_PERMISSIONS = 1004
        
        // 权限状态
        enum class PermissionStatus {
            GRANTED,           // 已授权
            DENIED,            // 拒绝
            DENIED_FOREVER,    // 永久拒绝
            NOT_REQUIRED       // 不需要此权限
        }
    }
    
    /**
     * 检查存储权限状态
     */
    fun checkStoragePermissions(): Map<String, PermissionStatus> {
        val result = mutableMapOf<String, PermissionStatus>()
        
        when {
            // Android 13+ (API 33+)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                // 检查新的媒体权限
                result["READ_MEDIA_IMAGES"] = checkPermission(Manifest.permission.READ_MEDIA_IMAGES)
                result["READ_MEDIA_VIDEO"] = checkPermission(Manifest.permission.READ_MEDIA_VIDEO)
                result["READ_MEDIA_AUDIO"] = checkPermission(Manifest.permission.READ_MEDIA_AUDIO)
                
                // 检查管理外部存储权限
                result["MANAGE_EXTERNAL_STORAGE"] = if (Environment.isExternalStorageManager()) {
                    PermissionStatus.GRANTED
                } else {
                    PermissionStatus.DENIED
                }
            }
            
            // Android 11+ (API 30+)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                // 检查管理外部存储权限
                result["MANAGE_EXTERNAL_STORAGE"] = if (Environment.isExternalStorageManager()) {
                    PermissionStatus.GRANTED
                } else {
                    PermissionStatus.DENIED
                }
                
                // 传统权限仍然检查
                result["READ_EXTERNAL_STORAGE"] = checkPermission(Manifest.permission.READ_EXTERNAL_STORAGE)
                result["WRITE_EXTERNAL_STORAGE"] = checkPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
            
            // Android 6.0+ (API 23+)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                result["READ_EXTERNAL_STORAGE"] = checkPermission(Manifest.permission.READ_EXTERNAL_STORAGE)
                result["WRITE_EXTERNAL_STORAGE"] = checkPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
            
            // Android 6.0以下
            else -> {
                result["READ_EXTERNAL_STORAGE"] = PermissionStatus.GRANTED
                result["WRITE_EXTERNAL_STORAGE"] = PermissionStatus.GRANTED
            }
        }
        
        return result
    }
    
    /**
     * 检查单个权限状态
     */
    private fun checkPermission(permission: String): PermissionStatus {
        return when {
            ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED -> {
                PermissionStatus.GRANTED
            }
            
            ActivityCompat.shouldShowRequestPermissionRationale(activity, permission) -> {
                PermissionStatus.DENIED
            }
            
            else -> {
                PermissionStatus.DENIED_FOREVER
            }
        }
    }
    
    /**
     * 请求存储权限
     */
    fun requestStoragePermissions() {
        when {
            // Android 13+ (API 33+)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                requestMediaPermissions()
            }
            
            // Android 11+ (API 30+)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                requestManageExternalStoragePermission()
            }
            
            // Android 6.0+ (API 23+)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                requestLegacyStoragePermissions()
            }
            
            // Android 6.0以下不需要请求权限
            else -> {
                // 权限已经在安装时授予
            }
        }
    }
    
    /**
     * 请求Android 13+的媒体权限
     */
    private fun requestMediaPermissions() {
        val permissions = arrayOf(
            Manifest.permission.READ_MEDIA_IMAGES,
            Manifest.permission.READ_MEDIA_VIDEO,
            Manifest.permission.READ_MEDIA_AUDIO
        )
        
        ActivityCompat.requestPermissions(
            activity,
            permissions,
            REQUEST_CODE_MULTIPLE_PERMISSIONS
        )
    }
    
    /**
     * 请求Android 11+的管理外部存储权限
     */
    private fun requestManageExternalStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                try {
                    val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                    intent.addCategory("android.intent.category.DEFAULT")
                    intent.data = Uri.parse("package:${activity.packageName}")
                    activity.startActivityForResult(intent, REQUEST_CODE_MANAGE_EXTERNAL_STORAGE)
                } catch (e: Exception) {
                    // 如果无法打开特定应用的设置页面，打开通用设置页面
                    val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                    activity.startActivityForResult(intent, REQUEST_CODE_MANAGE_EXTERNAL_STORAGE)
                }
            }
        }
    }
    
    /**
     * 请求传统存储权限
     */
    private fun requestLegacyStoragePermissions() {
        val permissions = arrayOf(
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        )
        
        ActivityCompat.requestPermissions(
            activity,
            permissions,
            REQUEST_CODE_MULTIPLE_PERMISSIONS
        )
    }
    
    /**
     * 处理权限请求结果
     */
    fun onPermissionResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
        callback: (Boolean, String) -> Unit
    ) {
        when (requestCode) {
            REQUEST_CODE_MULTIPLE_PERMISSIONS -> {
                val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                if (allGranted) {
                    callback(true, "存储权限已授予")
                } else {
                    val deniedPermissions = permissions.filterIndexed { index, _ ->
                        grantResults[index] != PackageManager.PERMISSION_GRANTED
                    }
                    callback(false, "以下权限被拒绝: ${deniedPermissions.joinToString(", ")}")
                }
            }
            
            REQUEST_CODE_WRITE_EXTERNAL_STORAGE -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    callback(true, "写入外部存储权限已授予")
                } else {
                    callback(false, "写入外部存储权限被拒绝")
                }
            }
            
            REQUEST_CODE_READ_EXTERNAL_STORAGE -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    callback(true, "读取外部存储权限已授予")
                } else {
                    callback(false, "读取外部存储权限被拒绝")
                }
            }
        }
    }
    
    /**
     * 处理ActivityResult（用于管理外部存储权限）
     */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?, callback: (Boolean, String) -> Unit) {
        if (requestCode == REQUEST_CODE_MANAGE_EXTERNAL_STORAGE) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (Environment.isExternalStorageManager()) {
                    callback(true, "管理外部存储权限已授予")
                } else {
                    callback(false, "管理外部存储权限被拒绝")
                }
            }
        }
    }
    
    /**
     * 检查是否有足够的存储权限
     */
    fun hasRequiredStoragePermissions(): Boolean {
        return when {
            // Android 13+
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                Environment.isExternalStorageManager() || 
                hasLegacyStoragePermissions()
            }
            
            // Android 11+
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                Environment.isExternalStorageManager() || 
                hasLegacyStoragePermissions()
            }
            
            // Android 6.0+
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                hasLegacyStoragePermissions()
            }
            
            // Android 6.0以下
            else -> true
        }
    }
    
    /**
     * 检查是否有传统存储权限
     */
    private fun hasLegacyStoragePermissions(): Boolean {
        return ContextCompat.checkSelfPermission(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED &&
               ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
    }
    
    /**
     * 打开应用设置页面
     */
    fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        intent.data = Uri.parse("package:${activity.packageName}")
        activity.startActivity(intent)
    }
    
    /**
     * 获取权限状态描述
     */
    fun getPermissionStatusDescription(): String {
        val permissions = checkStoragePermissions()
        val sb = StringBuilder()
        
        sb.append("Android 版本: API ${Build.VERSION.SDK_INT}\n")
        sb.append("存储权限状态:\n")
        
        permissions.forEach { (permission, status) ->
            sb.append("  $permission: ${getStatusText(status)}\n")
        }
        
        return sb.toString()
    }
    
    /**
     * 获取权限状态文本
     */
    private fun getStatusText(status: PermissionStatus): String {
        return when (status) {
            PermissionStatus.GRANTED -> "已授权"
            PermissionStatus.DENIED -> "已拒绝"
            PermissionStatus.DENIED_FOREVER -> "永久拒绝"
            PermissionStatus.NOT_REQUIRED -> "不需要"
        }
    }
} 