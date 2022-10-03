part of flutter_smart_watch;

class _MethodChannelFlutterSmartWatch extends _FlutterSmartWatchPlatform {
  final methodChannel = const MethodChannel('flutter_smart_watch');
  final callbackMethodChannel =
      const MethodChannel("flutter_smart_watch_callback");
  ActiveStateChangeCallback? _activeStateChangeCallback;
  PairDeviceInfoChangeCallback? _pairDeviceInfoChangeCallback;
  MessageReceivedCallback? _messageReceivedCallback;
  ReachabilityChangeCallback? _reachabilityChangeCallback;
  ApplicationContextReceiveCallback? _applicationContextReceiveCallback;
  ErrorCallback? _errorCallback;
  Map<String, MessageReplyHandler> _handlers = new Map();

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
            Message message =
                json.decode(json.encode(call.arguments)) as Message;
            _messageReceivedCallback?.call(message);
          } catch (e) {
            _errorCallback
                ?.call(CurrentError(message: e.toString(), statusCode: 404));
          }
        }
        break;
      case "reachabilityChanged":
        if (call.arguments != null && call.arguments is bool) {
          _reachabilityChangeCallback?.call(call.arguments);
        }
        break;
      case "onMessageReplied":
        var arguments = call.arguments;
        if (arguments != null) {
          Map? _replyMessage = arguments["replyMessage"] as Map?;
          String? _replyMessageId = arguments["replyHandlerId"] as String?;
          if (_replyMessage != null && _replyMessageId != null) {
            _handlers[_replyMessageId]?.call(_replyMessage
                .map((key, value) => MapEntry(key.toString(), value)));
            _handlers.remove(_replyMessageId);
          }
        }
        break;
      case "onApplicationContextReceived":
        var arguments = call.arguments;
        if (arguments != null && arguments is Map) {
          var applicationContext =
              arguments.map((key, value) => MapEntry(key.toString(), value));
          _applicationContextReceiveCallback?.call(applicationContext);
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
  Future<bool> getReachability() async {
    bool isReachable = await methodChannel.invokeMethod("getReachability");
    return isReachable;
  }

  @override
  Future<ApplicationContext> getCurrentApplicationContext() async {
    Map _rawContext = await methodChannel.invokeMethod("getApplicationContext");
    Map<String, dynamic> _applicationContext =
        _rawContext.map((key, value) => MapEntry(key.toString(), value));
    return _applicationContext;
  }

  @override
  Future sendMessage(Message message, {MessageReplyHandler? replyHandler}) {
    String? handlerId;
    if (replyHandler != null) {
      handlerId = getRandomString(20);
      _handlers[handlerId] = replyHandler;
    }
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
  void listenToReachability(ReachabilityChangeCallback callback) {
    _reachabilityChangeCallback = callback;
  }

  @override
  void listenToApplicationContext(ApplicationContextReceiveCallback callback) {
    _applicationContextReceiveCallback = callback;
  }

  @override
  void listenToErrorCallback(ErrorCallback callback) {
    _errorCallback = callback;
  }
}
