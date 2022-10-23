import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_ios/channel.dart';
import 'package:flutter_smart_watch_ios/src/models/application_context.dart';
import 'package:flutter_smart_watch_ios/src/models/message.dart';
import 'package:flutter_smart_watch_ios/src/models/paired_device_info.dart';
import 'package:flutter_smart_watch_ios/src/models/user_info_transfer.dart';

import 'src/enums/activate_state.dart';
import 'src/models/error.dart';
import 'src/models/file_transfer.dart';

typedef MessageReplyHandler = Future<void> Function(
    Map<String, dynamic> message);

typedef ProgressHandler = Function(double);

class WatchOSObserver {
  late StreamController<ActivationState> activateStateStreamController;
  late StreamController<PairedDeviceInfo> pairedDeviceInfoStreamController;
  late StreamController<Message> messageStreamController;
  late StreamController<bool> reachabilityStreamController;
  late StreamController<ApplicationContext> applicationContextStreamController;
  late StreamController<Map<String, dynamic>> userInfoStreamController;
  late StreamController<List<UserInfoTransfer>>
      onProgressUserInfoTransferListStreamController;
  late StreamController<UserInfoTransfer>
      userInfoTransferFinishedStreamController;
  late StreamController<Map<String, dynamic>> fileInfoStreamController;
  late StreamController<List<FileTransfer>>
      onProgressFileTransferListStreamController;
  late StreamController<FileTransfer> fileTransferDidFinishStreamController;
  late StreamController<MainError> errorStreamController;
  late Map<String, MessageReplyHandler> replyHandlers;
  late Map<String, ProgressHandler> progressHandlers;

  WatchOSObserver() {
    callbackChannel.setMethodCallHandler(_methodCallhandler);
  }

  Future _methodCallhandler(MethodCall call) async {
    switch (call.method) {
      case "activateStateChanged":
        if (call.arguments != null && call.arguments is int)
          activateStateStreamController
              .add(ActivationState.values[call.arguments]);
        break;
      case "pairDeviceInfoChanged":
        if (call.arguments != null) {
          try {
            Map<String, dynamic> argumentsInJson = jsonDecode(call.arguments);
            PairedDeviceInfo _pairedDeviceInfo =
                PairedDeviceInfo.fromJson(argumentsInJson);
            pairedDeviceInfoStreamController.add(_pairedDeviceInfo);
          } catch (e) {
            errorStreamController
                .add(MainError(message: e.toString(), statusCode: 500));
          }
        }
        break;
      case "messageReceived":
        if (call.arguments != null && call.arguments is Map) {
          try {
            Map<String, dynamic> messageData =
                json.decode(json.encode(call.arguments["message"]))
                    as Map<String, dynamic>;
            String? replyHandlerId = call.arguments["replyHandlerId"];
            Message message = Message(
                data: messageData,
                onReply: ((message) {
                  return channel.invokeMethod("replyMessage", {
                    "replyMessage": message,
                    "replyHandlerId": replyHandlerId
                  });
                }));
            messageStreamController.add(message);
          } catch (e) {
            errorStreamController
                .add(MainError(message: e.toString(), statusCode: 500));
          }
        }
        break;
      case "reachabilityChanged":
        if (call.arguments != null && call.arguments is bool) {
          reachabilityStreamController.add(call.arguments);
        }
        break;
      case "onMessageReplied":
        var arguments = call.arguments;
        if (arguments != null) {
          Map? _replyMessage = arguments["replyMessage"] as Map?;
          String? _replyMessageId = arguments["replyHandlerId"] as String?;
          if (_replyMessage != null && _replyMessageId != null) {
            replyHandlers[_replyMessageId]?.call(_replyMessage
                .map((key, value) => MapEntry(key.toString(), value)));
            replyHandlers.remove(_replyMessageId);
          }
        }
        break;
      case "onApplicationContextUpdated":
        var arguments = call.arguments;
        if (arguments != null && arguments is Map) {
          var applicationContext = ApplicationContext.fromJson(
              arguments.map((key, value) => MapEntry(key.toString(), value)));
          applicationContextStreamController.add(applicationContext);
        }
        break;
      case "onUserInfoReceived":
        var arguments = call.arguments;
        if (arguments != null && arguments is Map) {
          var userInfo =
              arguments.map((key, value) => MapEntry(key.toString(), value));
          userInfoStreamController.add(userInfo);
        }
        break;
      case "onPendingUserInfoTransferListChanged":
        var arguments = call.arguments;
        if (arguments != null &&
            arguments is List &&
            arguments.every((transfer) => transfer is Map)) {
          List<UserInfoTransfer> _transfers = arguments.map((transferJson) {
            return _mapIdAndConvertUserInfoTransfer((transferJson as Map)
                .map((key, value) => MapEntry(key.toString(), value)));
          }).toList();
          onProgressUserInfoTransferListStreamController.add(_transfers);
        }
        break;
      case "onUserInfoTransferDidFinish":
        var arguments = call.arguments;
        if (arguments != null && arguments is Map) {
          UserInfoTransfer _userInfoTransfer = _mapIdAndConvertUserInfoTransfer(
              arguments.map((key, value) => MapEntry(key.toString(), value)));
          userInfoTransferFinishedStreamController.add(_userInfoTransfer);
        }
        break;
      case "onFileReceived":
        var arguments = call.arguments;
        if (arguments != null &&
            arguments is Map &&
            arguments["path"] != null) {
          //* get received file from path
          var _receivedFile = File(arguments["path"]);

          // * add received file to global stream
          fileInfoStreamController.add({
            "file": _receivedFile,
            if (arguments["metadata"] != null) "metadata": arguments["metadata"]
          });
        }
        break;
      case "onPendingFileTransferListChanged":
        var arguments = call.arguments;
        if (arguments != null &&
            arguments is List &&
            arguments.every((transfer) => transfer is Map)) {
          List<FileTransfer> _transfers = arguments.map((transferJson) {
            return _mapIdAndConvertFileTransfer((transferJson as Map)
                .map((key, value) => MapEntry(key.toString(), value)));
          }).toList();
          onProgressFileTransferListStreamController.add(_transfers);
        }
        break;
      case "onFileTransferDidFinish":
        var arguments = call.arguments;
        if (arguments != null && arguments is Map) {
          FileTransfer _fileTransfer = _mapIdAndConvertFileTransfer(
              arguments.map((key, value) => MapEntry(key.toString(), value)));
          fileTransferDidFinishStreamController.add(_fileTransfer);
        }
        break;

      // case "onFileProgressChanged":
      //   var arguments = call.arguments;
      //   if (arguments != null && arguments is Map) {
      //     var handlerId = arguments["progressHandlerId"];
      //     var currentProgress = arguments["currentProgress"] as int? ?? 0;
      //     // * add received file to global stream
      //     progressHandlers[handlerId]?.call(currentProgress.toDouble());
      //   }
      //   break;
      case "onError":
        if (call.arguments != null) {
          errorStreamController
              .add(MainError(message: call.arguments, statusCode: 500));
        }
        break;
    }
  }

  UserInfoTransfer _mapIdAndConvertUserInfoTransfer(Map<String, dynamic> json) {
    if (json.containsKey("userInfo") && json["userInfo"] is Map) {
      Map<String, dynamic> userInfoInJson = (json["userInfo"] as Map)
          .map((key, value) => MapEntry(key.toString(), value));
      if (userInfoInJson.containsKey("id")) {
        json["id"] = (userInfoInJson["id"] ?? "").toString();
        (json["userInfo"] as Map).remove("id");
      }
    }
    UserInfoTransfer _userInfoTransfer = UserInfoTransfer.fromJson(json);
    _userInfoTransfer.cancel = () =>
        channel.invokeMethod("cancelUserInfoTransfer", _userInfoTransfer.id);
    return _userInfoTransfer;
  }

  FileTransfer _mapIdAndConvertFileTransfer(Map<String, dynamic> json) {
    if (json.containsKey("metadata") && json["metadata"] is Map) {
      Map<String, dynamic> _metadataInJson = (json["metadata"] as Map)
          .map((key, value) => MapEntry(key.toString(), value));
      json["id"] = _metadataInJson["id"];
      _metadataInJson.remove("id");
    }
    FileTransfer _fileTransfer = FileTransfer.fromJson(json);
    _fileTransfer.cancel =
        () => channel.invokeMethod("cancelFileTransfer", _fileTransfer.id);
    return _fileTransfer;
  }

  initAllStreamControllers() {
    activateStateStreamController = StreamController.broadcast();
    pairedDeviceInfoStreamController = StreamController.broadcast();
    messageStreamController = StreamController.broadcast();
    reachabilityStreamController = StreamController.broadcast();
    applicationContextStreamController = StreamController.broadcast();
    userInfoStreamController = StreamController.broadcast();
    onProgressUserInfoTransferListStreamController =
        StreamController.broadcast();
    userInfoTransferFinishedStreamController = StreamController.broadcast();
    errorStreamController = StreamController.broadcast();
    fileInfoStreamController = StreamController.broadcast();
    onProgressFileTransferListStreamController = StreamController.broadcast();
    fileTransferDidFinishStreamController = StreamController.broadcast();
    replyHandlers = new Map();
    progressHandlers = new Map();
  }

  clearAllStreamControllers() {
    activateStateStreamController.close();
    pairedDeviceInfoStreamController.close();
    messageStreamController.close();
    reachabilityStreamController.close();
    applicationContextStreamController.close();
    userInfoStreamController.close();
    errorStreamController.close();
    userInfoTransferFinishedStreamController.close();
    onProgressUserInfoTransferListStreamController.close();
    fileInfoStreamController.close();
    onProgressFileTransferListStreamController.close();
    fileTransferDidFinishStreamController.close();
    replyHandlers.clear();
    progressHandlers.clear();
  }
}
