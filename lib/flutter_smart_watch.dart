library flutter_smart_watch;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch/models/error.dart';

import 'models/paired_device_info.dart';

export './flutter_smart_watch.dart';

part 'flutter_smart_watch_method_channel.dart';
part 'flutter_smart_watch_platform_interface.dart';
part "enums/activate_state.dart";

typedef Message = Map<String, dynamic>;

typedef ActiveStateChangeCallback = Function(ActivateState activateState);

typedef PairDeviceInfoChangeCallback = Function(
    PairedDeviceInfo pairedDeviceInfo);

typedef ErrorCallback = Function(CurrentError error);

typedef MessageReceivedCallback = Function(Message message);

class FlutterSmartWatch {
  Future configure() async {
    bool isSupported =
        await _FlutterSmartWatchPlatform.instance.isSmartWatchSupported() ??
            false;
    if (isSupported) {
      await _activate();
    }
  }

  Future _activate() async {
    return _FlutterSmartWatchPlatform.instance.activate();
  }

  Future sendMessage(Message message) {
    return _FlutterSmartWatchPlatform.instance.sendMessage(message);
  }

  void listenToActivateStateChanged(ActiveStateChangeCallback callback) {
    _FlutterSmartWatchPlatform.instance.listenToActivateStateChanged(callback);
  }

  void listenToPairedDeviceInfoChanged(PairDeviceInfoChangeCallback callback) {
    _FlutterSmartWatchPlatform.instance
        .listenToPairedDeviceInfoChanged(callback);
  }

  void onMessageReceived(MessageReceivedCallback callback) {
    _FlutterSmartWatchPlatform.instance.listenToMessageReceiveEvent(callback);
  }

  void listenToError(ErrorCallback callback) {
    _FlutterSmartWatchPlatform.instance.listenToErrorCallback(callback);
  }
}
