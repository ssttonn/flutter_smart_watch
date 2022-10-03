library flutter_smart_watch;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch/helpers/utils.dart';
import 'package:flutter_smart_watch/models/error.dart';

import 'models/paired_device_info.dart';

export './flutter_smart_watch.dart';

part 'flutter_smart_watch_method_channel.dart';
part 'flutter_smart_watch_platform_interface.dart';
part "enums/activate_state.dart";

typedef Message = Map<String, dynamic>;

typedef ApplicationContext = Map<String, dynamic>;

typedef ActiveStateChangeCallback = Function(ActivateState activateState);

typedef PairDeviceInfoChangeCallback = Function(
    PairedDeviceInfo pairedDeviceInfo);

typedef ReachabilityChangeCallback = Function(bool);

typedef ErrorCallback = Function(CurrentError error);

typedef MessageReceivedCallback = Function(Message message);

typedef MessageReplyHandler = MessageReceivedCallback;

typedef ApplicationContextReceiveCallback = Function(
    ApplicationContext context);

class FlutterSmartWatch {
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
    return _FlutterSmartWatchPlatform.instance
        .sendMessage(message, replyHandler: replyHandler);
  }

  Future<ApplicationContext> getCurrentApplicationContext() {
    return _FlutterSmartWatchPlatform.instance.getCurrentApplicationContext();
  }

  Future updateApplicationContext(ApplicationContext context) {
    return _FlutterSmartWatchPlatform.instance
        .updateApplicationContext(context);
  }

  Future<PairedDeviceInfo> getPairedDeviceInfo() {
    return _FlutterSmartWatchPlatform.instance.getPairedDeviceInfo();
  }

  Future<ActivateState> getActivateState() {
    return _FlutterSmartWatchPlatform.instance.getActivateState();
  }

  Future<bool> getReachability() {
    return _FlutterSmartWatchPlatform.instance.getReachability();
  }

  void listenToActivateStateChanged(ActiveStateChangeCallback callback) {
    _FlutterSmartWatchPlatform.instance.listenToActivateStateChanged(callback);
  }

  void listenToPairedDeviceInfoChanged(PairDeviceInfoChangeCallback callback) {
    _FlutterSmartWatchPlatform.instance
        .listenToPairedDeviceInfoChanged(callback);
  }

  void onMessageReceived(MessageReceivedCallback callback) {
    _FlutterSmartWatchPlatform.instance.listenToMessageReceiveEvent(callback);
  }

  void onReachabilityChanged(ReachabilityChangeCallback callback) {
    _FlutterSmartWatchPlatform.instance.listenToReachability(callback);
  }

  void onApplicationContextReceived(
      ApplicationContextReceiveCallback callback) {
    _FlutterSmartWatchPlatform.instance.listenToApplicationContext(callback);
  }

  void listenToError(ErrorCallback callback) {
    _FlutterSmartWatchPlatform.instance.listenToErrorCallback(callback);
  }
}
