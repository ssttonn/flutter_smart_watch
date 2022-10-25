import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/models/connected_device_info.dart';

class WearOSObserver {
  late StreamController<Set<DeviceInfo>> connectedNodesStreamController;
  WearOSObserver() {
    callbackChannel.setMethodCallHandler(_methodCallhandler);
  }

  Future _methodCallhandler(MethodCall call) async {
    switch (call.method) {
    }
  }

  initAllStreamControllers() {
    connectedNodesStreamController = StreamController.broadcast();
  }

  clearAllStreamControllers() {
    connectedNodesStreamController.close();
  }
}
