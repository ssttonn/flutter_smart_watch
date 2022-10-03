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

  Future<ActivateState> getActivateState() {
    throw UnimplementedError("getActivateState() has not been implemented");
  }

  Future<bool> getReachability() {
    throw UnimplementedError("getReachability() has not been implemented");
  }

  Future<ApplicationContext> getCurrentApplicationContext() {
    throw UnimplementedError(
        "getCurrentApplicationContext() has not been implemented");
  }

  Future sendMessage(Message message, {MessageReplyHandler? replyHandler}) {
    throw UnimplementedError("sendMessage() has not been implemented");
  }

  Future updateApplicationContext(Map<String, dynamic> applicationContext) {
    throw UnimplementedError(
        "updateApplicationContext() has not been implemented");
  }

  void listenToActivateStateChanged(ActiveStateChangeCallback callback) {
    throw UnimplementedError(
        "listenToActivateStateChanged() has not been implemented");
  }

  void listenToPairedDeviceInfoChanged(PairDeviceInfoChangeCallback callback) {
    throw UnimplementedError(
        "listenToPairedDeviceInfoChanged() has not been implemented");
  }

  void listenToErrorCallback(ErrorCallback callback) {
    throw UnimplementedError(
        "listenToErrorCallback() has not been implemented");
  }

  void listenToMessageReceiveEvent(MessageReceivedCallback callback) {
    throw UnimplementedError(
        "listenToMessageReceiveEvent() has not been implemented");
  }

  void listenToApplicationContext(ApplicationContextReceiveCallback callback) {
    throw UnimplementedError(
        "listenToApplicationContext() has not been implemented");
  }

  void listenToReachability(ReachabilityChangeCallback callback) {
    throw UnimplementedError("listenToReachability() has not been implemented");
  }
}
