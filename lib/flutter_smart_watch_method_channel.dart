import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_smart_watch_platform_interface.dart';

/// An implementation of [FlutterSmartWatchPlatform] that uses method channels.
class MethodChannelFlutterSmartWatch extends FlutterSmartWatchPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_smart_watch');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
