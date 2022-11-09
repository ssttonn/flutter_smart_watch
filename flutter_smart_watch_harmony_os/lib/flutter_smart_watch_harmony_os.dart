import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_smart_watch_harmony_os/harmonyos_observer.dart';
import 'package:flutter_smart_watch_harmony_os/helpers/enums.dart';
import 'package:flutter_smart_watch_harmony_os/models/harmony_device.dart';
import 'package:flutter_smart_watch_harmony_os/models/monitor_data.dart';
import 'package:flutter_smart_watch_platform_interface/flutter_smart_watch_platform_interface.dart';

/// An implementation of [FlutterSmartWatchHarmonyOsPlatform] that uses method channels.
class FlutterSmartWatchHarmonyOs extends FlutterSmartWatchPlatformInterface {
  static registerWith() {
    FlutterSmartWatchPlatformInterface.instance = FlutterSmartWatchHarmonyOs();
  }

  late HarmonyOsObserver _harmonyOsObserver;

  final methodChannel =
      const MethodChannel('sstonn/flutter_smart_watch_harmony_os');

  Future<void> configure(
      {required String companionAppPackageName,
      required String companionAppFingerprint}) {
    _harmonyOsObserver = HarmonyOsObserver();
    return methodChannel.invokeMethod("configure", {
      "companionPackageName": companionAppPackageName,
      "companionAppFingerprint": companionAppFingerprint
    });
  }

  Future<bool> hasAvailableDevices() {
    return methodChannel
        .invokeMethod("hasAvailableDevices")
        .then((result) => result ?? false);
  }

  Stream<ConnectionState> connectionStateChanged() async* {
    await _removeConnectionListener();
    if (_harmonyOsObserver.connectionStateChangedStreamController == null) {
      _harmonyOsObserver.connectionStateChangedStreamController =
          StreamController.broadcast();
    }
    await methodChannel.invokeMethod("addServiceConnectionListener");
    yield* _harmonyOsObserver.connectionStateChangedStreamController!.stream;
  }

  Future<void> _removeConnectionListener() {
    if (_harmonyOsObserver.connectionStateChangedStreamController != null) {
      _harmonyOsObserver.connectionStateChangedStreamController?.close();
      _harmonyOsObserver.connectionStateChangedStreamController = null;
    }
    return methodChannel.invokeMethod("removeServiceConnectionListener");
  }

  Future<void> closeConnection() {
    return methodChannel.invokeMethod("releaseConnection");
  }

  Future<int?> getClientApiLevel() {
    return methodChannel.invokeMethod("getClientApiLevel");
  }

  Future<int?> getWearEngineApiLevel() {
    return methodChannel.invokeMethod("getServiceApiLevel");
  }

  Stream<List<WearEnginePermission>> permissionsChanged() async* {
    await _removePermissionChangedListener();
    if (_harmonyOsObserver.permissionsChangedStreamController == null) {
      _harmonyOsObserver.permissionsChangedStreamController =
          StreamController.broadcast();
    }
    await methodChannel.invokeMethod("addPermissionsListener");
    yield* _harmonyOsObserver.permissionsChangedStreamController!.stream;
  }

  Future<void> _removePermissionChangedListener() {
    if (_harmonyOsObserver.permissionsChangedStreamController != null) {
      _harmonyOsObserver.permissionsChangedStreamController?.close();
      _harmonyOsObserver.permissionsChangedStreamController = null;
    }
    return methodChannel.invokeMethod("removePermissionListener");
  }

  Future<bool> checkPermission(WearEnginePermission permission) {
    return methodChannel.invokeMethod("checkWearEnginePermission",
        {"permissionIndex": permission.index}).then((isGranted) {
      return isGranted ?? false;
    });
  }

  Future<Map<WearEnginePermission, bool>> checkPermissions(
      List<WearEnginePermission> permissions) {
    return methodChannel.invokeMethod("checkWearEnginePermissions", {
      "permissionIndexes":
          permissions.map((permission) => permission.index).toList()
    }).then((permissionResult) {
      return (permissionResult as Map? ?? {}).map(
          (key, value) => MapEntry(WearEnginePermission.values[key], value));
    });
  }

  Future<void> requestPermissions(List<WearEnginePermission> permissions) {
    return methodChannel.invokeMethod("requestPermissions", {
      "permissionIndexes":
          permissions.map((permission) => permission.index).toList()
    });
  }

  Future<List<WearEngineDevice>> getBoundedDevices() {
    return methodChannel.invokeMethod("getBoundedDevices").then((rawDevices) {
      return (rawDevices as List? ?? [])
          .map((rawDevice) => WearEngineDevice.fromJson(rawDevice))
          .toList();
    });
  }

  Future<List<WearEngineDevice>> getCommonDevices() {
    return methodChannel.invokeMethod("getCommonDevices").then((rawDevices) {
      return (rawDevices as List? ?? []).map((rawDevice) {
        WearEngineDevice _device = WearEngineDevice.fromJson(rawDevice);
        _device.checkForDeviceCapability = ({int queryId = 128}) =>
            _checkForDeviceCapability(
                deviceUUID: _device.uuid, queryId: queryId);
        _device.getAvailableStorageSize =
            () => _getAvailableStorageSize(deviceUUID: _device.uuid);
        _device.queryMonitorItem = ({required MonitorItem monitorItem}) =>
            _queryForMonitorData(item: monitorItem, deviceUUID: _device.uuid);
        _device.monitorItemsChanged = ({required List<MonitorItem> items}) =>
            _registerMonitorListener(deviceUUID: _device.uuid, items: items);
        return _device;
      }).toList();
    });
  }

  Future<DeviceCapabilityStatus> _checkForDeviceCapability(
      {required String deviceUUID, required int queryId}) {
    return methodChannel.invokeMethod("checkForDeviceCapability",
        {"deviceUUID": deviceUUID, "queryId": queryId}).then((statusIndex) {
      return DeviceCapabilityStatus.values[statusIndex ?? 2];
    });
  }

  Future<int> _getAvailableStorageSize({required String deviceUUID}) {
    return methodChannel.invokeMethod("getAvailableKBytes",
        {"deviceUUID": deviceUUID}).then((kBytes) => kBytes ?? 0);
  }

  Future<MonitorData> _queryForMonitorData(
      {required MonitorItem item, required String deviceUUID}) {
    return methodChannel.invokeMethod("queryForMonitorData", {
      "deviceUUID": deviceUUID,
      "monitorItemIndex": item.index
    }).then((rawData) {
      return MonitorData.fromJson(rawData);
    });
  }

  Stream<Map<String, dynamic>> _registerMonitorListener(
      {required String deviceUUID, required List<MonitorItem> items}) async* {
    await _removeMonitorListener(deviceUUID: deviceUUID);
    if (_harmonyOsObserver.monitorDataChangedStreamController == null) {
      _harmonyOsObserver.monitorDataChangedStreamController =
          StreamController.broadcast();
    }
    await methodChannel.invokeMethod("registerMonitorListener", {
      "deviceUUID": deviceUUID,
      "monitorItemIndexes": items.map((item) => item.index).toList()
    });
    yield* _harmonyOsObserver.monitorDataChangedStreamController!.stream;
  }

  Future<void> _removeMonitorListener({required String deviceUUID}) {
    if (_harmonyOsObserver.monitorDataChangedStreamController != null) {
      _harmonyOsObserver.monitorDataChangedStreamController?.close();
      _harmonyOsObserver.monitorDataChangedStreamController = null;
    }
    return methodChannel
        .invokeMethod("removeMonitorListener", {"deviceUUID": deviceUUID});
  }

  Future<bool> isCompanionAppInstalled({required String deviceUUID}) {
    return methodChannel.invokeMethod("isCompanionAppInstalled",
        {"deviceUUID": deviceUUID}).then((result) => result ?? false);
  }

  Future<int?> getCompanionAppVersion({required String deviceUUID}) {
    return methodChannel.invokeMethod("getCompanionAppVersion", {
      "deviceUUID": deviceUUID
    }).then((version) => version == -1 ? null : version);
  }
}
