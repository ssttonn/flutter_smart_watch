import 'dart:async';

import 'package:flutter_smart_watch_harmony_os/helpers/enums.dart';

class HarmonyOsObserver {
  StreamController<ConnectionState>? connectionStateChangedStreamController;
  StreamController<List<WearEnginePermission>>?
      permissionsChangedStreamController;
  StreamController<Map<String, dynamic>>? monitorDataChangedStreamController;
}
