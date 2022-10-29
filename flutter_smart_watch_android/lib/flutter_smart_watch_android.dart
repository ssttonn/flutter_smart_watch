import 'dart:typed_data';

import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/helpers/enums.dart';
import 'package:flutter_smart_watch_android/models/capability_info.dart';
import 'package:flutter_smart_watch_android/models/data_item.dart';
import 'package:flutter_smart_watch_android/models/message.dart';
import 'package:flutter_smart_watch_android/wear_os_observer.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

import 'models/connected_device_info.dart';
import 'models/data_event.dart';

export 'models/connected_device_info.dart';
export 'helpers/enums.dart';
export 'models/message.dart';
export "models/data_item.dart";
export "models/data_event.dart";

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
      {CapabilityFilterType filterType = CapabilityFilterType.all}) async {
    Map data =
        (await channel.invokeMethod("getAllCapabilities", filterType.index));
    return data.map((key, value) => MapEntry(
        key.toString(),
        CapabilityInfo.fromJson((value as Map? ?? {})
            .map((key, value) => MapEntry(key.toString(), value)))));
  }

  Future<CapabilityInfo?> findCapabilityByName(String name,
      {CapabilityFilterType filterType = CapabilityFilterType.all}) async {
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

  Future<int> sendMessage(Uint8List data,
      {required String deviceId,
      required String path,
      MessagePriority priority = MessagePriority.low}) {
    return (channel.invokeMethod<int>("sendMessage", {
      "data": data,
      "nodeId": deviceId,
      "path": path,
      "priority": priority.index
    })).then((messageId) => messageId ?? -1);
  }

  Future<DataItem?> syncData(
      {required String path,
      required Map<String, dynamic> rawMapData,
      bool isUrgent = false}) async {
    final result = await channel.invokeMethod("syncData",
        {"path": path, "isUrgent": isUrgent, "rawMapData": rawMapData}) as Map?;
    if (result != null) {
      return DataItem.fromJson(
          result.map((key, value) => MapEntry(key.toString(), value)));
    }
    return null;
  }

  Future<int> deleteDataItems(
      {required Uri uri,
      DataUriFilterType filterType = DataUriFilterType.literal}) {
    return channel.invokeMethod("deleteDataItems", {
      "path": uri.toString(),
      "filterType": filterType.index
    }).then((deleteCount) => deleteCount ?? 0);
  }

  Future<List<DataItem>> findDataItems(
      {required Uri uri,
      DataUriFilterType filterType = DataUriFilterType.literal}) async {
    List? results = await channel.invokeMethod("getDataItems",
        {"path": uri.toString(), "filterType": filterType.index});
    return (results ?? [])
        .map((result) => DataItem.fromJson((result as Map? ?? {})
            .map((key, value) => MapEntry(key.toString(), value))))
        .toList();
  }

  Future<DataItem?> findDataItemFromUri({required Uri uri}) async {
    Map? result = await channel.invokeMethod("findDataItem", uri.toString());
    return DataItem.fromJson(
        (result ?? {}).map((key, value) => MapEntry(key.toString(), value)));
  }

  Future<List<DataItem>> getAllDataItems() async {
    List? results = await channel.invokeMethod("getAllDataItems");
    return (results ?? [])
        .map((result) => DataItem.fromJson((result as Map? ?? {})
            .map((key, value) => MapEntry(key.toString(), value))))
        .toList();
  }

  Stream<Message> get messageReceived =>
      _wearOSObserver.messageStreamController.stream;
  Stream<List<DataEvent>> get dataEventsChanged =>
      _wearOSObserver.dataEventsStreamController.stream;

  @override
  void dispose() {
    _wearOSObserver.clearAllStreamControllers();
  }
}
