library flutter_smart_watch_watch_os;

import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:flutter_smart_watch_harmony_os/flutter_smart_watch_harmony_os.dart';
import 'package:flutter_watch_os_connectivity/flutter_watch_os_connectivity.dart';

export 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
export 'package:flutter_smart_watch_harmony_os/flutter_smart_watch_harmony_os.dart';

class FlutterSmartWatch {
  FlutterWatchOsConnectivity _watchOS = FlutterWatchOsConnectivity();
  FlutterWearOsConnectivity _wearOS = FlutterWearOsConnectivity();
  FlutterSmartWatchHarmonyOs _harmonyOs = FlutterSmartWatchHarmonyOs();

  FlutterWatchOsConnectivity get watchOS => _watchOS;

  FlutterWearOsConnectivity get wearOS => _wearOS;

  FlutterSmartWatchHarmonyOs get harmonyOs => _harmonyOs;

  static FlutterSmartWatch _instance = FlutterSmartWatch._internal();

  FlutterSmartWatch._internal();

  factory FlutterSmartWatch() {
    return _instance;
  }
}
