import 'package:flutter_smart_watch_platform_interface/src/FlutterSmartWatchMethodChannel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class FlutterSmartWatchPlatformInterface extends PlatformInterface {
  /// [FlutterSmartWatchPlatformInterface] constructor
  FlutterSmartWatchPlatformInterface() : super(token: _token);
  static final Object _token = Object();

  /// Default instance of [FlutterSmartWatchPlatformInterface] is [FlutterSmartWatchMethodChannel]
  static FlutterSmartWatchPlatformInterface _instance =
      FlutterSmartWatchMethodChannel();

  static FlutterSmartWatchPlatformInterface get instance => _instance;

  static set instance(FlutterSmartWatchPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }
}
