import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/wear_os_observer.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

import 'models/node.dart';

class FlutterSmartWatchAndroid extends FlutterSmartWatchPlatformInterface {
  static registerWith() {
    FlutterSmartWatchPlatformInterface.instance = FlutterSmartWatchAndroid();
  }

  late WearOSObserver _wearOSObserver;

  @override
  Future initialize() async {
    _wearOSObserver = WearOSObserver();
    _wearOSObserver.initAllStreamControllers();
  }

  @override
  Future<bool> isSupported() async {
    bool? isSupported = await channel.invokeMethod("isSupported");
    return isSupported ?? false;
  }

  Future configureWearableAPI() async {
    return channel.invokeMethod("configure");
  }

  Future<List<Node>> getConnectedNodes() async {
    List rawNodes = await channel.invokeMethod("getConnectedNodes");
    return rawNodes
        .map((nodeJson) => Node.fromJson((nodeJson as Map? ?? {})
            .map((key, value) => MapEntry(key.toString(), value))))
        .toList();
  }

  @override
  void dispose() {
    _wearOSObserver.clearAllStreamControllers();
  }
}
