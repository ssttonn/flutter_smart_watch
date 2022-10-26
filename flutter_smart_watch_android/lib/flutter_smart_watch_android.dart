import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/helpers/enums.dart';
import 'package:flutter_smart_watch_android/models/capability_info.dart';
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

  Future<Map<String, CapabilityInfo>> getAllCapabilities(
      {FilterType filterType = FilterType.ALL}) async {
    Map data =
        (await channel.invokeMethod("getAllCapabilities", filterType.index));
    return data.map((key, value) => MapEntry(
        key.toString(),
        CapabilityInfo.fromJson((value as Map? ?? {})
            .map((key, value) => MapEntry(key.toString(), value)))));
  }

  Future<CapabilityInfo?> findCapabilityByName(String name,
      {FilterType filterType = FilterType.ALL}) async {
    Map? data = (await channel.invokeMethod("findCapabilityByName",
        {"name": name, "filterType": filterType.index}));
    if (data == null) {
      return null;
    }
    return CapabilityInfo.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)));
  }

  Future registerNewCapability(String name) {
    return channel.invokeMethod("registerNewCapability", name);
  }

  Future removeExistingCapability(String name) {
    return channel.invokeMethod("removeExistingCapability", name);
  }

  Future addCapabilityListener(
      String name, CapabilityChangedListener listener) {
    return channel.invokeMethod("addCapabilityListener", name).whenComplete(() {
      _wearOSObserver.capabilityListeners[name] = listener;
    });
  }

  bool isCapabilityHasListener(String name) {
    return _wearOSObserver.capabilityListeners.containsKey(name);
  }

  Future<bool> removeCapabilityListener(String name) async {
    final result = await channel.invokeMethod("removeCapabilityListener", name);
    if (result) {
      _wearOSObserver.capabilityListeners.remove(name);
    }
    return result ?? false;
  }

  @override
  void dispose() {
    _wearOSObserver.clearAllStreamControllers();
  }
}
