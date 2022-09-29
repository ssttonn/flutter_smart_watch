import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_smart_watch_method_channel.dart';

abstract class FlutterSmartWatchPlatform extends PlatformInterface {
  /// Constructs a FlutterSmartWatchPlatform.
  FlutterSmartWatchPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSmartWatchPlatform _instance = MethodChannelFlutterSmartWatch();

  /// The default instance of [FlutterSmartWatchPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSmartWatch].
  static FlutterSmartWatchPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSmartWatchPlatform] when
  /// they register themselves.
  static set instance(FlutterSmartWatchPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
