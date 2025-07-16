import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency
import Security
import CommonCrypto
import os.log

/**
 * iOS 设备唯一标识符管理器
 * 兼容 iOS 15+ 及最新隐私政策
 * 提供多种设备标识符获取方式，用于应用安装统计
 */
@MainActor
class DeviceIdentifierManager: ObservableObject {
    
    static let shared = DeviceIdentifierManager()
    
    private let keychainService = "com.hicyh.getdeviceid.keychain"
    private let keychainAccount = "device_uuid"
    
    // 日志系统
    private let logger = Logger(subsystem: "com.hicyh.getdeviceid", category: "DeviceIdentifier")
    
    // MARK: - 设备标识符数据结构
    
    struct IOSDeviceIdentifier {
        /** iOS设备ID: 类似Android ID的概念，最推荐用于统计 */
        let iosDeviceID: String
        /** IDFV: 同一开发者应用共享，卸载重装时可能变化 */
        let idfv: String?
        /** IDFA: 广告标识符，iOS 14.5+ 需要用户授权，卸载重装不变 */
        let idfa: String?
        /** Keychain UUID: 存储在钥匙串中，最稳定的标识符 */
        let keychainUUID: String?
        /** 设备指纹: 基于硬件信息生成的相对稳定标识符 */
        let deviceFingerprint: String?
        /** 应用启动UUID: 每次应用启动生成，测试用 */
        let launchUUID: String
        /** 组合ID: 多个标识符的组合哈希 */
        let combinedId: String?
        /** 是否限制广告追踪: ATT授权状态 */
        let isLimitAdTrackingEnabled: Bool
        /** 设备基本信息 */
        let deviceInfo: [String: String]
    }
    
    // MARK: - 公开方法

    /**
     * 获取设备基本信息
     * 返回内容包括：
     * - model: 设备型号标识符（如 "iPhone14,2"）
     * - name: 设备名称（如 "张三的iPhone"）
     * - systemName: 操作系统名称（如 "iOS"）
     * - systemVersion: 操作系统版本号（如 "17.0.2"）
     * - localizedModel: 本地化设备型号（如 "iPhone"）
     * - isSimulator: 是否为模拟器（"true"/"false"）
     * - screenSize: 屏幕分辨率（如 "390x844"）
     * - screenScale: 屏幕缩放因子（如 "3.0"）
     * - timeZone: 当前时区标识符（如 "Asia/Shanghai"）
     * - language: 当前系统语言（如 "zh"、"en"）
     */
    func getDeviceInfo() async -> [String: String] {
        let device = UIDevice.current
        return [
            "model": deviceModel(),
            "name": device.name,
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "localizedModel": device.localizedModel,
            "isSimulator": isSimulator() ? "true" : "false",
            "screenSize": "\(Int(UIScreen.main.bounds.width))x\(Int(UIScreen.main.bounds.height))",
            "screenScale": "\(UIScreen.main.scale)",
            "timeZone": TimeZone.current.identifier,
            "language": {
                if #available(iOS 16, *) {
                    return Locale.current.language.languageCode?.identifier ?? "unknown"
                } else {
                    return Locale.current.languageCode ?? "unknown"
                }
            }()
        ]
    }
    
    /**
     * 获取完整的设备标识符信息
     */
    func getDeviceIdentifier() async -> IOSDeviceIdentifier {
        logger.info("🚀 开始获取设备标识符信息")
        
        logger.info("📱 正在获取 IDFV...")
        let idfv = getIDFV()
        logger.info("📱 IDFV 获取结果: \(idfv ?? "nil", privacy: .public)")
        
        logger.info("📺 正在获取 IDFA...")
        let idfa = await getIDFA()
        logger.info("📺 IDFA 获取结果: \(idfa ?? "nil", privacy: .public)")
        
        logger.info("🔐 正在获取 Keychain UUID...")
        let keychainUUID = getKeychainUUID()
        logger.info("🔐 Keychain UUID 获取结果: \(keychainUUID ?? "nil", privacy: .public)")
        
        logger.info("👆 正在获取设备指纹...")
        let deviceFingerprint = getDeviceFingerprint()
        logger.info("👆 设备指纹获取结果: \(deviceFingerprint ?? "nil", privacy: .public)")
        
        let launchUUID = UUID().uuidString
        logger.info("🎲 生成启动UUID: \(launchUUID, privacy: .public)")
        
        logger.info("ℹ️ 正在获取设备信息...")
        let deviceInfo = await getDeviceInfo()
        logger.info("ℹ️ 设备信息获取完成，包含 \(deviceInfo.count) 项")
        
        logger.info("🔒 正在检查广告追踪授权状态...")
        let isLimitAdTrackingEnabled = await getTrackingAuthorizationStatus() != .authorized
        logger.info("🔒 限制广告追踪: \(isLimitAdTrackingEnabled)")
        
        logger.info("🔗 正在生成组合ID...")
        let combinedId = generateCombinedId(
            idfv: idfv,
            idfa: idfa,
            keychainUUID: keychainUUID,
            deviceFingerprint: deviceFingerprint
        )
        logger.info("🔗 组合ID生成结果: \(combinedId ?? "nil", privacy: .public)")
        
        // 获取iOS设备ID（类似Android ID）
        logger.info("🍎 正在获取 iOS 设备ID...")
        let iosDeviceID = await getIOSDeviceID()
        logger.info("🍎 iOS 设备ID获取结果: \(iosDeviceID, privacy: .public)")
        
        logger.info("✅ 设备标识符信息获取完成")
        
        return IOSDeviceIdentifier(
            iosDeviceID: iosDeviceID,
            idfv: idfv,
            idfa: idfa,
            keychainUUID: keychainUUID,
            deviceFingerprint: deviceFingerprint,
            launchUUID: launchUUID,
            combinedId: combinedId,
            isLimitAdTrackingEnabled: isLimitAdTrackingEnabled,
            deviceInfo: deviceInfo
        )
    }
    
    /**
     * 获取最优的设备标识符
     * 按优先级返回可用的标识符
     */
    func getBestDeviceIdentifier() async -> String {
        let identifier = await getDeviceIdentifier()
        
        // iOS设备ID现在是最优选择（类似Android ID）
        return identifier.iosDeviceID
    }
    
    /**
     * 获取iOS设备ID（类似Android ID的概念）
     * 这是iOS平台上最接近Android ID功能的标识符
     * 
     * 稳定性分析：
     * - 卸载重装：不变 ✅（使用钥匙串存储）
     * - 系统更新：不变 ✅
     * - 应用更新：不变 ✅
     * - 设备重启：不变 ✅
     * - 恢复备份：不变 ✅
     * - 设备重置：会变化 ✗
     * - 用户手动清除：可能变化 ⚠️
     * 
     * 实现策略：
     * 1. 优先使用钥匙串UUID（最稳定）
     * 2. 如果钥匙串失效，使用IDFV + 设备指纹组合
     * 3. 生成的ID会自动保存到钥匙串以确保一致性
     * 
     * 这个方法提供了与Android ID相似的稳定性和唯一性
     */
    func getIOSDeviceID() async -> String {
        logger.info("🍎 [iOS设备ID] 开始获取iOS设备ID")
        
        // 尝试从钥匙串获取已存储的设备ID
        logger.info("🍎 [iOS设备ID] 尝试从钥匙串获取已存储的设备ID")
        if let existingDeviceID = getStoredIOSDeviceID() {
            logger.info("🍎 [iOS设备ID] ✅ 从钥匙串成功获取已存储的设备ID: \(existingDeviceID.prefix(8))...")
            return existingDeviceID
        }
        logger.info("🍎 [iOS设备ID] ⚠️ 钥匙串中没有找到已存储的设备ID，需要生成新的")
        
        // 如果没有存储的设备ID，生成新的
        logger.info("🍎 [iOS设备ID] 正在生成新的设备ID...")
        let deviceIdentifier = await getBasicDeviceIdentifier()
        let newDeviceID = generateIOSDeviceID(from: deviceIdentifier)
        logger.info("🍎 [iOS设备ID] ✅ 新设备ID生成成功: \(newDeviceID.prefix(8))...")
        
        // 保存到钥匙串
        logger.info("🍎 [iOS设备ID] 正在保存新设备ID到钥匙串...")
        saveIOSDeviceID(newDeviceID)
        
        logger.info("🍎 [iOS设备ID] ✅ iOS设备ID获取完成")
        return newDeviceID
    }
    
    /**
     * 获取生成iOS设备ID所需的基本设备标识符信息
     * 这个方法不会调用getIOSDeviceID()，避免循环依赖
     */
    private func getBasicDeviceIdentifier() async -> IOSDeviceIdentifier {
        logger.info("🔧 [基础标识符] 开始获取基础设备标识符信息（用于生成iOS设备ID）")
        
        logger.info("📱 正在获取 IDFV...")
        let idfv = getIDFV()
        logger.info("📱 IDFV 获取结果: \(idfv ?? "nil", privacy: .public)")
        
        logger.info("📺 正在获取 IDFA...")
        let idfa = await getIDFA()
        logger.info("📺 IDFA 获取结果: \(idfa ?? "nil", privacy: .public)")
        
        logger.info("👆 正在获取设备指纹...")
        let deviceFingerprint = getDeviceFingerprint()
        logger.info("👆 设备指纹获取结果: \(deviceFingerprint ?? "nil", privacy: .public)")
        
        logger.info("🔒 正在检查广告追踪授权状态...")
        let isLimitAdTrackingEnabled = await getTrackingAuthorizationStatus() != .authorized
        logger.info("🔒 限制广告追踪: \(isLimitAdTrackingEnabled)")
        
        logger.info("🔧 [基础标识符] ✅ 基础设备标识符信息获取完成")
        
        return IOSDeviceIdentifier(
            iosDeviceID: "", // 这里留空，因为我们正在生成它
            idfv: idfv,
            idfa: idfa,
            keychainUUID: nil, // iOS设备ID生成不需要keychain UUID
            deviceFingerprint: deviceFingerprint,
            launchUUID: UUID().uuidString,
            combinedId: nil, // iOS设备ID生成不需要组合ID
            isLimitAdTrackingEnabled: isLimitAdTrackingEnabled,
            deviceInfo: [:] // iOS设备ID生成不需要完整设备信息
        )
    }
    
    /**
     * 从钥匙串获取已存储的iOS设备ID
     */
    func getStoredIOSDeviceID() -> String? {
        logger.info("[钥匙串] 开始从钥匙串获取iOS设备ID")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "ios_device_id",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        logger.info("[钥匙串] 钥匙串查询参数: service=\(self.keychainService), account=ios_device_id")
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        logger.info("[钥匙串] 钥匙串查询状态码: \(status)")
        
        if status == errSecSuccess {
            logger.info("[钥匙串] 钥匙串查询成功")
            
            if let data = result as? Data {
                logger.info("[钥匙串] 成功获取数据，数据长度: \(data.count) 字节")
                
                if let deviceID = String(data: data, encoding: .utf8) {
                    logger.info("[钥匙串] 成功解码设备ID: \(deviceID.prefix(8))...")
                    return deviceID
                } else {
                    logger.error("[钥匙串] 数据解码为字符串失败")
                }
            } else {
                logger.error("[钥匙串] 返回的数据不是Data类型")
            }
        } else {
            // 记录具体的错误信息
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "未知错误"
            logger.info("[钥匙串] 钥匙串查询失败: \(errorMessage) (状态码: \(status))")
            
            if status == errSecItemNotFound {
                logger.info("[钥匙串] 这是正常情况,设备ID尚未存储")
            }
        }
        
        logger.info("[钥匙串] 返回nil,未找到已存储的iOS设备ID")
        return nil
    }
    
    /**
     * 保存iOS设备ID到钥匙串
     */
    private func saveIOSDeviceID(_ deviceID: String) {
        logger.info("💾 [钥匙串保存] 开始保存iOS设备ID到钥匙串")
        logger.info("💾 [钥匙串保存] 设备ID: \(deviceID.prefix(8))...")
        
        guard let data = deviceID.data(using: .utf8) else {
            logger.error("💾 [钥匙串保存] ❌ 设备ID转换为Data失败")
            return
        }
        
        logger.info("💾 [钥匙串保存] ✅ 设备ID转换为Data成功，数据长度: \(data.count) 字节")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "ios_device_id",
            kSecValueData as String: data
        ]
        
        // 先删除可能存在的旧数据
        logger.info("💾 [钥匙串保存] 正在删除可能存在的旧数据...")
        let deleteStatus = SecItemDelete(query as CFDictionary)
        logger.info("💾 [钥匙串保存] 删除操作状态码: \(deleteStatus)")
        
        // 添加新数据
        logger.info("💾 [钥匙串保存] 正在添加新数据...")
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        logger.info("💾 [钥匙串保存] 添加操作状态码: \(addStatus)")
        
        if addStatus == errSecSuccess {
            logger.info("💾 [钥匙串保存] ✅ iOS设备ID保存成功")
        } else {
            let errorMessage = SecCopyErrorMessageString(addStatus, nil) as String? ?? "未知错误"
            logger.error("💾 [钥匙串保存] ❌ iOS设备ID保存失败: \(errorMessage) (状态码: \(addStatus))")
        }
    }
    
    /**
     * 生成iOS设备ID
     * 使用多个标识符组合生成稳定的设备ID
     */
    private func generateIOSDeviceID(from identifier: IOSDeviceIdentifier) -> String {
        var components: [String] = []
        
        // 核心组件：IDFV（如果可用）
        if let idfv = identifier.idfv, !idfv.isEmpty {
            components.append("IDFV:\(idfv)")
        }
        
        // 稳定组件：设备指纹
        if let deviceFingerprint = identifier.deviceFingerprint, !deviceFingerprint.isEmpty {
            components.append("FP:\(deviceFingerprint)")
        }
        
        // 备用组件：如果IDFA可用且用户授权
        if let idfa = identifier.idfa, !idfa.isEmpty, !identifier.isLimitAdTrackingEnabled {
            components.append("IDFA:\(idfa)")
        }
        
        // 设备硬件标识
        let deviceModel = self.deviceModel()
        components.append("MODEL:\(deviceModel)")
        
        // 如果没有足够的组件，使用时间戳确保唯一性
        if components.isEmpty {
            let timestamp = String(Int(Date().timeIntervalSince1970))
            components.append("TS:\(timestamp)")
            components.append("RAND:\(UUID().uuidString)")
        }
        
        // 生成最终的设备ID
        let combinedString = components.joined(separator: "|")
        let deviceID = "iOS_" + sha256(combinedString).prefix(32)
        
        return String(deviceID)
    }
    
    /**
     * 清除iOS设备ID（用于测试）
     */
    func clearIOSDeviceID() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "ios_device_id"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /**
     * 请求广告追踪权限
     */
    func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        if #available(iOS 14.5, *) {
            return await ATTrackingManager.requestTrackingAuthorization()
        } else {
            return .authorized
        }
    }
    
    /**
     * 检查是否为模拟器
     */
    func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    
    /**
     * 获取 IDFV (Identifier For Vendor)
     *
     * 稳定性分析：
     * - 卸载重装：如果设备上没有同一开发者的其他应用，会变化 ⚠️
     * - 如果有同一开发者的其他应用，则不变 ✓
     * - 系统更新：不变 ✓
     * - 应用更新：不变 ✓
     * - 设备重启：不变 ✓
     *
     * 特殊情况：
     * - 同一个Apple开发者账号下的应用共享相同IDFV
     * - 设备上所有该开发者的应用都被卸载后，重新安装会生成新的IDFV
     * - 企业版应用和App Store应用的IDFV不同
     *
     * 推荐使用场景：用户行为分析、应用内统计
     */
    func getIDFV() -> String? {
        logger.info("📱 [IDFV] 开始获取IDFV")
        
        let vendorID = UIDevice.current.identifierForVendor
        if let vendorID = vendorID {
            let idfv = vendorID.uuidString
            logger.info("📱 [IDFV] ✅ IDFV获取成功: \(idfv)")
            return idfv
        } else {
            logger.error("📱 [IDFV] ❌ IDFV获取失败，identifierForVendor为nil")
            return nil
        }
    }
    
    /**
     * 获取 IDFA (Identifier for Advertisers)
     *
     * 稳定性分析：
     * - 卸载重装：不变 ✓
     * - 用户手动重置：会变化 ✗
     * - 系统更新：不变 ✓
     * - 应用更新：不变 ✓
     * - 设备重启：不变 ✓
     * - 用户限制追踪：返回全零UUID ✗
     *
     * 权限要求：
     * - iOS 14.5+：需要用户明确授权 (ATTrackingManager)
     * - iOS 14.0-14.4：默认可用，用户可在设置中关闭
     * - iOS 13-：默认可用
     *
     * 隐私政策：
     * - 必须遵循 Apple 的广告政策
     * - 需要在应用中说明使用目的
     * - 用户可以随时撤销授权
     * - 儿童类应用不能使用
     *
     * 特殊情况：
     * - 用户拒绝授权时返回全零UUID
     * - 限制广告追踪时返回全零UUID
     * - 模拟器中通常返回全零UUID
     *
     * 推荐使用场景：广告归因、用户获取分析（需要合规使用）
     */
    func getIDFA() async -> String? {
        logger.info("📺 [IDFA] 开始获取IDFA")
        
        logger.info("📺 [IDFA] 正在检查广告追踪授权状态...")
        let authorizationStatus = await getTrackingAuthorizationStatus()
        logger.info("📺 [IDFA] 广告追踪授权状态: \(authorizationStatus.rawValue)")
        
        if authorizationStatus == .authorized {
            logger.info("📺 [IDFA] ✅ 已获得广告追踪授权，正在获取IDFA...")
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            logger.info("📺 [IDFA] 原始IDFA值: \(idfa)")
            
            // 检查是否为全零UUID
            if idfa != "00000000-0000-0000-0000-000000000000" {
                logger.info("📺 [IDFA] ✅ IDFA获取成功: \(idfa)")
                return idfa
            } else {
                logger.info("📺 [IDFA] ⚠️ IDFA为全零UUID，可能用户限制了广告追踪")
            }
        } else {
            logger.info("📺 [IDFA] ❌ 未获得广告追踪授权，无法获取IDFA")
        }
        
        logger.info("📺 [IDFA] 返回nil")
        return nil
    }
    
    /**
     * 获取广告追踪授权状态
     */
    private func getTrackingAuthorizationStatus() async -> ATTrackingManager.AuthorizationStatus {
        logger.info("🔒 [授权状态] 开始检查广告追踪授权状态")
        
        if #available(iOS 14.5, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            logger.info("🔒 [授权状态] iOS 14.5+ 授权状态: \(status.rawValue)")
            switch status {
            case .notDetermined:
                logger.info("🔒 [授权状态] 用户尚未做出选择")
            case .restricted:
                logger.info("🔒 [授权状态] 受限制（例如家长控制）")
            case .denied:
                logger.info("🔒 [授权状态] 用户拒绝授权")
            case .authorized:
                logger.info("🔒 [授权状态] 用户已授权")
            @unknown default:
                logger.info("🔒 [授权状态] 未知状态")
            }
            return status
        } else {
            // iOS 14.5 之前版本
            let isEnabled = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
            let status: ATTrackingManager.AuthorizationStatus = isEnabled ? .authorized : .denied
            logger.info("🔒 [授权状态] iOS 14.5- 追踪启用: \(isEnabled), 转换状态: \(status.rawValue)")
            return status
        }
    }
    
    /**
     * 获取钥匙串中存储的UUID
     *
     * 稳定性分析：
     * - 卸载重装：不变 ✓（如果未删除钥匙串数据）
     * - 系统更新：不变 ✓
     * - 应用更新：不变 ✓
     * - 设备重启：不变 ✓
     * - 恢复备份：不变 ✓
     * - 设备重置：会变化 ✗
     *
     * 特殊情况：
     * - 钥匙串数据在应用卸载后通常保留
     * - 用户手动删除应用数据时可能被清除
     * - 设备越狱后可能被修改
     * - 企业设备管理可能清除钥匙串
     *
     * 优点：
     * - 最稳定的标识符选项
     * - 跨应用安装保持一致
     * - 不需要用户权限
     * - 不受隐私设置影响
     *
     * 缺点：
     * - 实现复杂度较高
     * - 可能存在安全性考虑
     * - 某些企业环境可能受限
     *
     * 推荐使用场景：设备识别、防作弊、用户统计
     */
    func getKeychainUUID() -> String? {
        logger.info("[getKeychainUUID] 开始获取钥匙串UUID")
        
        // 首先尝试从钥匙串读取
        logger.info("[getKeychainUUID] 尝试从钥匙串读取现有UUID...")
        if let existingUUID = readFromKeychain() {
            if !existingUUID.isEmpty {
                logger.info("[getKeychainUUID] 从钥匙串成功读取UUID: \(existingUUID)")
                return existingUUID
            }
        }
        
        logger.info("[getKeychainUUID] 钥匙串中没有找到UUID,正在生成新的...")
        
        // 如果不存在，生成新的UUID并保存
        let newUUID = UUID().uuidString
        logger.info("[getKeychainUUID] 生成新UUID: \(newUUID)")
        
        logger.info("[getKeychainUUID] 正在保存新UUID到钥匙串...")
        if saveToKeychain(uuid: newUUID) {
            logger.info("[getKeychainUUID] UUID保存成功,返回新UUID")
            return newUUID
        } else {
            logger.error("[getKeychainUUID] UUID保存失败")
        }
        logger.error("[getKeychainUUID] 钥匙串UUID获取失败,返回nil")
        return nil
    }
    
    /**
     * 从钥匙串读取UUID
     * 读取不到返回nil
     */
    func readFromKeychain() -> String? {
        logger.info("[钥匙串读取] 开始从钥匙串读取UUID")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        logger.info("[钥匙串读取] 查询参数: service=\(self.keychainService), account=\(self.keychainAccount)")
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        logger.info("[钥匙串读取] 查询状态码: \(status)")
        
        if status == errSecSuccess {
            logger.info("[钥匙串读取] 查询成功")
            
            if let data = result as? Data {
                logger.info("[钥匙串读取] 数据获取成功，长度: \(data.count) 字节")
                
                if let uuid = String(data: data, encoding: .utf8) {
                    logger.info("[钥匙串读取] UUID解码成功: \(uuid)")
                    return uuid
                } else {
                    logger.error("[钥匙串读取] 数据解码为字符串失败")
                }
            } else {
                logger.error("[钥匙串读取] 返回数据不是Data类型")
            }
        } else {
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "未知错误"
            logger.info("[钥匙串读取] 查询失败: \(errorMessage) (状态码: \(status))")
            
            if status == errSecItemNotFound {
                logger.info("[钥匙串读取] 这是正常情,UUID尚未存储")
            }
        }
        
        logger.info("[钥匙串读取] 返回nil")
        return nil
    }
    
    /**
     * 保存UUID到钥匙串
     */
    private func saveToKeychain(uuid: String) -> Bool {
        logger.info("[钥匙串保存] 开始保存UUID到钥匙串")
        logger.info("[钥匙串保存] UUID: \(uuid)")
        
        guard let data = uuid.data(using: .utf8) else {
            logger.error("[钥匙串保存] UUID转换为Data失败")
            return false
        }
        
        logger.info("[钥匙串保存] UUID转换为Data成功,长度: \(data.count) 字节")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        
        logger.info("[钥匙串保存] 保存参数: service=\(self.keychainService), account=\(self.keychainAccount)")
        
        // 先删除可能存在的旧数据
        logger.info("[钥匙串保存] 正在删除可能存在的旧数据...")
        let deleteStatus = SecItemDelete(query as CFDictionary)
        logger.info("[钥匙串保存] 删除操作状态码: \(deleteStatus)")
        
        // 添加新数据
        logger.info("[钥匙串保存] 正在添加新数据...")
        let status = SecItemAdd(query as CFDictionary, nil)
        logger.info("[钥匙串保存] 添加操作状态码: \(status)")
        
        if status == errSecSuccess {
            logger.info("[钥匙串保存] UUID保存成功")
            return true
        } else {
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "未知错误"
            logger.error("[钥匙串保存] UUID保存失败: \(errorMessage) (状态码: \(status))")
            return false
        }
    }

    /**
     * 清除钥匙串中的UUID (用于测试)
     */
    func clearKeychainUUID() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /**
     * 获取设备指纹
     *
     * 稳定性分析：
     * - 卸载重装：不变 ✓（基于硬件信息）
     * - 系统更新：通常不变 ✓
     * - 应用更新：不变 ✓
     * - 设备重启：不变 ✓
     * - 硬件变化：会变化 ✗
     * - 系统重置：会变化 ✗
     *
     * 包含的信息：
     * - 设备型号标识符
     * - 系统版本信息
     * - 屏幕尺寸和像素密度
     * - 时区信息
     * - 语言设置
     *
     * 特殊情况：
     * - 模拟器可能返回通用值
     * - 相同型号设备指纹相似
     * - 越狱设备可能修改系统信息
     * - 某些信息可能受隐私限制
     *
     * 优点：
     * - 不需要任何权限
     * - 相对稳定
     * - 实现简单
     * - 兼容所有iOS版本
     *
     * 缺点：
     * - 隐私争议
     * - 可能不够唯一
     * - 系统更新可能影响
     *
     * 推荐使用场景：辅助设备识别、反作弊
     */
    private func getDeviceFingerprint() -> String? {
        logger.info("👆 [设备指纹] 开始生成设备指纹")
        
        var components: [String] = []
        
        // 设备型号
        let deviceModelString = deviceModel()
        logger.info("👆 [设备指纹] 设备型号: \(deviceModelString)")
        components.append(deviceModelString)
        
        // 系统版本
        let systemVersion = UIDevice.current.systemVersion
        logger.info("👆 [设备指纹] 系统版本: \(systemVersion)")
        components.append(systemVersion)
        
        // 屏幕信息
        let screen = UIScreen.main
        let screenSize = "\(Int(screen.bounds.width))x\(Int(screen.bounds.height))"
        let screenScale = "\(screen.scale)"
        logger.info("👆 [设备指纹] 屏幕尺寸: \(screenSize)")
        logger.info("👆 [设备指纹] 屏幕缩放: \(screenScale)")
        components.append(screenSize)
        components.append(screenScale)
        
        // 时区
        let timezone = TimeZone.current.identifier
        logger.info("👆 [设备指纹] 时区: \(timezone)")
        components.append(timezone)
        
        // 语言设置
        if #available(iOS 16, *) {
            let language = Locale.current.language.languageCode?.identifier ?? "unknown"
            logger.info("👆 [设备指纹] 语言(iOS16+): \(language)")
            components.append(language)
        } else {
            if let language = Locale.current.languageCode {
                logger.info("👆 [设备指纹] 语言(iOS16-): \(language)")
                components.append(language)
            } else {
                logger.info("👆 [设备指纹] ⚠️ 无法获取语言代码")
            }
        }
        
        // 生成哈希
        let fingerprintInput = components.joined(separator: "|")
        logger.info("👆 [设备指纹] 指纹输入: \(fingerprintInput)")
        
        let fingerprint = sha256(fingerprintInput)
        logger.info("👆 [设备指纹] ✅ 设备指纹生成成功: \(fingerprint)")
        return fingerprint
    }
    
    /**
     * 生成组合ID
     *
     * 稳定性分析：
     * - 卸载重装：取决于组成部分 ⚠️
     * - 系统更新：通常不变 ✓
     * - 用户操作：可能变化 ⚠️
     *
     * 组合策略：
     * - 优先使用钥匙串UUID
     * - 其次使用IDFV
     * - 再次使用设备指纹
     * - 最后使用IDFA（如果用户授权）
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
    private func generateCombinedId(idfv: String?, idfa: String?, keychainUUID: String?, deviceFingerprint: String?) -> String? {
        logger.info("🔗 [组合ID] 开始生成组合ID")
        
        var identifiers: [String] = []
        
        if let keychainUUID = keychainUUID, !keychainUUID.isEmpty {
            logger.info("🔗 [组合ID] ✅ 添加钥匙串UUID: \(keychainUUID)")
            identifiers.append(keychainUUID)
        } else {
            logger.info("🔗 [组合ID] ⚠️ 钥匙串UUID不可用")
        }
        
        if let idfv = idfv, !idfv.isEmpty {
            logger.info("🔗 [组合ID] ✅ 添加IDFV: \(idfv)")
            identifiers.append(idfv)
        } else {
            logger.info("🔗 [组合ID] ⚠️ IDFV不可用")
        }
        
        if let deviceFingerprint = deviceFingerprint, !deviceFingerprint.isEmpty {
            logger.info("🔗 [组合ID] ✅ 添加设备指纹: \(deviceFingerprint.prefix(16))...")
            identifiers.append(deviceFingerprint)
        } else {
            logger.info("🔗 [组合ID] ⚠️ 设备指纹不可用")
        }
        
        if let idfa = idfa, !idfa.isEmpty {
            logger.info("🔗 [组合ID] ✅ 添加IDFA: \(idfa)")
            identifiers.append(idfa)
        } else {
            logger.info("🔗 [组合ID] ⚠️ IDFA不可用")
        }
        
        logger.info("🔗 [组合ID] 可用标识符数量: \(identifiers.count)")
        
        if !identifiers.isEmpty {
            let combinedString = identifiers.joined(separator: "-")
            logger.info("🔗 [组合ID] 组合字符串: \(combinedString)")
            let hashedId = sha256(combinedString)
            logger.info("🔗 [组合ID] ✅ 组合ID生成成功: \(hashedId)")
            return hashedId
        }
        
        logger.warning("🔗 [组合ID] ⚠️ 所有标识符都不可用，生成随机UUID")
        let randomUUID = UUID().uuidString
        logger.info("🔗 [组合ID] 随机UUID: \(randomUUID)")
        return randomUUID
    }
    
    /**
     * 获取设备型号
     */
    private func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            let scalar = UnicodeScalar(UInt8(value))
            return identifier + String(scalar)
        }
        return identifier
    }
    
    /**
     * SHA-256 哈希函数
     */
    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /**
     * 获取权限状态信息
     */
    func getPermissionStatus() async -> [String: String] {
        let attStatus = await getTrackingAuthorizationStatus()
        
        var statusString: String
        switch attStatus {
        case .notDetermined:
            statusString = "未确定"
        case .restricted:
            statusString = "受限制"
        case .denied:
            statusString = "已拒绝"
        case .authorized:
            statusString = "已授权"
        @unknown default:
            statusString = "未知"
        }
        
        return [
            "ATT_STATUS": statusString,
            "IDFA_AVAILABLE": (await getIDFA() != nil) ? "可用" : "不可用",
            "IDFV_AVAILABLE": (getIDFV() != nil) ? "可用" : "不可用",
            "KEYCHAIN_AVAILABLE": (getKeychainUUID() != nil) ? "可用" : "不可用"
        ]
    }
}

// MARK: - 扩展：ATTrackingManager异步支持

@available(iOS 14.5, *)
extension ATTrackingManager {
    static func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
} 
