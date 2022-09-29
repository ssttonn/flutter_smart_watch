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
            watchSession?.activate()
            result(nil)
        case "getActivateState":
            guard watchSession != nil else{
                handleFlutterError(result: result, message: "Session not found, you need to call activate() first to configure a session")
                return
            }
            result(watchSession?.activationState.rawValue)
        case "getPairedDeviceInfo":
            guard watchSession != nil else{
                handleFlutterError(result: result, message: "Session not found, you need to call activate() first to configure a session")
                return
            }
        default:
            result(nil)
        }
    }
}

//MARK: - WCSessionDelegate methods handle
extension SwiftFlutterSmartWatchPlugin: WCSessionDelegate{
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard error != nil else {}
        callbackChannel.invokeMethod("activateStateChanged", arguments: activationState.rawValue)
        print(session.isPaired)
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        callbackChannel.invokeMethod("activateStateChanged", arguments: session.activationState)
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        callbackChannel.invokeMethod("activateStateChanged", arguments: session.activationState)
    }
    
    func handleFlutterError(result: FlutterResult,message: String){
        result(FlutterError(code: "500", message: message, details: nil))
    }
    
    func handleCallbackError(message: String){
        callbackChannel.invokeMethod("onError", arguments: message)
    }
}

extension WCSession{
    func toPairedDeviceJsonString()-> String{
        var dict: [String: Any] = [:]
        dict["isPaired"] = self.isPaired
        dict["isComplicationEnabled"] = self.isComplicationEnabled
        dict["isWatchAppInstalled"] = self.isWatchAppInstalled
        return
    }
}
