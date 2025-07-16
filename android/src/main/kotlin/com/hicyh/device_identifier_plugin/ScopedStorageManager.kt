package com.hicyh.device_identifier_plugin

import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.util.*

/**
 * 分区存储管理器
 * 专门处理Android 10+的分区存储，提供更好的跨版本兼容性
 */
class ScopedStorageManager(private val context: Context) {
    
    companion object {
        private const val TAG = "ScopedStorageManager"
        private const val DEVICE_IDENTIFIER_FOLDER = "DeviceIdentifier"
        private const val DEVICE_ID_FILENAME = "device_id.txt"
        private const val BACKUP_FILENAME = "device_id_backup.txt"
    }
    
    /**
     * 存储策略枚举
     */
    enum class StorageStrategy {
        APP_SPECIFIC_STORAGE,      // 应用特定存储（Android 10+推荐）
        LEGACY_EXTERNAL_STORAGE,   // 传统外部存储
        SCOPED_STORAGE,            // 分区存储
        MEDIA_STORE,               // MediaStore API
        DOCUMENT_PROVIDER          // 文档提供器
    }
    
    /**
     * 存储结果
     */
    data class StorageResult(
        val success: Boolean,
        val deviceId: String?,
        val strategy: StorageStrategy,
        val path: String?,
        val error: String?
    )
    
    /**
     * 根据Android版本选择最佳存储策略
     */
    private fun getBestStorageStrategy(): StorageStrategy {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                // Android 10+ 优先使用应用特定存储
                if (hasManageExternalStoragePermission()) {
                    StorageStrategy.SCOPED_STORAGE
                } else {
                    StorageStrategy.APP_SPECIFIC_STORAGE
                }
            }
            else -> {
                StorageStrategy.LEGACY_EXTERNAL_STORAGE
            }
        }
    }
    
    /**
     * 检查是否有管理外部存储权限
     */
    private fun hasManageExternalStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }
    }
    
    /**
     * 获取或创建设备标识符（多策略尝试）
     */
    suspend fun getOrCreateDeviceIdentifier(): StorageResult {
        return withContext(Dispatchers.IO) {
            // 尝试多种存储策略
            val strategies = listOf(
                StorageStrategy.APP_SPECIFIC_STORAGE,
                StorageStrategy.SCOPED_STORAGE,
                StorageStrategy.LEGACY_EXTERNAL_STORAGE,
                StorageStrategy.MEDIA_STORE
            )
            
            for (strategy in strategies) {
                try {
                    val result = getDeviceIdentifierWithStrategy(strategy)
                    if (result.success) {
                        return@withContext result
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Strategy $strategy failed", e)
                }
            }
            
            // 如果所有策略都失败，生成一个新的UUID
            val fallbackId = UUID.randomUUID().toString()
            StorageResult(
                success = true,
                deviceId = fallbackId,
                strategy = StorageStrategy.APP_SPECIFIC_STORAGE,
                path = null,
                error = "使用fallback策略生成UUID"
            )
        }
    }
    
    /**
     * 使用特定策略获取设备标识符
     */
    private suspend fun getDeviceIdentifierWithStrategy(strategy: StorageStrategy): StorageResult {
        return when (strategy) {
            StorageStrategy.APP_SPECIFIC_STORAGE -> getFromAppSpecificStorage()
            StorageStrategy.SCOPED_STORAGE -> getFromScopedStorage()
            StorageStrategy.LEGACY_EXTERNAL_STORAGE -> getFromLegacyExternalStorage()
            StorageStrategy.MEDIA_STORE -> getFromMediaStore()
            StorageStrategy.DOCUMENT_PROVIDER -> getFromDocumentProvider()
        }
    }
    
    /**
     * 应用特定存储策略（Android 10+推荐）
     */
    private suspend fun getFromAppSpecificStorage(): StorageResult {
        return withContext(Dispatchers.IO) {
            try {
                // 使用应用特定的外部存储目录
                val externalFilesDir = context.getExternalFilesDir(null)
                if (externalFilesDir == null) {
                    return@withContext StorageResult(
                        success = false,
                        deviceId = null,
                        strategy = StorageStrategy.APP_SPECIFIC_STORAGE,
                        path = null,
                        error = "无法获取应用特定存储目录"
                    )
                }
                
                val deviceIdFolder = File(externalFilesDir, DEVICE_IDENTIFIER_FOLDER)
                if (!deviceIdFolder.exists()) {
                    deviceIdFolder.mkdirs()
                }
                
                val deviceIdFile = File(deviceIdFolder, DEVICE_ID_FILENAME)
                
                // 尝试读取现有标识符
                if (deviceIdFile.exists()) {
                    val existingId = deviceIdFile.readText().trim()
                    if (existingId.isNotEmpty()) {
                        return@withContext StorageResult(
                            success = true,
                            deviceId = existingId,
                            strategy = StorageStrategy.APP_SPECIFIC_STORAGE,
                            path = deviceIdFile.absolutePath,
                            error = null
                        )
                    }
                }
                
                // 生成新的标识符
                val newId = generateDeviceId()
                deviceIdFile.writeText(newId)
                
                // 创建备份文件
                val backupFile = File(deviceIdFolder, BACKUP_FILENAME)
                backupFile.writeText(newId)
                
                StorageResult(
                    success = true,
                    deviceId = newId,
                    strategy = StorageStrategy.APP_SPECIFIC_STORAGE,
                    path = deviceIdFile.absolutePath,
                    error = null
                )
                
            } catch (e: Exception) {
                Log.e(TAG, "应用特定存储失败", e)
                StorageResult(
                    success = false,
                    deviceId = null,
                    strategy = StorageStrategy.APP_SPECIFIC_STORAGE,
                    path = null,
                    error = e.message
                )
            }
        }
    }
    
    /**
     * 分区存储策略（Android 10+）
     */
    private suspend fun getFromScopedStorage(): StorageResult {
        return withContext(Dispatchers.IO) {
            try {
                if (!hasManageExternalStoragePermission()) {
                    return@withContext StorageResult(
                        success = false,
                        deviceId = null,
                        strategy = StorageStrategy.SCOPED_STORAGE,
                        path = null,
                        error = "没有管理外部存储权限"
                    )
                }
                
                // 使用外部存储根目录
                val externalStorageDir = Environment.getExternalStorageDirectory()
                val deviceIdFolder = File(externalStorageDir, DEVICE_IDENTIFIER_FOLDER)
                
                if (!deviceIdFolder.exists()) {
                    deviceIdFolder.mkdirs()
                }
                
                val deviceIdFile = File(deviceIdFolder, DEVICE_ID_FILENAME)
                
                // 尝试读取现有标识符
                if (deviceIdFile.exists()) {
                    val existingId = deviceIdFile.readText().trim()
                    if (existingId.isNotEmpty()) {
                        return@withContext StorageResult(
                            success = true,
                            deviceId = existingId,
                            strategy = StorageStrategy.SCOPED_STORAGE,
                            path = deviceIdFile.absolutePath,
                            error = null
                        )
                    }
                }
                
                // 生成新的标识符
                val newId = generateDeviceId()
                deviceIdFile.writeText(newId)
                
                StorageResult(
                    success = true,
                    deviceId = newId,
                    strategy = StorageStrategy.SCOPED_STORAGE,
                    path = deviceIdFile.absolutePath,
                    error = null
                )
                
            } catch (e: Exception) {
                Log.e(TAG, "分区存储失败", e)
                StorageResult(
                    success = false,
                    deviceId = null,
                    strategy = StorageStrategy.SCOPED_STORAGE,
                    path = null,
                    error = e.message
                )
            }
        }
    }
    
    /**
     * 传统外部存储策略（Android 9及以下）
     */
    private suspend fun getFromLegacyExternalStorage(): StorageResult {
        return withContext(Dispatchers.IO) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    // Android 10+ 不建议使用传统外部存储
                    return@withContext StorageResult(
                        success = false,
                        deviceId = null,
                        strategy = StorageStrategy.LEGACY_EXTERNAL_STORAGE,
                        path = null,
                        error = "Android 10+ 不支持传统外部存储"
                    )
                }
                
                val externalStorageDir = Environment.getExternalStorageDirectory()
                val deviceIdFolder = File(externalStorageDir, DEVICE_IDENTIFIER_FOLDER)
                
                if (!deviceIdFolder.exists()) {
                    deviceIdFolder.mkdirs()
                }
                
                val deviceIdFile = File(deviceIdFolder, DEVICE_ID_FILENAME)
                
                // 尝试读取现有标识符
                if (deviceIdFile.exists()) {
                    val existingId = deviceIdFile.readText().trim()
                    if (existingId.isNotEmpty()) {
                        return@withContext StorageResult(
                            success = true,
                            deviceId = existingId,
                            strategy = StorageStrategy.LEGACY_EXTERNAL_STORAGE,
                            path = deviceIdFile.absolutePath,
                            error = null
                        )
                    }
                }
                
                // 生成新的标识符
                val newId = generateDeviceId()
                deviceIdFile.writeText(newId)
                
                StorageResult(
                    success = true,
                    deviceId = newId,
                    strategy = StorageStrategy.LEGACY_EXTERNAL_STORAGE,
                    path = deviceIdFile.absolutePath,
                    error = null
                )
                
            } catch (e: Exception) {
                Log.e(TAG, "传统外部存储失败", e)
                StorageResult(
                    success = false,
                    deviceId = null,
                    strategy = StorageStrategy.LEGACY_EXTERNAL_STORAGE,
                    path = null,
                    error = e.message
                )
            }
        }
    }
    
    /**
     * MediaStore策略（Android 10+）
     */
    private suspend fun getFromMediaStore(): StorageResult {
        return withContext(Dispatchers.IO) {
            try {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    return@withContext StorageResult(
                        success = false,
                        deviceId = null,
                        strategy = StorageStrategy.MEDIA_STORE,
                        path = null,
                        error = "Android 10以下不支持MediaStore策略"
                    )
                }
                
                // 使用MediaStore保存文件
                val contentValues = android.content.ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, DEVICE_ID_FILENAME)
                    put(MediaStore.MediaColumns.MIME_TYPE, "text/plain")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOCUMENTS + "/$DEVICE_IDENTIFIER_FOLDER")
                }
                
                val resolver = context.contentResolver
                val uri = resolver.insert(MediaStore.Files.getContentUri("external"), contentValues)
                
                if (uri != null) {
                    try {
                        // 尝试读取现有文件
                        val inputStream = resolver.openInputStream(uri)
                        if (inputStream != null) {
                            val existingId = inputStream.bufferedReader().readText().trim()
                            inputStream.close()
                            
                            if (existingId.isNotEmpty()) {
                                return@withContext StorageResult(
                                    success = true,
                                    deviceId = existingId,
                                    strategy = StorageStrategy.MEDIA_STORE,
                                    path = uri.toString(),
                                    error = null
                                )
                            }
                        }
                    } catch (e: Exception) {
                        // 文件可能不存在，继续创建新的
                    }
                    
                    // 生成新的标识符并保存
                    val newId = generateDeviceId()
                    val outputStream = resolver.openOutputStream(uri)
                    if (outputStream != null) {
                        outputStream.write(newId.toByteArray())
                        outputStream.close()
                        
                        return@withContext StorageResult(
                            success = true,
                            deviceId = newId,
                            strategy = StorageStrategy.MEDIA_STORE,
                            path = uri.toString(),
                            error = null
                        )
                    }
                }
                
                StorageResult(
                    success = false,
                    deviceId = null,
                    strategy = StorageStrategy.MEDIA_STORE,
                    path = null,
                    error = "无法使用MediaStore创建文件"
                )
                
            } catch (e: Exception) {
                Log.e(TAG, "MediaStore存储失败", e)
                StorageResult(
                    success = false,
                    deviceId = null,
                    strategy = StorageStrategy.MEDIA_STORE,
                    path = null,
                    error = e.message
                )
            }
        }
    }
    
    /**
     * 文档提供器策略（最后的备选方案）
     */
    private suspend fun getFromDocumentProvider(): StorageResult {
        return withContext(Dispatchers.IO) {
            try {
                // 这个策略需要用户交互，通常不适合后台使用
                // 这里只是提供接口，实际使用时需要用户选择目录
                StorageResult(
                    success = false,
                    deviceId = null,
                    strategy = StorageStrategy.DOCUMENT_PROVIDER,
                    path = null,
                    error = "文档提供器策略需要用户交互"
                )
            } catch (e: Exception) {
                Log.e(TAG, "文档提供器失败", e)
                StorageResult(
                    success = false,
                    deviceId = null,
                    strategy = StorageStrategy.DOCUMENT_PROVIDER,
                    path = null,
                    error = e.message
                )
            }
        }
    }
    
    /**
     * 生成设备标识符
     */
    private fun generateDeviceId(): String {
        val sb = StringBuilder()
        sb.append(System.currentTimeMillis())
        sb.append("-")
        sb.append(Build.MANUFACTURER)
        sb.append("-")
        sb.append(Build.MODEL)
        sb.append("-")
        sb.append(UUID.randomUUID().toString())
        
        return sb.toString()
    }
    
    /**
     * 删除设备标识符文件
     */
    suspend fun deleteDeviceIdentifier(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // 尝试删除应用特定存储中的文件
                val externalFilesDir = context.getExternalFilesDir(null)
                if (externalFilesDir != null) {
                    val deviceIdFolder = File(externalFilesDir, DEVICE_IDENTIFIER_FOLDER)
                    if (deviceIdFolder.exists()) {
                        deviceIdFolder.deleteRecursively()
                    }
                }
                
                // 如果有权限，也删除外部存储中的文件
                if (hasManageExternalStoragePermission()) {
                    val externalStorageDir = Environment.getExternalStorageDirectory()
                    val deviceIdFolder = File(externalStorageDir, DEVICE_IDENTIFIER_FOLDER)
                    if (deviceIdFolder.exists()) {
                        deviceIdFolder.deleteRecursively()
                    }
                }
                
                true
            } catch (e: Exception) {
                Log.e(TAG, "删除设备标识符失败", e)
                false
            }
        }
    }
    
    /**
     * 获取存储策略信息
     */
    fun getStorageStrategyInfo(): Map<String, Any> {
        val bestStrategy = getBestStorageStrategy()
        
        return mapOf(
            "android_version" to Build.VERSION.SDK_INT,
            "best_strategy" to bestStrategy.name,
            "has_manage_external_storage" to hasManageExternalStoragePermission(),
            "external_storage_state" to Environment.getExternalStorageState(),
            "app_specific_storage_available" to (context.getExternalFilesDir(null) != null),
            "strategies_available" to listOf(
                StorageStrategy.APP_SPECIFIC_STORAGE.name,
                StorageStrategy.SCOPED_STORAGE.name,
                StorageStrategy.LEGACY_EXTERNAL_STORAGE.name,
                StorageStrategy.MEDIA_STORE.name
            )
        )
    }
} 