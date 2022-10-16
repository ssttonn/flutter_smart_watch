import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

class FlutterSmartWatchAndroid extends FlutterSmartWatchPlatformInterface {
  static registerWith() {
    FlutterSmartWatchPlatformInterface.instance = FlutterSmartWatchAndroid();
  }
}
