import Flutter
import UIKit

public class SwiftFlutterSmartWatchIosPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_smart_watch_ios", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterSmartWatchIosPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
