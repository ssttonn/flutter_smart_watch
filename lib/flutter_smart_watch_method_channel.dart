part of flutter_smart_watch;

class _MethodChannelFlutterSmartWatch extends _FlutterSmartWatchPlatform {
  final methodChannel = const MethodChannel('flutter_smart_watch');
  final callbackMethodChannel =
      const MethodChannel("flutter_smart_watch_callback");
  ActiveStateChangeCallback? _activeStateChangeCallback;
  PairDeviceInfoChangeCallback? _pairDeviceInfoChangeCallback;
  MessageReceivedCallback? _messageReceivedCallback;
  ErrorCallback? _errorCallback;

  _MethodChannelFlutterSmartWatch() {
    callbackMethodChannel.setMethodCallHandler(_methodCallhandler);
  }

  Future _methodCallhandler(MethodCall call) async {
    switch (call.method) {
      case "activateStateChanged":
        if (call.arguments != null && call.arguments is int)
          _activeStateChangeCallback
              ?.call(ActivateState.values[call.arguments]);
        break;
      case "pairDeviceInfoChanged":
        if (call.arguments != null) {
          try {
            Map<String, dynamic> argumentsInJson = jsonDecode(call.arguments);
            PairedDeviceInfo _pairedDeviceInfo =
                PairedDeviceInfo.fromJson(argumentsInJson);
            _pairDeviceInfoChangeCallback?.call(_pairedDeviceInfo);
          } catch (e) {
            _errorCallback?.call(CurrentError(
                message: "Error when parsing data, please try again later",
                statusCode: 404));
          }
        }
        break;
      case "messageReceived":
        if (call.arguments != null) {
          try {
            Map<String, dynamic> argumentsInJson = jsonDecode(call.arguments);
            Message message = argumentsInJson["message"];
            _messageReceivedCallback?.call(message);
          } catch (e) {
            _errorCallback?.call(CurrentError(
                message: "Error when parsing data, please try again later",
                statusCode: 404));
          }
        }
        break;
      case "onError":
        if (call.arguments != null) {
          _errorCallback
              ?.call(CurrentError(message: call.arguments, statusCode: 0));
        }
        break;
    }
  }

  @override
  Future<bool?> isSmartWatchSupported() async {
    return methodChannel.invokeMethod<bool?>("isSupported");
  }

  @override
  Future activate() {
    return methodChannel.invokeMethod("activate");
  }

  @override
  Future<ActivateState> getActivateState() async {
    int stateIndex = await methodChannel.invokeMethod("getActivateState");
    return ActivateState.values[stateIndex];
  }

  @override
  Future<PairedDeviceInfo> getPairedDeviceInfo() async {
    String jsonString = await methodChannel.invokeMethod("getPairedDeviceInfo");
    Map<String, dynamic> json = jsonDecode(jsonString);
    return PairedDeviceInfo.fromJson(json);
  }

  @override
  Future sendMessage(Message message) {
    return methodChannel.invokeMethod("sendMessage", message);
  }

  @override
  void listenToActivateStateChanged(ActiveStateChangeCallback callback) {
    _activeStateChangeCallback = callback;
  }

  @override
  void listenToPairedDeviceInfoChanged(PairDeviceInfoChangeCallback callback) {
    _pairDeviceInfoChangeCallback = callback;
  }

  @override
  void listenToMessageReceiveEvent(MessageReceivedCallback callback) {
    _messageReceivedCallback = callback;
  }

  @override
  void listenToErrorCallback(ErrorCallback callback) {
    _errorCallback = callback;
  }
}
