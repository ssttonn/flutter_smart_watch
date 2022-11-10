import 'dart:async';

import 'package:flutter_smart_watch_harmony_os/helpers/enums.dart';
import 'package:flutter_smart_watch_harmony_os/models/wear_engine_message.dart';

typedef ReplyReceived = void Function(CompanionAppStatus appStatus);
typedef MessageResultReceived = void Function(int resultCode);
typedef MessageSendProgressChanged = void Function(int currentProgress);

class HarmonyOsObserver {
  StreamController<ConnectionState>? connectionStateChangedStreamController;
  StreamController<List<WearEnginePermission>>?
      permissionsChangedStreamController;
  StreamController<Map<String, dynamic>>? monitorDataChangedStreamController;
  StreamController<WearEngineMessage>? messageReceivedStreamController;
  Map<String, ReplyReceived> replyReceivedCallbacks = Map();
  Map<String, MessageResultReceived> messageResultReceivedCallbacks = Map();
  Map<String, MessageSendProgressChanged> messageSendProgressChangedCallbacks =
      Map();
}
