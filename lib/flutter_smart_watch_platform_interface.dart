part of flutter_smart_watch;

abstract class _FlutterSmartWatchPlatform {
  static _FlutterSmartWatchPlatform instance =
      _MethodChannelFlutterSmartWatch();

  Future<bool?> isSmartWatchSupported() async {
    throw UnimplementedError(
        "isSmartWatchSupported() has not been implemented");
  }

  Future activate() {
    throw UnimplementedError("activate() has not been implemented");
  }

  Future<PairedDeviceInfo> getPairedDeviceInfo() {
    throw UnimplementedError("getPairedDeviceInfo() has not been implemented");
  }

  Future<ActivationState> getActivateState() {
    throw UnimplementedError("getActivateState() has not been implemented");
  }

  Future<bool> getReachability() {
    throw UnimplementedError("getReachability() has not been implemented");
  }

  Future<ApplicationContext> getLatestApplicationContext() {
    throw UnimplementedError(
        "getLatestSentApplicationContext() has not been implemented");
  }

  Future sendMessage(Message message, {String? handlerId}) {
    throw UnimplementedError("sendMessage() has not been implemented");
  }

  Future updateApplicationContext(Map<String, dynamic> applicationContext) {
    throw UnimplementedError(
        "updateApplicationContext() has not been implemented");
  }
}
