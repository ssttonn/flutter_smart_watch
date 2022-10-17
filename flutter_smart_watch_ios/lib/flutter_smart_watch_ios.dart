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
import 'src/models/file_transfer.dart';

export 'src/models/application_context.dart' show ApplicationContext;
export 'src/models/paired_device_info.dart' show PairedDeviceInfo;
export 'src/models/user_info_transfer.dart' show UserInfoTransfer;
export 'src/enums/activate_state.dart' show ActivationState;
export 'src/models/file_transfer.dart' show FileTransfer;

class FlutterSmartWatchIos extends FlutterSmartWatchPlatformInterface {
  static registerWith() {
    FlutterSmartWatchPlatformInterface.instance = FlutterSmartWatchIos();
  }

  late WatchOSObserver _watchOSObserver;

  @override
  Future initialize() async {
    _watchOSObserver = WatchOSObserver();
    _watchOSObserver.initAllStreamControllers();
    if (!(await _isSmartWatchSupported())) {
      throw PlatformException(
          code: "400",
          message:
              "Your device does not support connecting to a WatchOS device.");
    }
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
      _watchOSObserver.replyHandlers[handlerId] = replyHandler;
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

  /// Transfer user information.
  ///
  /// Returns [UserInfoTransfer] representing this transfer.
  ///
  /// You can cancel this transfer after creation using [cancelOnProgressUserInfoTransfer]
  Future<UserInfoTransfer?> transferUserInfo(Map<String, dynamic> userInfo,
      {bool isComplication = false}) async {
    userInfo["id"] = getRandomString(20);
    var _rawUserInfoTransfer = await channel.invokeMethod("transferUserInfo",
        {"userInfo": userInfo, "isComplication": isComplication});
    if (_rawUserInfoTransfer != null && _rawUserInfoTransfer is Map) {
      _rawUserInfoTransfer = _rawUserInfoTransfer.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value));
      if (_rawUserInfoTransfer.containsKey("userInfo") &&
          _rawUserInfoTransfer["userInfo"] is Map) {
        Map<String, dynamic> userInfoInJson =
            (_rawUserInfoTransfer["userInfo"] as Map)
                .map((key, value) => MapEntry(key.toString(), value));
        if (userInfoInJson.containsKey("id")) {
          _rawUserInfoTransfer["id"] = (userInfoInJson["id"] ?? "").toString();
          (_rawUserInfoTransfer["userInfo"] as Map).remove("id");
        }
      }
      return UserInfoTransfer.fromJson(
          _rawUserInfoTransfer.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value)));
    }
    return null;
  }

  Future cancelOnProgressUserInfoTransfer(String transferId) {
    return channel.invokeMethod("cancelUserInfoTransfer", transferId);
  }

  /// Retrieve pending user info transfers.
  ///
  /// Call this method to retrieve all on progress user info transfers.
  ///
  /// You can cancel any transfer by using [cancelOnProgressUserInfoTransfer]
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

  ///Transfer a [File] to WatchOS companion app
  ///
  ///You can track the transfering progress implicitly with [onProgressChanged] handler.
  ///
  ///Return a [FileTransfer]
  Future<FileTransfer?> transferFileInfo(File file,
      {ProgressHandler? onProgressChanged,
      Map<String, dynamic> metadata = const {}}) async {
    String? handlerId;
    Map<String, dynamic> mMetadata = new Map<String, dynamic>.from(metadata);
    if (onProgressChanged != null) {
      handlerId = getRandomString(20);
      _watchOSObserver.progressHandlers[handlerId] = onProgressChanged;
    }
    mMetadata["id"] = getRandomString(20);
    var _rawFileTransferInMap = await channel.invokeMethod("transferFileInfo", {
      "filePath": file.path,
      "metadata": mMetadata,
      if (handlerId != null) "progressHandlerId": handlerId
    });
    if (_rawFileTransferInMap != null && _rawFileTransferInMap is Map) {
      Map<String, dynamic> fileTransferInJson = _rawFileTransferInMap
          .map((key, value) => MapEntry(key.toString(), value));
      if (fileTransferInJson.containsKey("metadata") &&
          fileTransferInJson["metadata"] is Map) {
        Map<String, dynamic> _metadataInJson =
            (fileTransferInJson["metadata"] as Map)
                .map((key, value) => MapEntry(key.toString(), value));
        fileTransferInJson["id"] = _metadataInJson["id"];
        _metadataInJson.remove("id");
      }
      return FileTransfer.fromJson(fileTransferInJson);
    }
    return null;
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
  Stream<File> get fileStream =>
      _watchOSObserver.fileInfoStreamController.stream;

  @override
  void dispose() {
    _watchOSObserver.clearAllStreamControllers();
  }
}
