import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/models/node.dart';

class WearOSObserver {
  late StreamController<Set<Node>> connectedNodesStreamController;
  WearOSObserver() {
    callbackChannel.setMethodCallHandler(_methodCallhandler);
  }

  Future _methodCallhandler(MethodCall call) async {
    switch (call.method) {
      case "connectedNodesChanged":
        if (call.arguments != null && call.arguments is List<Map>) {
          Set<Node> _connectedNodes = (call.arguments as List<Map>? ?? [])
              .map((rawJson) => Node.fromJson(
                  rawJson.map((key, value) => MapEntry(key.toString(), value))))
              .toSet();
          connectedNodesStreamController.add(_connectedNodes);
        }
        return;
    }
  }

  initAllStreamControllers() {
    connectedNodesStreamController = StreamController.broadcast();
  }

  clearAllStreamControllers() {
    connectedNodesStreamController.close();
  }
}
