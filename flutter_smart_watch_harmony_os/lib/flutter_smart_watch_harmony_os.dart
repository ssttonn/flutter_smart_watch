import 'dart:async';
import 'dart:io';

import 'package:flutter_smart_watch_harmony_os/harmonyos_observer.dart';
import 'package:flutter_smart_watch_harmony_os/helpers/enums.dart';
import 'package:flutter_smart_watch_harmony_os/models/harmony_device.dart';
import 'package:flutter_smart_watch_harmony_os/models/monitor_data.dart';
import 'package:flutter_smart_watch_harmony_os/models/notification.dart';
import 'package:flutter_smart_watch_harmony_os/models/wear_engine_message.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

import 'channel.dart';

class FlutterSmartWatchHarmonyOs extends FlutterSmartWatchPlatformInterface {
  static registerWith() {
    FlutterSmartWatchPlatformInterface.instance = FlutterSmartWatchHarmonyOs();
  }

  late HarmonyOsObserver _harmonyOsObserver;

  ///Call this method first to configure all the necessary dependencies for WearEngineAPI.
  ///
  ///[companionAppPackageName] = The package name of your wearable app to be communicated with.
  ///
  ///[companionAppFingerprint] = The signing certificate fingerprint of your wearable app to be communicated with. See [Obtaining a Signing Certificate Fingerprint on the Wearable Device](https://developer.huawei.com/consumer/en/doc/development/connectivity-Guides/signature-0000001053969657)
  Future<void> configure(
      {String? companionAppPackageName, String? companionAppFingerprint}) {
    _harmonyOsObserver = HarmonyOsObserver();
    return channel.invokeMethod("configure", {
      "companionPackageName": companionAppPackageName,
      "companionAppFingerprint": companionAppFingerprint
    });
  }

  ///Call this method to detect connected wearable devices (Wearable devices that are connected to the Huawei Health app and support Wear Engine).
  ///
  ///This method returns a [bool] result indicating whether or not a device is connected to WearEngine service.
  Future<bool> hasAvailableDevices() {
    return channel
        .invokeMethod("hasAvailableDevices")
        .then((result) => result ?? false);
  }

  ///Listen to this stream for connection status between your phone app and WearEngineAPI
  Stream<ConnectionState> connectionStateChanged() async* {
    await _removeConnectionListener();
    if (_harmonyOsObserver.connectionStateChangedStreamController == null) {
      _harmonyOsObserver.connectionStateChangedStreamController =
          StreamController.broadcast();
    }
    await channel.invokeMethod("addServiceConnectionListener");
    yield* _harmonyOsObserver.connectionStateChangedStreamController!.stream;
  }

  /// Cancel the monitoring of the connection status between your app and WearEngineAPI.
  Future<void> _removeConnectionListener() {
    if (_harmonyOsObserver.connectionStateChangedStreamController != null) {
      _harmonyOsObserver.connectionStateChangedStreamController?.close();
      _harmonyOsObserver.connectionStateChangedStreamController = null;
    }
    return channel.invokeMethod("removeServiceConnectionListener");
  }

  ///Call this method to disconnect your app from WearEngineAPI.
  Future<void> closeConnection() {
    return channel.invokeMethod("releaseConnection");
  }

  ///Get highest client API level
  ///
  ///This method returns an [int] for the API level value
  Future<int?> getClientApiLevel() {
    return channel.invokeMethod("getClientApiLevel");
  }

  ///Get current WearEngine API level
  ///
  ///This method returns an [int] for the API level value
  Future<int?> getWearEngineApiLevel() {
    return channel.invokeMethod("getServiceApiLevel");
  }

  ///Use this method to check if specific permission is granted by user.
  ///
  ///This method accepts [WearEnginePermission] enum value.
  ///
  ///This method returns a [bool] value to indicate whether the corresponding [WearEnginePermission] is granted or not.
  Future<bool> checkPermission(WearEnginePermission permission) {
    return channel.invokeMethod("checkWearEnginePermission",
        {"permissionIndex": permission.index}).then((isGranted) {
      return isGranted ?? false;
    });
  }

  ///Use this method to check if the user has granted a specific set of permissions.
  ///
  ///This method accepts a [List] of [WearEnginePermission].
  ///
  ///This method returns a [Map] with [WearEnginePermission] keys and [bool] values to indicate whether the corresponding [WearEnginePermission] key is granted or not.
  Future<Map<WearEnginePermission, bool>> checkPermissions(
      List<WearEnginePermission> permissions) {
    return channel.invokeMethod("checkWearEnginePermissions", {
      "permissionIndexes":
          permissions.map((permission) => permission.index).toList()
    }).then((permissionResult) {
      return (permissionResult as Map? ?? {}).map(
          (key, value) => MapEntry(WearEnginePermission.values[key], value));
    });
  }

  /// Call this method to ask the user to grant the specified permissions.
  ///
  /// This method accepts the following arguments:
  ///
  /// - A [List] of [WearEnginePermission] that needed to be requested.
  ///
  /// - A [PermissionGrantedCallback] to indicate whether the requested permissions have been granted.
  ///
  /// - A [PermissionCancelledCallback] to indicate whether the user canceled the session or not.
  Future<void> requestPermissions(
      {required List<WearEnginePermission> permissions,
      required PermissionGrantedCallback onPermissionGranted,
      required PermissionCancelledCallback onCancelled}) {
    String requestId = getRandomString(100);
    return channel.invokeMethod("requestPermissions", {
      "requestId": requestId,
      "permissionIndexes":
          permissions.map((permission) => permission.index).toList()
    }).then((_) {
      _harmonyOsObserver.permissionGrantedCallbacks[requestId] =
          onPermissionGranted;
      _harmonyOsObserver.permissionCancelledCallbacks[requestId] = onCancelled;
    });
  }

  /// Call the getBondedDevices method to obtain the paired device list.
  ///
  /// Only wearable devices that support app-to-app message communications can be obtained using the [getBondedDevices] method. Those do not support this capability but support other capabilities of the WearEngine can be obtained using the [getCommonDevices] method.
  ///
  /// This methods return a [List] of [WearEngineDevice]
  ///
  /// For details about the device information, refer to the [WearEngineDevice] object.
  Future<List<WearEngineDevice>> getBondedDevices() {
    return channel.invokeMethod("getBoundedDevices").then((rawDevices) {
      return (rawDevices as List? ?? [])
          .map((rawDevice) => fromRawDevice(rawDevice))
          .toList();
    });
  }

  /// Call the getBondedDevices method to obtain the paired device list.
  ///
  /// Only wearable devices that support app-to-app message communications can be obtained using the [getBondedDevices] method. Those do not support this capability but support other capabilities of the WearEngine can be obtained using the [getCommonDevices] method.
  ///
  /// This methods return a [List] of [WearEngineDevice]
  ///
  /// For details about the device information, refer to the [WearEngineDevice] object.
  Future<List<WearEngineDevice>> getCommonDevices() {
    return channel.invokeMethod("getCommonDevices").then((rawDevices) {
      return (rawDevices as List? ?? []).map((rawDevice) {
        return fromRawDevice(rawDevice);
      }).toList();
    });
  }

  Future<DeviceCapabilityStatus> _checkForDeviceCapability(
      {required String deviceUUID, required int queryId}) {
    return channel.invokeMethod("checkForDeviceCapability",
        {"deviceUUID": deviceUUID, "queryId": queryId}).then((statusIndex) {
      return DeviceCapabilityStatus.values[statusIndex ?? 2];
    });
  }

  Future<int> _getAvailableStorageSize({required String deviceUUID}) {
    return channel.invokeMethod("getAvailableKBytes",
        {"deviceUUID": deviceUUID}).then((kBytes) => kBytes ?? 0);
  }

  Future<MonitorData> _queryForMonitorData(
      {required MonitorItem item, required String deviceUUID}) {
    return channel.invokeMethod("queryForMonitorData", {
      "deviceUUID": deviceUUID,
      "monitorItemIndex": item.index
    }).then((rawData) {
      return MonitorData.fromJson(rawData);
    });
  }

  Stream<Pair<MonitorItem, MonitorData>> _registerMonitorListener(
      {required String deviceUUID, required List<MonitorItem> items}) async* {
    await _removeMonitorListener(deviceUUID: deviceUUID);
    if (_harmonyOsObserver.monitorDataChangedStreamController == null) {
      _harmonyOsObserver.monitorDataChangedStreamController =
          StreamController.broadcast();
    }
    await channel.invokeMethod("registerMonitorListener", {
      "deviceUUID": deviceUUID,
      "monitorItemIndexes": items.map((item) => item.index).toList()
    });
    yield* _harmonyOsObserver.monitorDataChangedStreamController!.stream;
  }

  Future<void> _removeMonitorListener({required String deviceUUID}) {
    if (_harmonyOsObserver.monitorDataChangedStreamController != null) {
      _harmonyOsObserver.monitorDataChangedStreamController?.close();
      _harmonyOsObserver.monitorDataChangedStreamController = null;
    }
    return channel
        .invokeMethod("removeMonitorListener", {"deviceUUID": deviceUUID});
  }

  Future<bool> _isCompanionAppInstalled({required String deviceUUID}) {
    return channel.invokeMethod("isCompanionAppInstalled",
        {"deviceUUID": deviceUUID}).then((result) => result ?? false);
  }

  Future<int?> _getCompanionAppVersion({required String deviceUUID}) {
    return channel.invokeMethod("getCompanionAppVersion", {
      "deviceUUID": deviceUUID
    }).then((version) => version == -1 ? null : version);
  }

  Future<void> _checkForCompanionAppRunningStatus(
      {required String deviceUUID, required ReplyReceived onReplyReceived}) {
    String pingId = getRandomString(100);
    _harmonyOsObserver.replyReceivedCallbacks[pingId] = onReplyReceived;
    return channel.invokeMethod("checkForCompanionAppRunningStatus",
        {"deviceUUID": deviceUUID, "pingId": pingId});
  }

  Future<WearEngineMessage> _sendMessage(
      {required String deviceUUID,
      required Map<String, dynamic> data,
      required MessageResultReceived onSendResultReceived,
      required MessageSendProgressChanged onSendProgressChanged,
      String description = "",
      bool enableEncrypt = true}) {
    String sendId = getRandomString(100);
    _harmonyOsObserver.messageResultReceivedCallbacks[sendId] =
        onSendResultReceived;
    _harmonyOsObserver.messageSendProgressChangedCallbacks[sendId] =
        onSendProgressChanged;
    return channel.invokeMethod("sendNormalMessage", {
      "sendId": sendId,
      "data": data,
      "messageDescription": description,
      "enableEncrypt": enableEncrypt,
      "deviceUUID": deviceUUID
    }).then((_) {
      return WearEngineMessage(
          data: data,
          type: MessageType.data,
          isEnableEncrypt: enableEncrypt,
          description: description);
    });
  }

  Future<WearEngineMessage> _sendFile(
      {required String deviceUUID,
      required File file,
      required MessageResultReceived onSendResultReceived,
      required MessageSendProgressChanged onSendProgressChanged,
      String description = "",
      bool enableEncrypt = true}) {
    String sendId = getRandomString(100);
    _harmonyOsObserver.messageResultReceivedCallbacks[sendId] =
        onSendResultReceived;
    _harmonyOsObserver.messageSendProgressChangedCallbacks[sendId] =
        onSendProgressChanged;
    return channel.invokeMethod("sendNormalMessage", {
      "sendId": sendId,
      "filePath": file.path,
      "messageDescription": description,
      "enableEncrypt": enableEncrypt,
      "deviceUUID": deviceUUID
    }).then((_) {
      return WearEngineMessage(
          file: file,
          type: MessageType.data,
          isEnableEncrypt: enableEncrypt,
          description: description);
    });
  }

  Stream<WearEngineMessage> _registerMessageListener(
      {required String deviceUUID}) async* {
    await _removeMessageListener(deviceUUID: deviceUUID);
    if (!_harmonyOsObserver.messageReceivedStreamControllers
            .containsKey(deviceUUID) ||
        _harmonyOsObserver.messageReceivedStreamControllers[deviceUUID] ==
            null) {
      _harmonyOsObserver.messageReceivedStreamControllers[deviceUUID] =
          StreamController.broadcast();
    }
    await channel.invokeMethod(
        "registerMessageReceivedListener", {"deviceUUID": deviceUUID});
    yield* _harmonyOsObserver
        .messageReceivedStreamControllers[deviceUUID]!.stream;
  }

  Future<void> _removeMessageListener({required String deviceUUID}) {
    return channel.invokeMethod(
        "removeMessageReceivedListener", {"deviceUUID": deviceUUID});
  }

  Future<void> _sendNotification(
      {required String deviceUUID,
      required WearEngineNotificationSendOptions options,
      required NotificationResultReceived notificationResultReceived,
      required NoticationErrorDidHappen noticationErrorDidHappen}) {
    String sendId = getRandomString(100);
    return channel
        .invokeMethod("sendNotification")
        .then((value) => WearEngineNotification.fromNotifcationOptions(options))
        .then((_) {
      _harmonyOsObserver.notificationResultReceivedCallbacks[sendId] =
          notificationResultReceived;
      _harmonyOsObserver.notificationErrorDidHappenCallbacks[sendId] =
          noticationErrorDidHappen;
    });
  }

  WearEngineDevice fromRawDevice(Map<String, dynamic> rawDevice) {
    WearEngineDevice _device = WearEngineDevice.fromJson(rawDevice);
    _device.checkForDeviceCapability = ({int queryId = 128}) =>
        _checkForDeviceCapability(deviceUUID: _device.uuid, queryId: queryId);
    _device.getAvailableStorageSize =
        () => _getAvailableStorageSize(deviceUUID: _device.uuid);
    _device.queryMonitorItem = ({required MonitorItem monitorItem}) =>
        _queryForMonitorData(item: monitorItem, deviceUUID: _device.uuid);
    _device.monitorItemsChanged = ({required List<MonitorItem> items}) =>
        _registerMonitorListener(deviceUUID: _device.uuid, items: items);
    _device.isCompanionAppInstalled =
        () => _isCompanionAppInstalled(deviceUUID: _device.uuid);
    _device.getCompanionAppVersion =
        () => _getCompanionAppVersion(deviceUUID: _device.uuid);
    _device.checkForCompanionAppRunningStatus = (
            {required ReplyReceived onReplyReceived}) =>
        _checkForCompanionAppRunningStatus(
            deviceUUID: _device.uuid, onReplyReceived: onReplyReceived);
    _device.sendMessage = (
            {required Map<String, dynamic> data,
            required MessageResultReceived onSendResultReceived,
            required MessageSendProgressChanged onSendProgressChanged,
            String description = "",
            bool enableEncrypt = true}) =>
        _sendMessage(
            deviceUUID: _device.uuid,
            data: data,
            enableEncrypt: enableEncrypt,
            description: description,
            onSendResultReceived: onSendResultReceived,
            onSendProgressChanged: onSendProgressChanged);
    _device.sendFile = (
            {required File file,
            required MessageResultReceived onSendResultReceived,
            required MessageSendProgressChanged onSendProgressChanged,
            String description = "",
            bool enableEncrypt = true}) =>
        _sendFile(
            deviceUUID: _device.uuid,
            file: file,
            enableEncrypt: enableEncrypt,
            description: description,
            onSendResultReceived: onSendResultReceived,
            onSendProgressChanged: onSendProgressChanged);
    _device.messageReceived =
        () => _registerMessageListener(deviceUUID: _device.uuid);
    _device.sendNotification = ((
            {required String deviceUUID,
            required WearEngineNotificationSendOptions options,
            required NotificationResultReceived notificationResultReceived,
            required NoticationErrorDidHappen noticationErrorDidHappen}) =>
        _sendNotification(
            deviceUUID: deviceUUID,
            options: options,
            notificationResultReceived: notificationResultReceived,
            noticationErrorDidHappen: noticationErrorDidHappen));
    return _device;
  }
}
