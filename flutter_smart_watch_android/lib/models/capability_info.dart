import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/flutter_smart_watch_android.dart';

class CapabilityInfo {
  final String name;
  final Set<DeviceInfo> associatedDevices;
  CapabilityInfo({required this.name, required this.associatedDevices});

  factory CapabilityInfo.fromJson(Map<String, dynamic> json) {
    return CapabilityInfo(
        name: json["name"] as String? ?? "",
        associatedDevices: (json["associatedNodes"] as List? ?? [])
            .map((nodeJson) => DeviceInfo.fromRawData(
                channel,
                (nodeJson as Map? ?? {})
                    .map((key, value) => MapEntry(key.toString(), value))))
            .toSet());
  }
}
