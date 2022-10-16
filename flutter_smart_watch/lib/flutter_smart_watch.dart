library flutter_smart_watch_ios;

import 'package:flutter_smart_watch_android/flutter_smart_watch_android.dart';
import 'package:flutter_smart_watch_ios/flutter_smart_watch_ios.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

export 'package:flutter_smart_watch_ios/flutter_smart_watch_ios.dart';

class FlutterSmartWatch {
  static FlutterSmartWatchIos get ios =>
      FlutterSmartWatchPlatformInterface.instance as FlutterSmartWatchIos;

  static FlutterSmartWatchAndroid get android =>
      FlutterSmartWatchPlatformInterface as FlutterSmartWatchAndroid;
}
