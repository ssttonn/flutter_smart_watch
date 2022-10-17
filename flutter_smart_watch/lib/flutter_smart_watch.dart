library flutter_smart_watch_ios;

import 'package:flutter_smart_watch_android/flutter_smart_watch_android.dart';
import 'package:flutter_smart_watch_ios/flutter_smart_watch_ios.dart';

export 'package:flutter_smart_watch_ios/flutter_smart_watch_ios.dart';

class FlutterSmartWatch {
  FlutterSmartWatchIos _ios = FlutterSmartWatchIos();
  FlutterSmartWatchAndroid _android = FlutterSmartWatchAndroid();

  FlutterSmartWatchIos get ios => _ios;

  FlutterSmartWatchAndroid get android => _android;
}
