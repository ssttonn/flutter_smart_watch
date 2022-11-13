import 'package:flutter_smart_watch_harmony_os/helpers/enums.dart';

extension IntExtension on int {
  CompanionAppStatus convertToCompanionAppStatus() {
    switch (this) {
      case 200:
        return CompanionAppStatus.notInstalled;
      case 201:
        return CompanionAppStatus.notStarted;
      case 202:
        return CompanionAppStatus.started;
      default:
        return CompanionAppStatus.notInstalled;
    }
  }
}
