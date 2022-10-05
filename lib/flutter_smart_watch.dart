library flutter_smart_watch;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch/helpers/utils.dart';
import 'package:flutter_smart_watch/models/error.dart';

import 'models/application_context.dart';
import 'models/paired_device_info.dart';

export './flutter_smart_watch.dart';

part 'flutter_smart_watch_method_channel.dart';
part 'flutter_smart_watch_platform_interface.dart';
part "enums/activate_state.dart";

typedef Message = Map<String, dynamic>;

typedef UserInfo = Map<String, dynamic>;

typedef MessageReplyHandler = Function(Message message);

class FlutterSmartWatch {
  static FlutterSmartWatch _instance = FlutterSmartWatch._internal();

  FlutterSmartWatch._internal() {
    _callbackMethodChannel.setMethodCallHandler(_methodCallhandler);
  }

  factory FlutterSmartWatch.getInstance() {
    return _instance;
  }

  final _callbackMethodChannel =
      const MethodChannel("flutter_smart_watch_callback");
  StreamController<ActivationState> _activateStateStreamController =
      StreamController.broadcast();
  StreamController<PairedDeviceInfo> _pairedDeviceInfoStreamController =
      StreamController.broadcast();
  StreamController<Message> _messageStreamController =
      StreamController.broadcast();
  StreamController<bool> _reachabilityStreamController =
      StreamController.broadcast();
  StreamController<ApplicationContext> _applicationContextStreamController =
      StreamController.broadcast();
  StreamController<UserInfo> _userInfoStreamController =
      StreamController.broadcast();
  StreamController<MainError> _errorStreamController =
      StreamController.broadcast();
  Map<String, MessageReplyHandler> _handlers = new Map();

  Future _methodCallhandler(MethodCall call) async {
    switch (call.method) {
      case "activateStateChanged":
        if (call.arguments != null && call.arguments is int)
          _activateStateStreamController
              .add(ActivationState.values[call.arguments]);
        break;
      case "pairDeviceInfoChanged":
        if (call.arguments != null) {
          try {
            Map<String, dynamic> argumentsInJson = jsonDecode(call.arguments);
            PairedDeviceInfo _pairedDeviceInfo =
                PairedDeviceInfo.fromJson(argumentsInJson);
            _pairedDeviceInfoStreamController.add(_pairedDeviceInfo);
          } catch (e) {
            _errorStreamController
                .add(MainError(message: e.toString(), statusCode: 500));
          }
        }
        break;
      case "messageReceived":
        if (call.arguments != null) {
          try {
            Message message =
                json.decode(json.encode(call.arguments)) as Message;
            _messageStreamController.add(message);
          } catch (e) {
            _errorStreamController
                .add(MainError(message: e.toString(), statusCode: 500));
          }
        }
        break;
      case "reachabilityChanged":
        if (call.arguments != null && call.arguments is bool) {
          _reachabilityStreamController.add(call.arguments);
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
          var applicationContext = ApplicationContext.fromJson(
              arguments.map((key, value) => MapEntry(key.toString(), value)));
          _applicationContextStreamController.add(applicationContext);
        }
        break;
      case "onError":
        if (call.arguments != null) {
          _errorStreamController
              .add(MainError(message: call.arguments, statusCode: 500));
        }
        break;
    }
  }

  Future configure() async {
    bool isSupported =
        await _FlutterSmartWatchPlatform.instance.isSmartWatchSupported() ??
            false;
    if (isSupported) {
      await _activate();
    }
  }

  Future _activate() async {
    return _FlutterSmartWatchPlatform.instance.activate();
  }

  Future sendMessage(Message message, {MessageReplyHandler? replyHandler}) {
    String? handlerId;
    if (replyHandler != null) {
      handlerId = getRandomString(20);
      _handlers[handlerId] = replyHandler;
    }
    return _FlutterSmartWatchPlatform.instance
        .sendMessage(message, handlerId: handlerId);
  }

  Future<ApplicationContext> getLatestApplicationContext() {
    return _FlutterSmartWatchPlatform.instance.getLatestApplicationContext();
  }

  Future updateApplicationContext(Map<String, dynamic> context) {
    return _FlutterSmartWatchPlatform.instance
        .updateApplicationContext(context);
  }

  Future<PairedDeviceInfo> getPairedDeviceInfo() {
    return _FlutterSmartWatchPlatform.instance.getPairedDeviceInfo();
  }

  Future<ActivationState> getActivateState() {
    return _FlutterSmartWatchPlatform.instance.getActivateState();
  }

  Future<bool> getReachability() {
    return _FlutterSmartWatchPlatform.instance.getReachability();
  }

  Stream<ActivationState> get activationStateStream =>
      _activateStateStreamController.stream;
  Stream<PairedDeviceInfo> get pairedDeviceInfoStream =>
      _pairedDeviceInfoStreamController.stream;
  Stream<Message> get messageStream => _messageStreamController.stream;
  Stream<bool> get reachabilityStream => _reachabilityStreamController.stream;
  Stream<ApplicationContext> get applicationContextStream =>
      _applicationContextStreamController.stream;
  Stream<UserInfo> get userInfoStream => _userInfoStreamController.stream;
  Stream<MainError> get errorStream => _errorStreamController.stream;

  void dispose() {
    _activateStateStreamController.close();
    _pairedDeviceInfoStreamController.close();
    _messageStreamController.close();
    _reachabilityStreamController.close();
    _applicationContextStreamController.close();
    _userInfoStreamController.close();
    _errorStreamController.close();
  }
}
