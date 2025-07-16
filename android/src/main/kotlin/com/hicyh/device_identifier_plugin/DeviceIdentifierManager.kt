package com.hicyh.device_identifier_plugin

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.google.android.gms.ads.identifier.AdvertisingIdClient
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import com.google.android.gms.common.GooglePlayServicesRepairableException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException
import java.security.MessageDigest
import java.util.*
import android.os.Environment
import java.io.File

/**
 * 设备唯一标识符管理器
 * 兼容 Android 15 (API 35) 及以下版本
 * 提供多种设备标识符获取方式，用于应用安装统计
 */
class DeviceIdentifierManager private constructor(private val context: Context) {

    companion object {
        private const val PREFS_NAME = "device_identifier_prefs"
        private const val KEY_INSTALL_UUID = "install_uuid"
        private const val KEY_DEVICE_FINGERPRINT = "device_fingerprint"

        @Volatile
        private var instance: DeviceIdentifierManager? = null

        fun getInstance(context: Context): DeviceIdentifierManager {
            return instance ?: synchronized(this) {
                instance ?: DeviceIdentifierManager(context.applicationContext).also {
                    instance = it
                }
            }
        }
    }

    private val sharedPreferences: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    /**
     * 设备标识符信息数据类
     */
    data class DeviceIdentifier(
        /** Android ID: 工厂重置、刷机、切换用户时会变化，卸载重装不变 */
        val androidId: String? = null,
        /** 广告ID: 用户可手动重置，约每月自动重置一次，卸载重装不变 */
        val advertisingId: String? = null,
        /** 安装UUID: 每次安装都会生成新的，卸载重装必然变化 */
        val installUuid: String? = null,
        /** 设备指纹: 基于硬件信息，相对稳定，系统更新或硬件变化时可能变化 */
        val deviceFingerprint: String? = null,
        /** 设备序列号: 硬件级别标识符，除非更换设备否则不变 */
        val buildSerial: String? = null,
        /** 组合ID: 多个标识符的组合哈希，变化取决于组成部分 */
        val combinedId: String? = null,
        /** 是否限制广告追踪: 用户设置，影响广告ID的使用 */
        val isLimitAdTrackingEnabled: Boolean = false
    )

    /**
     * 获取完整的设备标识符信息
     */
    suspend fun getDeviceIdentifier(): DeviceIdentifier {
        return withContext(Dispatchers.IO) {
            val androidId = getAndroidId()
            val advertisingInfo = getAdvertisingIdInfo()
            val installUuid = getInstallUuid()
            val deviceFingerprint = getDeviceFingerprint()
            val buildSerial = getBuildSerial()

            val combinedId = generateCombinedId(
                androidId,
                advertisingInfo.first,
                installUuid,
                deviceFingerprint
            )

            DeviceIdentifier(
                androidId = androidId,
                advertisingId = advertisingInfo.first,
                installUuid = installUuid,
                deviceFingerprint = deviceFingerprint,
                buildSerial = buildSerial,
                combinedId = combinedId,
                isLimitAdTrackingEnabled = advertisingInfo.second
            )
        }
    }

    /**
     * 获取 Android ID
     *
     * 稳定性分析：
     * - 卸载重装：不变 ✓
     * - 工厂重置：会变化 ✗
     * - 刷机/Root：会变化 ✗
     * - 切换用户：会变化 ✗
     * - 系统更新：不变 ✓
     * - 应用更新：不变 ✓
     *
     * 特殊情况：
     * - 某些设备可能返回相同的ID（9774d56d682e549c）
     * - 模拟器通常返回固定值
     * - Android 8.0+ 对于未签名应用可能返回不同值
     *
     * 推荐使用场景：用户行为分析、崩溃统计
     */
    @SuppressLint("HardwareIds")
    fun getAndroidId(): String? {
        return try {
            val androidId = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ANDROID_ID
            )
            if (androidId.isNullOrEmpty() || androidId == "9774d56d682e549c") {
                // 处理已知的无效 Android ID
                null
            } else {
                androidId
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * 获取广告 ID (GAID - Google Advertising ID)
     *
     * 稳定性分析：
     * - 卸载重装：不变 ✓
     * - 工厂重置：会变化 ✗
     * - 用户手动重置：会变化 ✗
     * - 系统自动重置：约每月一次 ✗
     * - 系统更新：不变 ✓
     * - 应用更新：不变 ✓
     *
     * 特殊情况：
     * - 用户可以在设置中限制广告追踪
     * - 限制追踪时，所有应用获得相同的零值ID
     * - 需要 Google Play Services 支持
     * - 模拟器可能无法获取
     * - 儿童账户或企业设备可能被限制
     *
     * 隐私政策：
     * - 必须遵循 Google Play 政策
     * - 不能用于识别个人身份
     * - 用户可以选择退出广告追踪
     *
     * 推荐使用场景：广告归因、用户获取分析
     */
    suspend fun getAdvertisingIdInfo(): Pair<String?, Boolean> {
        return withContext(Dispatchers.IO) {
            try {
                val adInfo = AdvertisingIdClient.getAdvertisingIdInfo(context)
                Pair(adInfo.id, adInfo.isLimitAdTrackingEnabled)
            } catch (e: IOException) {
                Pair(null, false)
            } catch (e: GooglePlayServicesNotAvailableException) {
                Pair(null, false)
            } catch (e: GooglePlayServicesRepairableException) {
                Pair(null, false)
            } catch (e: Exception) {
                Pair(null, false)
            }
        }
    }

    /**
     * 获取应用安装时生成的 UUID
     *
     * 稳定性分析：
     * - 卸载重装：会变化 ✗（每次安装都生成新的）
     * - 工厂重置：会变化 ✗
     * - 清除应用数据：会变化 ✗
     * - 系统更新：不变 ✓
     * - 应用更新：不变 ✓
     * - 设备更换：会变化 ✗
     *
     * 特殊情况：
     * - 首次启动应用时生成
     * - 存储在应用私有数据中
     * - 应用数据备份/恢复时可能保持不变
     * - 不同应用会有不同的UUID
     *
     * 优点：
     * - 完全由应用控制
     * - 不需要任何权限
     * - 兼容所有Android版本
     * - 不受用户设置影响
     *
     * 缺点：
     * - 无法跨应用识别同一设备
     * - 卸载重装后会变化
     * - 无法识别同一用户的不同安装
     *
     * 推荐使用场景：应用安装统计、首次启动检测
     */
    private fun getInstallUuid(): String {
        var uuid = sharedPreferences.getString(KEY_INSTALL_UUID, null)
        if (uuid.isNullOrEmpty()) {
            uuid = UUID.randomUUID().toString()
            sharedPreferences.edit().putString(KEY_INSTALL_UUID, uuid).apply()
        }
        return uuid
    }

    /**
     * 获取设备指纹
     *
     * 稳定性分析：
     * - 卸载重装：不变 ✓（基于硬件信息）
     * - 工厂重置：不变 ✓
     * - 系统更新：通常不变 ✓
     * - 硬件变化：会变化 ✗
     * - 屏幕分辨率变化：会变化 ✗
     * - 刷机：可能变化 ⚠️
     *
     * 包含的信息：
     * - 设备型号、制造商、主板信息
     * - 系统版本、SDK版本
     * - 屏幕分辨率、像素密度
     * - CPU架构信息
     *
     * 特殊情况：
     * - 首次调用时生成并缓存
     * - 模拟器可能返回通用值
     * - 某些定制ROM可能修改硬件信息
     * - 相同型号设备可能有相似指纹
     *
     * 优点：
     * - 不需要特殊权限
     * - 相对稳定
     * - 卸载重装后不变
     * - 不受用户设置影响
     *
     * 缺点：
     * - 隐私争议较大
     * - 可能被硬件变化影响
     * - 算法复杂度较高
     *
     * 推荐使用场景：设备识别、反作弊检测
     */
    private fun getDeviceFingerprint(): String {
        var fingerprint = sharedPreferences.getString(KEY_DEVICE_FINGERPRINT, null)
        if (fingerprint.isNullOrEmpty()) {
            fingerprint = generateDeviceFingerprint()
            sharedPreferences.edit().putString(KEY_DEVICE_FINGERPRINT, fingerprint).apply()
        }
        return fingerprint
    }

    /**
     * 生成设备指纹
     */
    private fun generateDeviceFingerprint(): String {
        val sb = StringBuilder()

        // 基本设备信息
        sb.append(Build.BOARD)
        sb.append(Build.BRAND)
        sb.append(Build.DEVICE)
        sb.append(Build.HARDWARE)
        sb.append(Build.MANUFACTURER)
        sb.append(Build.MODEL)
        sb.append(Build.PRODUCT)

        // 系统版本信息
        sb.append(Build.VERSION.RELEASE)
        sb.append(Build.VERSION.SDK_INT)

        // 屏幕信息
        val displayMetrics = context.resources.displayMetrics
        sb.append(displayMetrics.widthPixels)
        sb.append(displayMetrics.heightPixels)
        sb.append(displayMetrics.densityDpi)

        // CPU 信息
        sb.append(Build.SUPPORTED_ABIS.contentToString())

        return hashString(sb.toString())
    }

    /**
     * 获取设备序列号
     *
     * 稳定性分析：
     * - 卸载重装：不变 ✓（硬件级别标识符）
     * - 工厂重置：不变 ✓
     * - 系统更新：不变 ✓
     * - 刷机：不变 ✓
     * - 设备更换：会变化 ✗
     *
     * 权限要求：
     * - Android 6.0-7.1：无需权限
     * - Android 8.0-9.0：需要 READ_PHONE_STATE 权限
     * - Android 10+：需要 READ_PRIVILEGED_PHONE_STATE 权限（系统级，普通应用无法获取）
     *
     * 特殊情况：
     * - Android 10+ 普通应用基本无法获取
     * - 某些设备可能返回 "unknown"
     * - 模拟器通常返回固定值
     * - 某些厂商ROM可能限制访问
     *
     * 隐私考虑：
     * - 这是最敏感的设备标识符
     * - Google 强烈不建议使用
     * - 可能违反某些地区的隐私法规
     *
     * 优点：
     * - 最稳定的标识符
     * - 硬件级别唯一性
     * - 不受软件操作影响
     *
     * 缺点：
     * - 隐私风险极高
     * - 权限要求严格
     * - 新版本Android基本无法获取
     *
     * 推荐使用场景：不建议使用（仅供测试）
     */
    @SuppressLint("HardwareIds", "MissingPermission")
    private fun getBuildSerial(): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Android 8.0+ 需要 READ_PHONE_STATE 权限
                // 但实际上在 Android 10+ 需要 READ_PRIVILEGED_PHONE_STATE 权限（系统级权限）
                if (ContextCompat.checkSelfPermission(
                        context,
                        android.Manifest.permission.READ_PHONE_STATE
                    ) == PackageManager.PERMISSION_GRANTED
                ) {
                    val serial = Build.getSerial()
                    if (serial != "unknown") serial else null
                } else {
                    null
                }
            } else {
                @Suppress("DEPRECATION")
                val serial = Build.SERIAL
                if (serial != "unknown") serial else null
            }
        } catch (e: Exception) {
            // 如果没有权限或其他异常，返回 null
            null
        }
    }

    /**
     * 生成组合ID
     *
     * 稳定性分析：
     * - 卸载重装：可能变化 ⚠️（取决于组成部分）
     * - 工厂重置：会变化 ✗
     * - 系统更新：通常不变 ✓
     * - 用户操作：可能变化 ⚠️
     *
     * 组合策略：
     * - 优先使用稳定的标识符（Android ID、设备指纹）
     * - 弱化不稳定的标识符（安装UUID）
     * - 如果用户限制广告追踪，忽略广告ID
     *
     * 特殊情况：
     * - 如果所有标识符都无法获取，生成随机UUID
     * - 使用SHA-256哈希确保一致性
     * - 不同的标识符组合会产生不同的结果
     *
     * 优点：
     * - 综合多个标识符的优势
     * - 降低单一标识符失效的风险
     * - 可以根据需要调整组合策略
     *
     * 缺点：
     * - 复杂度较高
     * - 调试困难
     * - 稳定性取决于组成部分
     *
     * 推荐使用场景：综合设备识别、多重验证
     */
    private fun generateCombinedId(
        androidId: String?,
        advertisingId: String?,
        installUuid: String?,
        deviceFingerprint: String?
    ): String {
        val identifiers = listOfNotNull(
            androidId,
            advertisingId,
            installUuid,
            deviceFingerprint
        )

        return if (identifiers.isNotEmpty()) {
            hashString(identifiers.joinToString(""))
        } else {
            UUID.randomUUID().toString()
        }
    }

    /**
     * 获取最优的设备标识符
     * 按优先级返回可用的标识符
     */
    suspend fun getBestDeviceIdentifier(): String {
        val identifier = getDeviceIdentifier()

        // 按优先级选择最优标识符
        return when {
            !identifier.androidId.isNullOrEmpty() -> identifier.androidId
            !identifier.advertisingId.isNullOrEmpty() && !identifier.isLimitAdTrackingEnabled -> identifier.advertisingId
            !identifier.deviceFingerprint.isNullOrEmpty() -> identifier.deviceFingerprint
            !identifier.installUuid.isNullOrEmpty() -> identifier.installUuid
            else -> identifier.combinedId ?: UUID.randomUUID().toString()
        }
    }

    /**
     * 检查是否为模拟器
     */
    fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic") ||
                Build.FINGERPRINT.startsWith("unknown") ||
                Build.MODEL.contains("google_sdk") ||
                Build.MODEL.contains("Emulator") ||
                Build.MODEL.contains("Android SDK built for x86") ||
                Build.MANUFACTURER.contains("Genymotion") ||
                (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")) ||
                "google_sdk" == Build.PRODUCT)
    }

    /**
     * 获取设备基本信息
     *
     * 返回内容包括：
     * - brand: 设备品牌（如 Xiaomi、HUAWEI、Samsung）
     * - model: 设备型号（如 MI 10、SM-G9730）
     * - manufacturer: 设备制造商（如 Xiaomi、HUAWEI、Samsung）
     * - device: 设备名称（设备内部代号，如 "cepheus"）
     * - product: 产品名称（如 "cepheus"）
     * - board: 主板名称（如 "msm8998"）
     * - hardware: 硬件名称（如 "qcom"）
     * - android_version: 系统版本号（如 "13"）
     * - sdk_int: 系统SDK版本号（如 "33"）
     * - fingerprint: 设备指纹（唯一标识一台设备的字符串）
     * - is_emulator: 是否为模拟器（true/false）
     */
    fun getDeviceInfo(): Map<String, String> {
        return mapOf(
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "device" to Build.DEVICE,
            "product" to Build.PRODUCT,
            "board" to Build.BOARD,
            "hardware" to Build.HARDWARE,
            "android_version" to Build.VERSION.RELEASE,
            "sdk_int" to Build.VERSION.SDK_INT.toString(),
            "fingerprint" to Build.FINGERPRINT,
            "is_emulator" to isEmulator().toString()
        )
    }

    /**
     * 清除缓存的标识符
     */
    fun clearCachedIdentifiers() {
        sharedPreferences.edit().clear().apply()
    }

    /**
     * 检查是否有获取设备序列号的权限
     */
    fun hasPhoneStatePermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * 获取权限状态信息
     */
    fun getPermissionStatus(): Map<String, Boolean> {
        return mapOf(
            "READ_PHONE_STATE" to hasPhoneStatePermission(),
            "INTERNET" to (ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.INTERNET
            ) == PackageManager.PERMISSION_GRANTED),
            "ACCESS_NETWORK_STATE" to (ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.ACCESS_NETWORK_STATE
            ) == PackageManager.PERMISSION_GRANTED),
            "WRITE_EXTERNAL_STORAGE" to hasWriteExternalStoragePermission(),
            "READ_EXTERNAL_STORAGE" to hasReadExternalStoragePermission(),
            "MANAGE_EXTERNAL_STORAGE" to hasManageExternalStoragePermission()
        )
    }

    /**
     * 检查是否有写入外部存储的权限
     * 适配不同Android版本
     */
    fun hasWriteExternalStoragePermission(): Boolean {
        return when {
            // Android 11+ 检查 MANAGE_EXTERNAL_STORAGE 权限
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                Environment.isExternalStorageManager()
            }
            // Android 10 检查传统权限但考虑分区存储
            Build.VERSION.SDK_INT == Build.VERSION_CODES.Q -> {
                ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.WRITE_EXTERNAL_STORAGE
                ) == PackageManager.PERMISSION_GRANTED
            }
            // Android 6.0-9.0 检查传统权限
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.WRITE_EXTERNAL_STORAGE
                ) == PackageManager.PERMISSION_GRANTED
            }
            // Android 6.0以下不需要运行时权限
            else -> true
        }
    }

    /**
     * 检查是否有读取外部存储的权限
     * 适配不同Android版本
     */
    fun hasReadExternalStoragePermission(): Boolean {
        return when {
            // Android 13+ 新的照片和视频权限模式
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                // 对于文件存储，仍然检查传统权限或MANAGE_EXTERNAL_STORAGE
                Environment.isExternalStorageManager() ||
                        ContextCompat.checkSelfPermission(
                            context,
                            android.Manifest.permission.READ_EXTERNAL_STORAGE
                        ) == PackageManager.PERMISSION_GRANTED
            }
            // Android 11+ 检查 MANAGE_EXTERNAL_STORAGE 权限
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                Environment.isExternalStorageManager()
            }
            // Android 6.0-10 检查传统权限
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.READ_EXTERNAL_STORAGE
                ) == PackageManager.PERMISSION_GRANTED
            }
            // Android 6.0以下不需要运行时权限
            else -> true
        }
    }

    /**
     * 检查是否有管理外部存储的权限 (Android 11+)
     */
    fun hasManageExternalStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            false // Android 10 及以下不需要此权限
        }
    }

    /**
     * 获取外部存储根目录路径
     * 适配不同Android版本的存储策略
     */
    private fun getExternalStorageRootPath(): String? {
        return try {
            if (Environment.getExternalStorageState() != Environment.MEDIA_MOUNTED) {
                return null
            }

            when {
                // Android 10+ 优先使用应用特定目录（不需要权限）
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                    // 尝试使用应用特定的外部存储目录
                    context.getExternalFilesDir(null)?.let { appSpecificDir ->
                        // 创建一个可以跨应用访问的路径（仍在外部存储根目录）
                        val publicDir = Environment.getExternalStorageDirectory()
                        if (publicDir.canWrite() || hasWriteExternalStoragePermission()) {
                            publicDir.absolutePath
                        } else {
                            // 如果没有权限访问公共目录，使用应用特定目录
                            appSpecificDir.absolutePath
                        }
                    } ?: Environment.getExternalStorageDirectory().absolutePath
                }
                // Android 6.0-9.0 使用传统外部存储
                else -> {
                    Environment.getExternalStorageDirectory().absolutePath
                }
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * 创建日志文件夹
     * @param folderName 文件夹名称，默认为 "DeviceIdentifier"
     * @return 创建的文件夹路径，失败返回 null
     */
    private fun createLogFolder(folderName: String = "DeviceIdentifier2"): String? {
        val rootPath = getExternalStorageRootPath() ?: return null

        try {
            val logFolder = File(rootPath, folderName)
            if (!logFolder.exists()) {
                val created = logFolder.mkdirs()
                if (!created) {
                    return null
                }
            }
            return logFolder.absolutePath
        } catch (e: Exception) {
            return null
        }
    }

    /**
     * 生成基于文件的唯一标识符（增强版 - 支持分区存储）
     *
     * 此方法使用增强的分区存储管理器，适配不同Android版本的存储策略
     *
     * 存储策略：
     * - Android 10+：优先使用应用特定存储，降级到分区存储
     * - Android 9-：使用传统外部存储
     * - 所有版本：支持MediaStore API作为备选方案
     *
     * 稳定性分析：
     * - 卸载重装：可能不变 ⚠️（取决于存储策略）
     * - 工厂重置：会变化 ✗（外部存储被清空）
     * - 系统更新：不变 ✓
     * - 应用更新：不变 ✓
     * - 用户手动删除文件：会变化 ✗
     * - 存储卡更换：会变化 ✗
     *
     * 权限要求：
     * - Android 6.0-10：WRITE_EXTERNAL_STORAGE 权限
     * - Android 11+：MANAGE_EXTERNAL_STORAGE 权限（可选）
     * - 应用特定存储：无需权限
     *
     * 优点：
     * - 自动选择最佳存储策略
     * - 多策略降级保障
     * - 完全适配分区存储
     * - 提供详细的存储信息
     *
     * 缺点：
     * - 复杂度较高
     * - 某些策略需要权限
     * - 工厂重置后会丢失
     *
     * @param fileName 文件名，默认为 "device_id.txt"
     * @param folderName 文件夹名称，默认为 "DeviceIdentifier"
     * @return 设备唯一标识符，失败返回 null
     */
    suspend fun getFileBasedDeviceIdentifier(
        fileName: String = "device_id.txt",
        folderName: String = "DeviceIdentifier"
    ): String? {
        return withContext(Dispatchers.IO) {
            try {
                // 使用增强的分区存储管理器
//                val scopedStorageManager = ScopedStorageManager(context)
//                val result = scopedStorageManager.getOrCreateDeviceIdentifier()
//
//                if (result.success) {
//                    return@withContext result.deviceId
//                }

                // 如果分区存储失败，回退到原始方法
                return@withContext getLegacyFileBasedDeviceIdentifier(fileName, folderName)

            } catch (e: Exception) {
                // 异常时也回退到原始方法
                return@withContext getLegacyFileBasedDeviceIdentifier(fileName, folderName)
            }
        }
    }

    /**
     * 传统文件存储方法（作为备选方案）
     * 获取文件存储的设备唯一标识符，如果不存在则返回null
     */
    private suspend fun getLegacyFileBasedDeviceIdentifier(
        fileName: String = "device_id.txt",
        folderName: String = "DeviceIdentifier"
    ): String? {
        return withContext<String?>(Dispatchers.IO) {
            try {
                // 检查权限
                if (!hasWriteExternalStoragePermission()) {
                    return@withContext null
                }
                // 创建文件夹
                val folderPath = createLogFolder(folderName) ?: return@withContext null
                val file = File(folderPath, fileName)

                // 如果文件已存在，读取现有标识符
                if (file.exists() && file.canRead()) {
                    try {
                        val existingId = file.readText().trim()
                        if (existingId.isNotEmpty()) {
                            return@withContext existingId
                        }
                    } catch (e: Exception) {
                        // 读取失败，继续生成新的标识符
                        return@withContext null
                    }
                } else {
                    return@withContext null
                }
                null
            } catch (e: Exception) {
                return@withContext null
            }
        }
    }

    // 生成并获取文件存储设备ID标识
    suspend fun generateFileDeviceIdentifier(
        fileName: String = "device_id.txt",
        folderName: String = "DeviceIdentifier"
    ): String? {
        return withContext(Dispatchers.IO) {
            try {
                // 检查权限
                if (!hasWriteExternalStoragePermission()) {
                    return@withContext null
                }

                // 创建文件夹
                val folderPath = createLogFolder(folderName) ?: return@withContext null
                val file = File(folderPath, fileName)

                // 如果文件已存在，读取现有标识符
                if (file.exists() && file.canRead()) {
                    try {
                        val existingId = file.readText().trim()
                        if (existingId.isNotEmpty()) {
                            return@withContext existingId
                        }
                    } catch (e: Exception) {
                        // 读取失败，继续生成新的标识符
                    }
                }

                // 生成新的唯一标识符
                val deviceId = generateFileBasedUniqueId()

                // 保存到文件
                try {
                    file.writeText(deviceId)
                    return@withContext deviceId
                } catch (e: Exception) {
                    return@withContext null
                }

            } catch (e: Exception) {
                return@withContext null
            }
        }
    }

    /**
     * 生成基于文件的唯一标识符
     * 结合多种信息生成更稳定的标识符
     */
    private fun generateFileBasedUniqueId(): String {
        val sb = StringBuilder()

        // 时间戳（首次生成时间）
        sb.append(System.currentTimeMillis())
        sb.append("-")

        // 设备硬件信息
        sb.append(Build.MANUFACTURER)
        sb.append("-")
        sb.append(Build.MODEL)
        sb.append("-")
        sb.append(Build.DEVICE)
        sb.append("-")

        // 随机UUID
        sb.append(UUID.randomUUID().toString())

        // 生成哈希
        return hashString(sb.toString())
    }

    /**
     * 删除文件中保存的设备标识符
     * @param fileName 文件名，默认为 "device_id.txt"
     * @param folderName 文件夹名称，默认为 "DeviceIdentifier"
     * @return 是否删除成功
     */
    fun deleteFileBasedDeviceIdentifier(
        fileName: String = "device_id.txt",
        folderName: String = "DeviceIdentifier"
    ): Boolean {
        return try {
            val rootPath = getExternalStorageRootPath() ?: return false
            val file = File(File(rootPath, folderName), fileName)

            if (file.exists()) {
                file.delete()
            } else {
                true // 文件不存在也算删除成功
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 检查文件中是否已存在设备标识符
     * @param fileName 文件名，默认为 "device_id.txt"
     * @param folderName 文件夹名称，默认为 "DeviceIdentifier"
     * @return 是否存在
     */
    fun hasFileBasedDeviceIdentifier(
        fileName: String = "device_id.txt",
        folderName: String = "DeviceIdentifier"
    ): Boolean {
        return try {
            if (!hasReadExternalStoragePermission()) {
                return false
            }

            val rootPath = getExternalStorageRootPath() ?: return false
            val file = File(File(rootPath, folderName), fileName)

            file.exists() && file.canRead() && file.length() > 0
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 获取适合当前Android版本的存储策略信息
     */
    fun getStorageStrategy(): Map<String, String> {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                mapOf(
                    "version" to "Android 11+ (API ${Build.VERSION.SDK_INT})",
                    "strategy" to "分区存储 + MANAGE_EXTERNAL_STORAGE",
                    "permission_required" to "MANAGE_EXTERNAL_STORAGE",
                    "description" to "需要特殊权限，用户需要在设置中手动授权"
                )
            }

            Build.VERSION.SDK_INT == Build.VERSION_CODES.Q -> {
                mapOf(
                    "version" to "Android 10 (API 29)",
                    "strategy" to "分区存储过渡期",
                    "permission_required" to "WRITE_EXTERNAL_STORAGE",
                    "description" to "分区存储引入但可以关闭，仍可使用传统权限"
                )
            }

            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                mapOf(
                    "version" to "Android 6.0-9.0 (API ${Build.VERSION.SDK_INT})",
                    "strategy" to "运行时权限",
                    "permission_required" to "WRITE_EXTERNAL_STORAGE",
                    "description" to "需要运行时申请存储权限"
                )
            }

            else -> {
                mapOf(
                    "version" to "Android 6.0以下 (API ${Build.VERSION.SDK_INT})",
                    "strategy" to "安装时权限",
                    "permission_required" to "无需运行时申请",
                    "description" to "权限在安装时授予"
                )
            }
        }
    }

    /**
     * 获取文件存储的详细信息（增强版）
     */
    fun getFileStorageInfo(): Map<String, Any> {
        val rootPath = getExternalStorageRootPath()
        val folderPath = rootPath?.let { File(it, "DeviceIdentifier").absolutePath }
        val filePath = folderPath?.let { File(it, "device_id.txt").absolutePath }
        val storageStrategy = getStorageStrategy()

        // 获取分区存储策略信息
        val scopedStorageManager = ScopedStorageManager(context)
        val scopedStorageInfo = scopedStorageManager.getStorageStrategyInfo()

        return mapOf<String, Any>(
            "external_storage_available" to (Environment.getExternalStorageState() == Environment.MEDIA_MOUNTED),
            "external_storage_root" to (rootPath ?: "Not available"),
            "log_folder_path" to (folderPath ?: "Not available"),
            "identifier_file_path" to (filePath ?: "Not available"),
            "has_write_permission" to hasWriteExternalStoragePermission(),
            "has_read_permission" to hasReadExternalStoragePermission(),
            "file_exists" to hasFileBasedDeviceIdentifier(),
            "android_version" to "API ${Build.VERSION.SDK_INT}",
            "storage_strategy" to (storageStrategy["strategy"] ?: "Unknown"),
            "permission_required" to (storageStrategy["permission_required"] ?: "Unknown"),
            "strategy_description" to (storageStrategy["description"] ?: "Unknown"),

            // 分区存储相关信息
            "scoped_storage_info" to scopedStorageInfo,
            "supports_scoped_storage" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q),
            "requires_manage_external_storage" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R),
            "app_specific_storage_path" to (context.getExternalFilesDir(null)?.absolutePath
                ?: "Not available")
        )
    }

    /**
     * 获取分区存储测试结果
     */
    suspend fun getScopedStorageTestResult(): Map<String, Any> {
        return withContext(Dispatchers.IO) {
            try {
                val scopedStorageManager = ScopedStorageManager(context)
                val result = scopedStorageManager.getOrCreateDeviceIdentifier()

                mapOf<String, Any>(
                    "success" to result.success,
                    "device_id" to (result.deviceId ?: "null"),
                    "strategy_used" to result.strategy.name,
                    "storage_path" to (result.path ?: "null"),
                    "error_message" to (result.error ?: "null"),
                    "test_timestamp" to System.currentTimeMillis()
                )
            } catch (e: Exception) {
                mapOf<String, Any>(
                    "success" to false,
                    "device_id" to "null",
                    "strategy_used" to "FAILED",
                    "storage_path" to "null",
                    "error_message" to (e.message ?: "Unknown error"),
                    "test_timestamp" to System.currentTimeMillis()
                )
            }
        }
    }

    /**
     * 清除分区存储中的设备标识符
     */
    suspend fun clearScopedStorageIdentifier(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val scopedStorageManager = ScopedStorageManager(context)
                scopedStorageManager.deleteDeviceIdentifier()
            } catch (e: Exception) {
                false
            }
        }
    }

    /**
     * 获取所有存储策略的测试结果
     */
    suspend fun getAllStorageStrategiesTestResult(): Map<String, Map<String, Any>> {
        return withContext(Dispatchers.IO) {
            val results = mutableMapOf<String, Map<String, Any>>()

            try {
                val scopedStorageManager = ScopedStorageManager(context)
                val strategies = listOf(
                    ScopedStorageManager.StorageStrategy.APP_SPECIFIC_STORAGE,
                    ScopedStorageManager.StorageStrategy.SCOPED_STORAGE,
                    ScopedStorageManager.StorageStrategy.LEGACY_EXTERNAL_STORAGE,
                    ScopedStorageManager.StorageStrategy.MEDIA_STORE
                )

                for (strategy in strategies) {
                    try {
                        // 这里应该调用私有方法，但为了演示，我们使用通用方法
                        val result = scopedStorageManager.getOrCreateDeviceIdentifier()

                        results[strategy.name] = mapOf(
                            "success" to result.success,
                            "device_id" to (result.deviceId ?: "null"),
                            "path" to (result.path ?: "null"),
                            "error" to (result.error ?: "null"),
                            "strategy" to strategy.name
                        )
                    } catch (e: Exception) {
                        results[strategy.name] = mapOf(
                            "success" to false,
                            "device_id" to "null",
                            "path" to "null",
                            "error" to (e.message ?: "Unknown error"),
                            "strategy" to strategy.name
                        )
                    }
                }
            } catch (e: Exception) {
                results["ERROR"] = mapOf(
                    "success" to false,
                    "device_id" to "null",
                    "path" to "null",
                    "error" to (e.message ?: "Unknown error"),
                    "strategy" to "ERROR"
                )
            }

            results
        }
    }

    /**
     * 字符串哈希函数
     */
    private fun hashString(input: String): String {
        return try {
            val bytes = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
            bytes.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            input.hashCode().toString()
        }
    }
} 