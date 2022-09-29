import Flutter
import UIKit
import WatchConnectivity

public class SwiftFlutterSmartWatchPlugin: NSObject, FlutterPlugin {
    private var watchSession: WCSession?
    private var callbackChannel: FlutterMethodChannel
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_smart_watch", binaryMessenger: registrar.messenger())
        
        let instance = SwiftFlutterSmartWatchPlugin(callbackChannel: FlutterMethodChannel(name: "flutter_smart_watch_callback", binaryMessenger: registrar.messenger()))
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    init(callbackChannel: FlutterMethodChannel){
        self.callbackChannel = callbackChannel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method{
        case "isSupported":
            let isSupported = WCSession.isSupported()
            result(isSupported)
        case "activate":
            watchSession = WCSession.default
            watchSession?.delegate = self
            if  watchSession?.activationState != WCSessionActivationState.activated{
                watchSession?.activate()
            }
            result(nil)
        case "getActivateState":
            guard watchSession == nil else{
                handleFlutterError(result: result, message: "Session not found, you need to call activate() first to configure a session")
                return
            }
            result(watchSession?.activationState.rawValue)
        case "getPairedDeviceInfo":
            guard watchSession == nil else{
                handleFlutterError(result: result, message: "Session not found, you need to call activate() first to configure a session")
                return
            }
            do{
                result(try watchSession?.toPairedDeviceJsonString())
            }catch{
                handleFlutterError(result: result, message: error.localizedDescription)
            }
        default:
            result(nil)
        }
    }
}

//MARK: - WCSessionDelegate methods handle
extension SwiftFlutterSmartWatchPlugin: WCSessionDelegate{
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard error == nil else {
            handleCallbackError(message: error!.localizedDescription)
            return
        }
        callbackChannel.invokeMethod("activateStateChanged", arguments: activationState.rawValue)
        getPairedDeviceInfo(session: session)
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        callbackChannel.invokeMethod("activateStateChanged", arguments: session.activationState)
        getPairedDeviceInfo(session: session)
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        callbackChannel.invokeMethod("activateStateChanged", arguments: session.activationState)
        getPairedDeviceInfo(session: session)
    }
    
    private func getPairedDeviceInfo(session: WCSession){
        do{
            callbackChannel.invokeMethod("pairDeviceInfoChanged", arguments: try session.toPairedDeviceJsonString())
        }catch{
            handleCallbackError(message: error.localizedDescription)
        }
    }
    
    private func handleFlutterError(result: FlutterResult,message: String){
        result(FlutterError(code: "500", message: message, details: nil))
    }
    
    private func handleCallbackError(message: String){
        callbackChannel.invokeMethod("onError", arguments: message)
    }
}

extension WCSession{
    func toPairedDeviceJsonString() throws -> String {
        var dict: [String: Any] = [:]
        dict["isPaired"] = self.isPaired
        dict["isComplicationEnabled"] = self.isComplicationEnabled
        dict["isWatchAppInstalled"] = self.isWatchAppInstalled
        if let watchDirectoryUrl = self.watchDirectoryURL{
            dict["watchDirectoryURL"] = watchDirectoryUrl.absoluteString
        }
        let jsonData = try JSONSerialization.data(withJSONObject: dict)
        
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
}
