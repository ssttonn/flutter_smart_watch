library flutter_smart_watch_ios;

import 'package:flutter_smart_watch_android/flutter_smart_watch_android.dart';
import 'package:flutter_smart_watch_ios/flutter_smart_watch_ios.dart';
import 'package:flutter_smart_watch_harmony_os/flutter_smart_watch_harmony_os.dart';

export 'package:flutter_smart_watch_ios/flutter_smart_watch_ios.dart';
export 'package:flutter_smart_watch_android/flutter_smart_watch_android.dart';
export 'package:flutter_smart_watch_harmony_os/flutter_smart_watch_harmony_os.dart';

class FlutterSmartWatch {
  FlutterSmartWatchIos _ios = FlutterSmartWatchIos();
  FlutterSmartWatchAndroid _android = FlutterSmartWatchAndroid();
  FlutterSmartWatchHarmonyOs _harmonyOs = FlutterSmartWatchHarmonyOs();

  FlutterSmartWatchIos get ios => _ios;

  FlutterSmartWatchAndroid get android => _android;

  FlutterSmartWatchHarmonyOs get harmonyOs => _harmonyOs;

  static FlutterSmartWatch _instance = FlutterSmartWatch._internal();

  FlutterSmartWatch._internal();

  factory FlutterSmartWatch() {
    return _instance;
  }
}
