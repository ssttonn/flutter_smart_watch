import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/wear_os_observer.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

import 'models/connected_device_info.dart';
export 'models/connected_device_info.dart';

class FlutterSmartWatchAndroid extends FlutterSmartWatchPlatformInterface {
  static registerWith() {
    FlutterSmartWatchPlatformInterface.instance = FlutterSmartWatchAndroid();
  }

  late WearOSObserver _wearOSObserver;

  @override
  Future initialize() async {
    _wearOSObserver = WearOSObserver();
    _wearOSObserver.initAllStreamControllers();
  }

  @override
  Future<bool> isSupported() async {
    bool? isSupported = await channel.invokeMethod("isSupported");
    return isSupported ?? false;
  }

  Future configureWearableAPI() async {
    return channel.invokeMethod("configure");
  }

  Future<List<DeviceInfo>> getConnectedDevices() async {
    List rawNodes = await channel.invokeMethod("getConnectedDevices");
    return rawNodes.map((nodeJson) {
      return DeviceInfo.fromRawData(channel, (nodeJson as Map? ?? {}));
    }).toList();
  }

  Future<DeviceInfo> getLocalDevice() async {
    Map data = (await channel.invokeMethod("getLocalDeviceInfo")) as Map? ?? {};
    return DeviceInfo.fromRawData(
        channel, data.map((key, value) => MapEntry(key.toString(), value)));
  }

  Future<String?> findDeviceIdFromBluetoothAddress(String address) async {
    return channel.invokeMethod("findDeviceIdFromBluetoothAddress", address);
  }

  Future registerNewCapability(String name) {
    return channel.invokeMethod("registerNewCapability", name);
  }

  Future removeExistingCapability(String name) {
    return channel.invokeMethod("removeExistingCapability", name);
  }

  @override
  void dispose() {
    _wearOSObserver.clearAllStreamControllers();
  }
}
