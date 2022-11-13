import 'dart:async';

import 'package:flutter_smart_watch_harmony_os/helpers/extensions.dart';
import 'package:flutter_smart_watch_harmony_os/models/monitor_data.dart';
import 'package:flutter_smart_watch_harmony_os/models/notification.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_harmony_os/channel.dart';
import 'package:flutter_smart_watch_harmony_os/helpers/enums.dart';
import 'package:flutter_smart_watch_harmony_os/models/wear_engine_message.dart';

typedef ReplyReceived = void Function(CompanionAppStatus appStatus);
typedef MessageResultReceived = void Function(bool result);
typedef MessageSendProgressChanged = void Function(int currentProgress);
typedef PermissionGrantedCallback = void Function(
    List<WearEnginePermission> permissions);
typedef PermissionCancelledCallback = Function;
typedef NotificationResultReceived = void Function(
    WearEngineNotification notification);
typedef NoticationErrorDidHappen = void Function(
    WearEngineNotification notification, Exception exception);

const MESSAGE_SEND_SUCCESS_CODE = 207;

class HarmonyOsObserver {
  StreamController<ConnectionState>? connectionStateChangedStreamController;

  StreamController<Pair<MonitorItem, MonitorData>>?
      monitorDataChangedStreamController;
  Map<String, StreamController<WearEngineMessage>?>
      messageReceivedStreamControllers = Map();
  Map<String, PermissionGrantedCallback> permissionGrantedCallbacks = Map();
  Map<String, PermissionCancelledCallback> permissionCancelledCallbacks = Map();
  Map<String, ReplyReceived> replyReceivedCallbacks = Map();
  Map<String, MessageResultReceived> messageResultReceivedCallbacks = Map();
  Map<String, MessageSendProgressChanged> messageSendProgressChangedCallbacks =
      Map();
  Map<String, NotificationResultReceived> notificationResultReceivedCallbacks =
      Map();
  Map<String, NoticationErrorDidHappen> notificationErrorDidHappenCallbacks =
      Map();

  HarmonyOsObserver() {
    callbackChannel.setMethodCallHandler(_onMethodCallHandler);
  }

  Future _onMethodCallHandler(MethodCall call) async {
    switch (call.method) {
      case "onConnectionChanged":
        bool connected = call.arguments as bool? ?? false;
        connectionStateChangedStreamController?.add(connected
            ? ConnectionState.connected
            : ConnectionState.disconnected);
        break;
      case "permissionGranted":
        List<int> permissionIndexes =
            call.arguments["permissionIndexes"] as List<int>? ?? [];
        String requestId = call.arguments["requestId"];
        permissionGrantedCallbacks[requestId]?.call(permissionIndexes
            .map((index) => WearEnginePermission.values
                .findElementOrGetFirstItemIfNull(index))
            .toList());
        permissionGrantedCallbacks.remove(requestId);
        permissionCancelledCallbacks.remove(requestId);
        break;
      case "permissionCancelled":
        String requestId = call.arguments["requestId"];
        permissionGrantedCallbacks.remove(requestId);
        permissionCancelledCallbacks.remove(requestId);
        break;
      case "monitorItemChanged":
        try {
          int monitorItemIndex = call.arguments["monitorItemIndex"] as int;
          Map<String, dynamic> rawMonitorData =
              (call.arguments["data"] as Map? ?? {})
                  .map((key, value) => MapEntry(key.toString(), value));
          MonitorItem _monitorItem = MonitorItem.values
              .findElementOrGetFirstItemIfNull(monitorItemIndex);
          MonitorData _monitorData = MonitorData.fromJson(rawMonitorData);
          monitorDataChangedStreamController
              ?.add(Pair(left: _monitorItem, right: _monitorData));
        } catch (e) {
          monitorDataChangedStreamController?.addError(e);
        }
        break;
      case "onConnectedWearableDeviceReplied":
        String pingId = call.arguments["pingId"] as String;
        int statusCode = call.arguments["code"] as int;
        replyReceivedCallbacks[pingId]
            ?.call(statusCode.convertToCompanionAppStatus());
        break;
      case "onMessageSendResultDidCome":
        String sendId = call.arguments["sendId"] as String;
        int resultCode = call.arguments["code"] as int;
        messageResultReceivedCallbacks[sendId]
            ?.call(resultCode == MESSAGE_SEND_SUCCESS_CODE);
        messageResultReceivedCallbacks.remove(sendId);
        messageSendProgressChangedCallbacks.remove(sendId);
        break;
      case "onMessageSendProgressChanged":
        String sendId = call.arguments["sendId"] as String;
        int currentProgress = call.arguments["progress"] as int;
        messageSendProgressChangedCallbacks[sendId]?.call(currentProgress);
        break;
      case "onMessageReceived":
        String deviceUUID = call.arguments["deviceUUID"] as String;
        try {
          Map<String, dynamic> rawMessageData =
              (call.arguments["message"] as Map? ?? {})
                  .map((key, value) => MapEntry(key.toString(), value));
          messageReceivedStreamControllers[deviceUUID]
              ?.add(WearEngineMessage.fromJson(rawMessageData));
        } catch (e) {
          messageReceivedStreamControllers[deviceUUID]?.addError(e);
        }
        break;
      case "onNotificationResult":
        String sendId = call.arguments["sendId"] as String;
        try {
          Map<String, dynamic> rawNotificationData =
              (call.arguments["notifcation"] as Map? ?? {})
                  .map((key, value) => MapEntry(key.toString(), value));
          notificationResultReceivedCallbacks[sendId]
              ?.call(WearEngineNotification.fromJson(rawNotificationData));
        } catch (e) {
          print(e);
        }
        break;
      case "onNotificationError":
        String sendId = call.arguments["sendId"] as String;
        String errorMessage = call.arguments["errorMsg"] as String;
        try {
          Map<String, dynamic> rawNotificationData =
              (call.arguments["notifcation"] as Map? ?? {})
                  .map((key, value) => MapEntry(key.toString(), value));
          notificationErrorDidHappenCallbacks[sendId]?.call(
              WearEngineNotification.fromJson(rawNotificationData),
              Exception(errorMessage));
        } catch (e) {
          print(e);
        }
        break;
    }
  }
}
