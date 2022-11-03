import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

/// An implementation of [FlutterSmartWatchHarmonyOsPlatform] that uses method channels.
class FlutterSmartWatchHarmonyOs extends FlutterSmartWatchPlatformInterface {
  final methodChannel =
      const MethodChannel('sstonn/flutter_smart_watch_harmony_os');

  @override
  Future initialize() {
    return methodChannel.invokeMethod("initialize");
  }
}
