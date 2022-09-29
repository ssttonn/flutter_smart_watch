
import 'flutter_smart_watch_platform_interface.dart';

class FlutterSmartWatch {
  Future<String?> getPlatformVersion() {
    return FlutterSmartWatchPlatform.instance.getPlatformVersion();
  }
}
