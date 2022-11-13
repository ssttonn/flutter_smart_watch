library flutter_smart_watch_watch_os;

import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:flutter_watch_os_connectivity/flutter_watch_os_connectivity.dart';

export 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart'
    hide channel, callbackChannel;
export 'package:flutter_watch_os_connectivity/flutter_watch_os_connectivity.dart'
    hide channel, callbackChannel;

class FlutterSmartWatch {
  FlutterWatchOsConnectivity _watchOS = FlutterWatchOsConnectivity();
  FlutterWearOsConnectivity _wearOS = FlutterWearOsConnectivity();

  FlutterWatchOsConnectivity get watchOS => _watchOS;

  FlutterWearOsConnectivity get wearOS => _wearOS;

  static FlutterSmartWatch _instance = FlutterSmartWatch._internal();

  FlutterSmartWatch._internal();

  factory FlutterSmartWatch() {
    return _instance;
  }
}
