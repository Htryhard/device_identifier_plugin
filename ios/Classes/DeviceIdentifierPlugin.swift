import Flutter
import UIKit

public class DeviceIdentifierPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.hicyh.device_identifier_plugin", binaryMessenger: registrar.messenger())
    let instance = DeviceIdentifierPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
      
    case "getSupportedIdentifiers":
      Task {
        await getDeviceIdentifier(result: result)
      }
      
    case "getAdvertisingIdForiOS":
      Task {
        await getAdvertisingIdForiOS(result: result)
      }
      
    case "isEmulator":
      Task {
        await getIsEmulator(result: result)
      }
      
    case "getDeviceInfo":
      Task {
        await getDeviceInfo(result: result)
      }

    case "getAppleIDFV":
      Task {
        await getAppleIDFV(result: result)
      } 

    case "getKeychainUUID":
      Task {
        await getKeychainUUID(result: result)
      } 

    case "hasKeychainUUID":
      Task {
        await hasKeychainUUID(result: result)
      } 

    case "generateKeychainUUID":
      Task {
        await generateKeychainUUID(result: result)
      } 

    case "clearCachedIdentifiers":
      Task {
        await clearCachedIdentifiers(result: result)
      }
      
    case "getPermissionStatus":
      Task {
        await getPermissionStatus(result: result)
      }
      
    case "requestTrackingAuthorization":
      Task {
        await requestTrackingAuthorization(result: result)
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - 私有方法
  
  private func getDeviceIdentifier(result: @escaping FlutterResult) async {
    let identifier = await DeviceIdentifierManager.shared.getDeviceIdentifier()
    
    let deviceData: [String: Any?] = [
      "iosDeviceID": identifier.iosDeviceID,
      "idfv": identifier.idfv,
      "idfa": identifier.idfa,
      "keychainUUID": identifier.keychainUUID,
      "deviceFingerprint": identifier.deviceFingerprint,
      "launchUUID": identifier.launchUUID,
      "combinedId": identifier.combinedId,
      "isLimitAdTrackingEnabled": identifier.isLimitAdTrackingEnabled
      //"deviceInfo": identifier.deviceInfo
    ]
    
    result(deviceData)
  }
  
  private func getAdvertisingIdForiOS(result: @escaping FlutterResult) async {
    let idfa = await DeviceIdentifierManager.shared.getIDFA()
    result(idfa)
  }

  private func getAppleIDFV(result: @escaping FlutterResult) async {
    let idfv = await DeviceIdentifierManager.shared.getIDFV()
    result(idfv)
  }

  private func getKeychainUUID(result: @escaping FlutterResult) async {
    let keychainUUID = await DeviceIdentifierManager.shared.readFromKeychain()
    result(keychainUUID)
  }

  private func hasKeychainUUID(result: @escaping FlutterResult) async {
    let keychainUUID = await DeviceIdentifierManager.shared.readFromKeychain()
    result(keychainUUID != nil && !keychainUUID!.isEmpty)
  }

  private func generateKeychainUUID(result: @escaping FlutterResult) async {
    let keychainUUID = await DeviceIdentifierManager.shared.getKeychainUUID()
    result(keychainUUID)
  }
  
  private func getIsEmulator(result: @escaping FlutterResult) async {
    let isEmulator = await DeviceIdentifierManager.shared.isSimulator()
    result(isEmulator)
  }
  
  private func getDeviceInfo(result: @escaping FlutterResult) async {
    let deviceInfo = await DeviceIdentifierManager.shared.getDeviceInfo()
    result(deviceInfo)
  }
  
  private func clearCachedIdentifiers(result: @escaping FlutterResult) async {
    let manager = DeviceIdentifierManager.shared
    let keychainCleared = await manager.clearKeychainUUID()
    let deviceIDCleared = await manager.clearIOSDeviceID()
    let cleared = keychainCleared && deviceIDCleared
    result(cleared)
  }
  
  private func getPermissionStatus(result: @escaping FlutterResult) async {
    let permissionStatus = await DeviceIdentifierManager.shared.getPermissionStatus()
    result(permissionStatus)
  }
  
  private func requestTrackingAuthorization(result: @escaping FlutterResult) async {
    let status = await DeviceIdentifierManager.shared.requestTrackingAuthorization()
    
    var statusString: String
    switch status {
    case .notDetermined:
      statusString = "notDetermined"
    case .restricted:
      statusString = "restricted"
    case .denied:
      statusString = "denied"
    case .authorized:
      statusString = "authorized"
    @unknown default:
      statusString = "unknown"
    }
    
    result(statusString)
  }
}
