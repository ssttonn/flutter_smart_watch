import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_ios/channel.dart';
import 'package:flutter_smart_watch_ios/src/models/application_context.dart';
import 'package:flutter_smart_watch_ios/watch_os_observer.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

import 'src/enums/activate_state.dart';
import 'src/helpers/utils.dart';
import 'src/models/error.dart';
import 'src/models/paired_device_info.dart';
import 'src/models/user_info_transfer.dart';

export 'src/models/application_context.dart' show ApplicationContext;
export 'src/models/paired_device_info.dart' show PairedDeviceInfo;
export 'src/models/user_info_transfer.dart' show UserInfoTransfer;
export 'src/enums/activate_state.dart' show ActivationState;

class FlutterSmartWatchIos extends FlutterSmartWatchPlatformInterface {
  static registerWith() {
    FlutterSmartWatchPlatformInterface.instance = FlutterSmartWatchIos();
  }

  WatchOSObserver _watchOSObserver = WatchOSObserver();

  @override
  Future initialize() async {
    if (!(await _isSmartWatchSupported())) {
      throw PlatformException(
          code: "400",
          message:
              "Your device does not support connecting to a WatchOS device.");
    }

    /// Init all streamcontrollers, ready for event listener
    _watchOSObserver.initAllStreamControllers();
    await _configureAndActivateSession();
  }

  /// Check if your IOS device is supported to connect with WatchOS device
  Future<bool> _isSmartWatchSupported() async {
    bool? isSupported = await channel.invokeMethod("isSupported");
    return isSupported ?? false;
  }

  /// Init and activate [WatchConnectivity] session
  Future _configureAndActivateSession() async {
    return channel.invokeMethod("configure");
  }

  /// Get current [ActivateState] of [WatchConnectivity] session
  Future<ActivationState> getActivateState() async {
    int stateIndex = await channel.invokeMethod("getActivateState");
    return ActivationState.values[stateIndex];
  }

  /// Get paired WatchOS device info
  Future<PairedDeviceInfo> getPairedDeviceInfo() async {
    String jsonString = await channel.invokeMethod("getPairedDeviceInfo");
    Map<String, dynamic> json = jsonDecode(jsonString);
    return PairedDeviceInfo.fromJson(json);
  }

  /// Check whether the WatchOS companion app is in the foreground
  /// If [getReachability] return true, the companion app is in the foreground, otherwise the companion app is in background or is teminated.
  Future<bool> getReachability() async {
    bool isReachable = await channel.invokeMethod("getReachability");
    return isReachable;
  }

  /// Send message to companion app, can only send if [getReachability] is true
  Future sendMessage(Map<String, dynamic> message,
      {MessageReplyHandler? replyHandler}) {
    String? handlerId;
    if (replyHandler != null) {
      handlerId = getRandomString(20);
      _watchOSObserver.handlers[handlerId] = replyHandler;
    }
    return channel.invokeMethod("sendMessage", {
      "message": message,
      if (handlerId != null) "replyHandlerId": handlerId
    });
  }

  /// Return the current [ApplicationContext] context of session
  /// [ApplicationContext] is a map data which is synced across of IOS app and WatchOS app
  Future<ApplicationContext> getApplicationContext() async {
    Map _rawContext = await channel.invokeMethod("getLatestApplicationContext");
    return ApplicationContext.fromJson(
        _rawContext.map((key, value) => MapEntry(key.toString(), value)));
  }

  /// Update and sync the [ApplicationContext].
  /// [ApplicationContext] works like the common data between both WatchOS and IOS app,
  /// which can be updated by calling [updateApplicationContext] method and synced via [applicationContextStream].
  /// You can call this method either the WatchOS companion app is in background or foreground
  Future updateApplicationContext(Map<String, dynamic> applicationContext) {
    return channel.invokeMethod("updateApplicationContext", applicationContext);
  }

  /// Transfer a user info.
  Future transferUserInfo(Map<String, dynamic> userInfo,
      {bool isComplication = false}) {
    return channel.invokeMethod("transferUserInfo",
        {"userInfo": userInfo, "isComplication": isComplication});
  }

  /// Retrieve pending user info transfers.
  Future<List> getOnProgressUserInfoTransfers() {
    return channel
        .invokeMethod("getOnProgressUserInfoTransfers")
        .then((transfers) {
      return transfers ?? [];
    });
  }

  /// Retrieve remaining transfer count, use this method to determine that you should send a [Complication] user info data.
  Future<int> getRemainingComplicationUserInfoTransferCount() async {
    return channel
        .invokeMethod("getRemainingComplicationUserInfoTransferCount")
        .then((count) => count ?? 0);
  }

  Future transferFileInfo(File file,
      {Map<String, dynamic> metadata = const {}}) {
    return channel.invokeMethod(
        "transferFileInfo", {"filePath": file.path, "metadata": metadata});
  }

  Future cancelOnProgressUserInfoTransfer(String transferId) {
    return channel.invokeMethod("cancelUserInfoTransfer", transferId);
  }

  Stream<ActivationState> get activationStateStream =>
      _watchOSObserver.activateStateStreamController.stream;
  Stream<PairedDeviceInfo> get pairedDeviceInfoStream =>
      _watchOSObserver.pairedDeviceInfoStreamController.stream;
  Stream<Map<String, dynamic>> get messageStream =>
      _watchOSObserver.messageStreamController.stream;
  Stream<bool> get reachabilityStream =>
      _watchOSObserver.reachabilityStreamController.stream;
  Stream<ApplicationContext> get applicationContextStream =>
      _watchOSObserver.applicationContextStreamController.stream;
  Stream<Map<String, dynamic>> get userInfoStream =>
      _watchOSObserver.userInfoStreamController.stream;
  Stream<MainError> get errorStream =>
      _watchOSObserver.errorStreamController.stream;
  Stream<List<UserInfoTransfer>> get onProgressUserInfoTransferListStream =>
      _watchOSObserver.onProgressUserInfoTransferListStreamController.stream;
  Stream<UserInfoTransfer> get userInfoTransferDidFinishStream =>
      _watchOSObserver.userInfoTransferFinishedStreamController.stream;

  @override
  void dispose() {
    _watchOSObserver.clearAllStreamControllers();
  }
}
