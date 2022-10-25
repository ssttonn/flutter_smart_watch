import 'package:flutter/services.dart';

class DeviceInfo {
  final String id;
  final String name;
  final bool isNearby;

  late Future<String?> Function() getCompanionPackageName;

  DeviceInfo({required this.id, required this.name, required this.isNearby});

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
      id: json["id"] as String? ?? "",
      name: json["name"] as String? ?? "",
      isNearby: json["isNearby"] as bool? ?? false);

  factory DeviceInfo.fromRawData(MethodChannel channel, Map data) {
    DeviceInfo _deviceInfo = DeviceInfo.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)));
    _deviceInfo.getCompanionPackageName = () =>
        channel.invokeMethod("getCompanionPackageForDevice", _deviceInfo.id);
    return _deviceInfo;
  }
}
