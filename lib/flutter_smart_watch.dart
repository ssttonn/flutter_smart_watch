library flutter_smart_watch;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch/helpers/utils.dart';
import 'package:flutter_smart_watch/models/error.dart';
import 'package:flutter_smart_watch/models/user_info_transfer.dart';

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
    _initAllStreamControllers();
    _callbackMethodChannel.setMethodCallHandler(_methodCallhandler);
  }

  factory FlutterSmartWatch.getInstance() {
    return _instance;
  }

  final _callbackMethodChannel =
      const MethodChannel("flutter_smart_watch_callback");
  late StreamController<ActivationState> _activateStateStreamController;
  late StreamController<PairedDeviceInfo> _pairedDeviceInfoStreamController;
  late StreamController<Message> _messageStreamController;
  late StreamController<bool> _reachabilityStreamController;
  late StreamController<ApplicationContext> _applicationContextStreamController;
  late StreamController<UserInfo> _userInfoStreamController;
  late StreamController<List<UserInfoTransfer>>
      _onProgressUserInfoTransferListStreamController;
  late StreamController<UserInfoTransfer>
      _userInfoTransferFinishedStreamController;
  late StreamController<MainError> _errorStreamController;
  late Map<String, MessageReplyHandler> _handlers;

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
      case "onUserInfoReceived":
        var arguments = call.arguments;
        if (arguments != null && arguments is Map) {
          var userInfo =
              arguments.map((key, value) => MapEntry(key.toString(), value));
          _userInfoStreamController.add(userInfo);
        }
        break;
      case "onPendingUserInfoTransferListChanged":
        var arguments = call.arguments;
        if (arguments != null &&
            arguments is List &&
            arguments.every((transfer) => transfer is Map)) {
          List<UserInfoTransfer> _transfers = arguments.map((transferJson) {
            return _mapIdAndConvert((transferJson as Map)
                .map((key, value) => MapEntry(key.toString(), value)));
          }).toList();
          _onProgressUserInfoTransferListStreamController.add(_transfers);
        }
        break;
      case "onUserInfoTransferDidFinish":
        var arguments = call.arguments;
        if (arguments != null && arguments is Map) {
          UserInfoTransfer _userInfoTransfer = _mapIdAndConvert(
              arguments.map((key, value) => MapEntry(key.toString(), value)));
          _userInfoTransferFinishedStreamController.add(_userInfoTransfer);
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

  UserInfoTransfer _mapIdAndConvert(Map<String, dynamic> json) {
    if (json.containsKey("userInfo") && json["userInfo"] is Map) {
      Map<String, dynamic> userInfoInJson = (json["userInfo"] as Map)
          .map((key, value) => MapEntry(key.toString(), value));
      if (userInfoInJson.containsKey("id")) {
        json["id"] = (userInfoInJson["id"] ?? "").toString();
        (json["userInfo"] as Map).remove("id");
      }
    }
    return UserInfoTransfer.fromJson(json);
  }

  Future<bool> isSupported() async {
    bool isSupported =
        await _FlutterSmartWatchPlatform.instance.isSmartWatchSupported() ??
            false;
    return isSupported;
  }

  _initAllStreamControllers() {
    _activateStateStreamController = StreamController.broadcast();
    _pairedDeviceInfoStreamController = StreamController.broadcast();
    _messageStreamController = StreamController.broadcast();
    _reachabilityStreamController = StreamController.broadcast();
    _applicationContextStreamController = StreamController.broadcast();
    _userInfoStreamController = StreamController.broadcast();
    _onProgressUserInfoTransferListStreamController =
        StreamController.broadcast();
    _userInfoTransferFinishedStreamController = StreamController.broadcast();
    _errorStreamController = StreamController.broadcast();
    _handlers = new Map();
  }

  Future activate() async {
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

  Future<List<UserInfoTransfer>> getOnProgressUserInfoTransfers() async {
    var rawTransfers = await _FlutterSmartWatchPlatform.instance
        .getOnProgressUserInfoTransfers();
    if (rawTransfers.every((transfer) => transfer is Map)) {
      return rawTransfers.map((transferJson) {
        return _mapIdAndConvert((transferJson as Map)
            .map((key, value) => MapEntry(key.toString(), value)));
      }).toList();
    }
    return [];
  }

  Future<int> getRemainingComplicationUserInfoTransferCount() async {
    return _FlutterSmartWatchPlatform.instance
        .getRemainingComplicationUserInfoTransferCount();
  }

  Future updateApplicationContext(Map<String, dynamic> context) {
    return _FlutterSmartWatchPlatform.instance
        .updateApplicationContext(context);
  }

  Future<UserInfoTransfer?> transferUserInfo(Map<String, dynamic> userInfo,
      {bool isComplication = false}) async {
    userInfo["id"] = getRandomString(20);
    var result = await _FlutterSmartWatchPlatform.instance
        .transferUserInfo(userInfo, isComplication: isComplication);
    if (result != null && result is Map) {
      return _mapIdAndConvert(
          result.map((key, value) => MapEntry(key.toString(), value)));
    }
    return null;
  }

  Future transferFileInfo(File file,
      {Map<String, dynamic> metadata = const {}}) {
    return _FlutterSmartWatchPlatform.instance
        .transferFileInfo(file, metadata: metadata);
  }

  Future cancelOnProgressUserInfoTransfer(String transferId) {
    return _FlutterSmartWatchPlatform.instance
        .cancelOnProgressUserInfoTransfer(transferId);
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
  Stream<List<UserInfoTransfer>> get onProgressUserInfoTransferListStream =>
      _onProgressUserInfoTransferListStreamController.stream;
  Stream<UserInfoTransfer> get userInfoTransferDidFinishStream =>
      _userInfoTransferFinishedStreamController.stream;

  void dispose() {
    _activateStateStreamController.close();
    _pairedDeviceInfoStreamController.close();
    _messageStreamController.close();
    _reachabilityStreamController.close();
    _applicationContextStreamController.close();
    _userInfoStreamController.close();
    _errorStreamController.close();
    _userInfoTransferFinishedStreamController.close();
    _onProgressUserInfoTransferListStreamController.close();
    _handlers.clear();
  }
}
