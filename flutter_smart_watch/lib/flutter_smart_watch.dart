library flutter_smart_watch_ios;

import 'dart:io';

import 'package:flutter_smart_watch_android/flutter_smart_watch_android.dart';
import 'package:flutter_smart_watch_ios/flutter_smart_watch_ios.dart';

export 'package:flutter_smart_watch_ios/flutter_smart_watch_ios.dart';
export 'package:flutter_smart_watch_android/flutter_smart_watch_android.dart';

class FlutterSmartWatch {
  FlutterSmartWatchIos _ios = FlutterSmartWatchIos();
  FlutterSmartWatchAndroid _android = FlutterSmartWatchAndroid();

  FlutterSmartWatchIos get ios => _ios;

  FlutterSmartWatchAndroid get android => _android;

  static FlutterSmartWatch _instance = FlutterSmartWatch._internal();

  FlutterSmartWatch._internal();

  factory FlutterSmartWatch() {
    return _instance;
  }
}
