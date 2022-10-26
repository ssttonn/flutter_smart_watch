import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/models/capability_info.dart';
import 'package:flutter_smart_watch_android/models/connected_device_info.dart';

typedef CapabilityChangedListener = Function(CapabilityInfo);

class WearOSObserver {
  late StreamController<Set<DeviceInfo>> connectedNodesStreamController;
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
    }
  }

  initAllStreamControllers() {
    connectedNodesStreamController = StreamController.broadcast();
  }

  clearAllStreamControllers() {
    connectedNodesStreamController.close();
  }
}
