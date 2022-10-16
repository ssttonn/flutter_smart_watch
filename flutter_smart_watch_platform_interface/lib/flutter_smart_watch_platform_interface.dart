import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class FlutterSmartWatchPlatformInterface extends PlatformInterface {
  /// [FlutterSmartWatchPlatformInterface] constructor
  FlutterSmartWatchPlatformInterface() : super(token: _token);
  static final Object _token = Object();

  /// Default instance of [FlutterSmartWatchPlatformInterface] is [FlutterSmartWatchMethodChannel]
  static FlutterSmartWatchPlatformInterface _instance =
      DefaultPlatformInterface();

  static FlutterSmartWatchPlatformInterface get instance => _instance;

  static set instance(FlutterSmartWatchPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future initialize() {
    throw UnimplementedError('initalize() has not been implemented.');
  }

  void dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}

class DefaultPlatformInterface implements FlutterSmartWatchPlatformInterface {
  @override
  void dispose() {
    throw UnimplementedError();
  }

  @override
  Future initialize() {
    throw UnimplementedError();
  }
}