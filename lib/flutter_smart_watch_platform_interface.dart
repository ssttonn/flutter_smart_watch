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

  Future sendMessage(Message message) {
    throw UnimplementedError("sendMessage() has not been implemented");
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
        "MessageReceivedCallback() has not been implemented");
  }
}
