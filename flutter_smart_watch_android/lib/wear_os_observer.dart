import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/models/capability_info.dart';
import 'package:flutter_smart_watch_android/models/data_event.dart';
import 'package:flutter_smart_watch_android/models/message.dart';

typedef CapabilityChangedListener = Function(CapabilityInfo);
typedef MessageReceivedListener = Function(Message);
typedef DataChangedListener = Function(List<DataEvent>);

class WearOSObserver {
  Map<String, CapabilityChangedListener> capabilityListeners = Map();
  Map<String, MessageReceivedListener> messageReceivedListeners = new Map();
  Map<String, DataChangedListener> dataChangedListeners = new Map();

  WearOSObserver() {
    callbackChannel.setMethodCallHandler(_methodCallhandler);
  }

  Future _methodCallhandler(MethodCall call) async {
    switch (call.method) {
      case "onCapabilityChanged":
        CapabilityInfo _capabilityInfo = CapabilityInfo.fromJson(
            (call.arguments["data"] as Map? ?? {})
                .map((key, value) => MapEntry(key.toString(), value)));
        capabilityListeners[call.arguments["key"] ?? ""]?.call(_capabilityInfo);
        break;
      case "onMessageReceived":
        Message _message = Message.fromJson(
            (call.arguments["data"] as Map? ?? {})
                .map((key, value) => MapEntry(key.toString(), value)));
        messageReceivedListeners[call.arguments["key"] ?? ""]?.call(_message);
        break;
      case "onDataChanged":
        List results = call.arguments["data"];
        dataChangedListeners[call.arguments["key"] ?? ""]?.call(results
            .map((result) => DataEvent.fromJson((result as Map? ?? {})
                .map((key, value) => MapEntry(key.toString(), value))))
            .toList());
        break;
    }
  }
}
