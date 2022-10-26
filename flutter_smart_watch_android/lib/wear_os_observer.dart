import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/models/capability_info.dart';
import 'package:flutter_smart_watch_android/models/message.dart';

typedef CapabilityChangedListener = Function(CapabilityInfo);

class WearOSObserver {
  late StreamController<Message> messageStreamController;
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
    }
  }

  initAllStreamControllers() {
    messageStreamController = StreamController.broadcast();
  }

  clearAllStreamControllers() {
    messageStreamController.close();
  }
}
