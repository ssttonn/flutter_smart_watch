import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/models/capability_info.dart';
import 'package:flutter_smart_watch_android/models/data_event.dart';
import 'package:flutter_smart_watch_android/models/message.dart';

typedef CapabilityChangedListener = Function(CapabilityInfo);

class WearOSObserver {
  late StreamController<Message> messageStreamController;
  late StreamController<List<DataEvent>> dataEventsStreamController;
  Map<String, CapabilityChangedListener> capabilityListeners = Map();
  WearOSObserver() {
    callbackChannel.setMethodCallHandler(_methodCallhandler);
  }

  Future _methodCallhandler(MethodCall call) async {
    switch (call.method) {
      case "onCapabilityChanged":
        CapabilityInfo _capabilityInfo = CapabilityInfo.fromJson(
            (call.arguments as Map? ?? {})
                .map((key, value) => MapEntry(key.toString(), value)));
        capabilityListeners[_capabilityInfo.name]?.call(_capabilityInfo);
        break;
      case "onMessageReceived":
        Message _message = Message.fromJson((call.arguments as Map? ?? {})
            .map((key, value) => MapEntry(key.toString(), value)));
        messageStreamController.add(_message);
        break;
      case "onDataChanged":
        List results = call.arguments;
        dataEventsStreamController.add(results
            .map((result) => DataEvent.fromJson((result as Map? ?? {})
                .map((key, value) => MapEntry(key.toString(), value))))
            .toList());
        break;
    }
  }

  initAllStreamControllers() {
    messageStreamController = StreamController.broadcast();
    dataEventsStreamController = StreamController.broadcast();
  }

  clearAllStreamControllers() {
    messageStreamController.close();
    dataEventsStreamController.close();
  }
}
