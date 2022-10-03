import Flutter
import UIKit
import WatchConnectivity

typealias ReplyHandler = ([String: Any]) -> Void

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
            checkForWatchSession(result: result)
            result(watchSession?.activationState.rawValue)
        case "getPairedDeviceInfo":
            checkForWatchSession(result: result)
            do{
                result(try watchSession?.toPairedDeviceJsonString())
            }catch{
                handleFlutterError(result: result, message: error.localizedDescription)
            }
        case "getReachability":
            checkForWatchSession(result: result)
            result(watchSession!.isReachable)
        case "sendMessage":
            checkForWatchSession(result: result)
            if let arguments = call.arguments as? [String: Any]{
                checkSessionReachability(result: result)
                if let message = arguments["message"] as? [String: Any]{
                    var handler: ReplyHandler? = nil
                    if let replyHandlerId = arguments["replyHandlerId"] as? String{
                        handler = { replyHandler in
                            var arguments: [String: Any] = [:]
                            arguments["replyMessage"] = replyHandler
                            arguments["replyHandlerId"] = replyHandlerId
                            self.callbackChannel.invokeMethod("onMessageReplied", arguments: arguments)
                        }
                    }
                    watchSession?.sendMessage(message, replyHandler: handler){ error in
                        self.handleFlutterError(result: result, message: error.localizedDescription)
                    }
                }
               
            }
            result(nil)
        case "getApplicationContext":
            checkForWatchSession(result: result)
            result(watchSession?.applicationContext)
        case "updateApplicationContext":
            checkForWatchSession(result: result)
            if let applicationContext = call.arguments as? [String: Any]{
                do{
                    try watchSession?.updateApplicationContext(applicationContext)
                }catch{
                    handleFlutterError(result: result, message: error.localizedDescription)
                }
            }
            result(nil)
        default:
            result(nil)
        }
    }
    
    private func checkForWatchSession(result: FlutterResult){
        guard watchSession != nil else{
            handleFlutterError(result: result, message: "Session not found, you need to call activate() first to configure a session")
            return
        }
    }
    
    private func checkSessionReachability(result: FlutterResult){
        if (!watchSession!.isReachable){
            handleFlutterError(result: result, message: "Session is not reachable, your companion app is either disconnected or is in offline mode")
            return
        }
    }
}

//MARK: - WCSessionDelegate methods handle
extension SwiftFlutterSmartWatchPlugin: WCSessionDelegate{
    public func sessionReachabilityDidChange(_ session: WCSession) {
        callbackChannel.invokeMethod("reachabilityChanged", arguments: session.isReachable)
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard error == nil else {
            handleCallbackError(message: error!.localizedDescription)
            return
        }
        callbackChannel.invokeMethod("reachabilityChanged", arguments: session.isReachable)
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
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        callbackChannel.invokeMethod("messageReceived", arguments: message)
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        callbackChannel.invokeMethod("onApplicationContextReceived", arguments: applicationContext)
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
