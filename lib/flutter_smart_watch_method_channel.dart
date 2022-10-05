part of flutter_smart_watch;

class _MethodChannelFlutterSmartWatch extends _FlutterSmartWatchPlatform {
  final methodChannel = const MethodChannel('flutter_smart_watch');

  @override
  Future<bool?> isSmartWatchSupported() async {
    return methodChannel.invokeMethod<bool?>("isSupported");
  }

  @override
  Future activate() {
    return methodChannel.invokeMethod("activate");
  }

  @override
  Future<ActivationState> getActivateState() async {
    int stateIndex = await methodChannel.invokeMethod("getActivateState");
    return ActivationState.values[stateIndex];
  }

  @override
  Future<PairedDeviceInfo> getPairedDeviceInfo() async {
    String jsonString = await methodChannel.invokeMethod("getPairedDeviceInfo");
    Map<String, dynamic> json = jsonDecode(jsonString);
    return PairedDeviceInfo.fromJson(json);
  }

  @override
  Future<bool> getReachability() async {
    bool isReachable = await methodChannel.invokeMethod("getReachability");
    return isReachable;
  }

  @override
  Future<ApplicationContext> getLatestApplicationContext() async {
    Map _rawContext =
        await methodChannel.invokeMethod("getLatestApplicationContext");
    return ApplicationContext.fromJson(
        _rawContext.map((key, value) => MapEntry(key.toString(), value)));
  }

  @override
  Future sendMessage(Message message, {String? handlerId}) {
    return methodChannel.invokeMethod("sendMessage", {
      "message": message,
      if (handlerId != null) "replyHandlerId": handlerId
    });
  }

  @override
  Future updateApplicationContext(Map<String, dynamic> applicationContext) {
    return methodChannel.invokeMethod(
        "updateApplicationContext", applicationContext);
  }
}
