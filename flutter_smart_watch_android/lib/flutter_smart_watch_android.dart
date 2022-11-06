import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_smart_watch_android/channel.dart';
import 'package:flutter_smart_watch_android/helpers/enums.dart';
import 'package:flutter_smart_watch_android/models/capability_info.dart';
import 'package:flutter_smart_watch_android/models/data_event.dart';
import 'package:flutter_smart_watch_android/models/data_item.dart';
import 'package:flutter_smart_watch_android/models/message.dart';
import 'package:flutter_smart_watch_android/wear_os_observer.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

import 'models/connected_device_info.dart';

export 'models/connected_device_info.dart';
export 'helpers/enums.dart';
export 'models/message.dart';
export "models/data_item.dart";
export "models/data_event.dart";
export "models/capability_info.dart";

class FlutterSmartWatchAndroid extends FlutterSmartWatchPlatformInterface {
  static registerWith() {
    FlutterSmartWatchPlatformInterface.instance = FlutterSmartWatchAndroid();
  }

  late WearOSObserver _wearOSObserver;

  @override
  Future<bool> isSupported() async {
    bool? isSupported = await channel.invokeMethod("isSupported");
    return isSupported ?? false;
  }

  Future configureWearableAPI() async {
    _wearOSObserver = WearOSObserver();
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

  Stream<CapabilityInfo> capabilityChanged(
      {String? capabilityName,
      Uri? capabilityPath,
      UriFilterType filterType = UriFilterType.literal}) async* {
    if (capabilityName == null && capabilityPath == null) {
      throw "Name or uri must be specified";
    }
    await removeCapabilityListener(
        capabilityName: capabilityName, capabilityUri: capabilityPath);
    await channel.invokeMethod(
        "addCapabilityListener",
        capabilityName != null
            ? {
                "name": capabilityName,
              }
            : {
                "path": capabilityPath.toString(),
                "filterType": filterType.index
              });

    String key = capabilityName ?? capabilityPath.toString();
    Map<String, StreamController<CapabilityInfo>>
        _capabilityInfoStreamControllers =
        _wearOSObserver.streamControllers[ObservableType.capability]
            as Map<String, StreamController<CapabilityInfo>>;
    _capabilityInfoStreamControllers[key] = StreamController.broadcast();
    yield* _capabilityInfoStreamControllers[key]!.stream;
  }

  bool isCapabilityHasListener({String? name, Uri? uri}) {
    return _wearOSObserver.streamControllers[ObservableType.capability]!
        .containsKey(name ?? uri.toString());
  }

  Future<bool> removeCapabilityListener(
      {String? capabilityName, Uri? capabilityUri}) async {
    if (capabilityName == null && capabilityUri == null) {
      throw "Name or uri must be specified";
    }
    String key = capabilityName ?? capabilityUri.toString();
    if (_wearOSObserver.streamControllers[ObservableType.capability]!
        .containsKey(key)) {
      _wearOSObserver.streamControllers[ObservableType.capability]![key]
          ?.close();
      _wearOSObserver.streamControllers[ObservableType.capability]?.remove(key);
    }
    final result = await channel.invokeMethod(
        "removeCapabilityListener",
        capabilityName != null
            ? {"name": capabilityName}
            : {"path": capabilityUri.toString()});
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

  Stream<Message> messageReceived(
      {Uri? path, UriFilterType filterType = UriFilterType.literal}) async* {
    await removeMessageListener(path: path);
    await channel.invokeMethod(
        "addMessageListener",
        path == null
            ? {"name": "global_message_channel"}
            : {"path": path.toString(), "filterType": filterType.index});

    String key = path == null ? "global_message_channel" : path.toString();
    Map<String, StreamController<Message>> _messageStreamControllers =
        _wearOSObserver.streamControllers[ObservableType.message]
            as Map<String, StreamController<Message>>;
    _messageStreamControllers[key] = StreamController.broadcast();
    yield* _messageStreamControllers[key]!.stream;
  }

  Future removeMessageListener({Uri? path}) {
    String key = path == null ? "global_message_channel" : path.toString();
    if (_wearOSObserver.streamControllers[ObservableType.message]!
        .containsKey(key)) {
      _wearOSObserver.streamControllers[ObservableType.message]![key]?.close();
      _wearOSObserver.streamControllers[ObservableType.message]!.remove(key);
    }
    return channel.invokeMethod(
        "removeMessageListener",
        path == null
            ? {"name": "global_message_channel"}
            : {"path": path.toString()});
  }

  Future<DataItem?> syncData(
      {required String path,
      required Map<String, dynamic> data,
      Map<String, File> files = const {},
      bool isUrgent = false}) async {
    final result = await channel.invokeMethod("syncData", {
      "path": path,
      "isUrgent": isUrgent,
      "rawMapData": data.map((key, value) => MapEntry(key.toString(), value)),
      "rawFilePaths":
          files.map((key, value) => MapEntry(key.toString(), (value.path)))
    }) as Map?;
    if (result != null) {
      return DataItem.fromJson(
          result.map((key, value) => MapEntry(key.toString(), value)));
    }
    return null;
  }

  Future<int> deleteDataItems(
      {required Uri uri, UriFilterType filterType = UriFilterType.literal}) {
    return channel.invokeMethod("deleteDataItems", {
      "path": uri.toString(),
      "filterType": filterType.index
    }).then((deleteCount) => deleteCount ?? 0);
  }

  Future<List<DataItem>> findDataItems(
      {required Uri uri,
      UriFilterType filterType = UriFilterType.literal}) async {
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

  Stream<List<DataEvent>> dataChanged(
      {Uri? path, UriFilterType filterType = UriFilterType.literal}) async* {
    await removeDataListener(path: path);
    await channel.invokeMethod(
        "addDataListener",
        path == null
            ? {"name": "global_data_channel"}
            : {"path": path.toString(), "filterType": filterType.index});
    String key = path == null ? "global_data_channel" : path.toString();

    Map<String, StreamController<List<DataEvent>>> _dataStreamControllers =
        _wearOSObserver.streamControllers[ObservableType.data]
            as Map<String, StreamController<List<DataEvent>>>;
    _dataStreamControllers[key] = StreamController.broadcast();
    yield* _dataStreamControllers[key]!.stream;
  }

  Future removeDataListener({Uri? path}) {
    String key = path == null ? "global_data_channel" : path.toString();

    if (_wearOSObserver.streamControllers[ObservableType.data]!
        .containsKey(key)) {
      _wearOSObserver.streamControllers[ObservableType.data]![key]!.close();
      _wearOSObserver.streamControllers[ObservableType.data]!.remove(key);
    }
    return channel.invokeMethod(
        "removeDataListener",
        path != null
            ? {"name": "global_data_channel"}
            : {"path": path.toString()});
  }

  @override
  void dispose() {
    _wearOSObserver.streamControllers.values.forEach((childControllers) {});
  }
}
