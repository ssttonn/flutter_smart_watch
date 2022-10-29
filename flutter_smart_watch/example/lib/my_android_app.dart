import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_watch/flutter_smart_watch.dart';

import 'widgets/spacing_column.dart';

class MyAndroidApp extends StatefulWidget {
  const MyAndroidApp({Key? key}) : super(key: key);

  @override
  State<MyAndroidApp> createState() => _MyAndroidAppState();
}

class _MyAndroidAppState extends State<MyAndroidApp> {
  FlutterSmartWatchAndroid _flutterSmartWatchPlugin =
      FlutterSmartWatch().android;
  List<DeviceInfo> _deviceList = [];
  DeviceInfo? _selectedDevice;
  Message? _currentMessage;
  DataItem? _dataItem;

  @override
  void initState() {
    super.initState();
    _flutterSmartWatchPlugin.configureWearableAPI().then((_) {
      // _flutterSmartWatchPlugin.getConnectedDevices().then((devices) {
      //   setState(() {
      //     _deviceList = devices;
      //   });
      // });
      _flutterSmartWatchPlugin
          .findCapabilityByName("flutter_smart_watch_connected_nodes",
              filterType: CapabilityFilterType.all)
          .then((info) {
        _updateDeviceList((info?.associatedDevices ?? Set()).toList());
      });
      _flutterSmartWatchPlugin.addMessageListener((message) {
        inspect(message);
      }, name: "main");
      _flutterSmartWatchPlugin.addMessageListener((message) {
        inspect(message);
      },
          uri: Uri(
              scheme: "wear", host: "cf4092e", path: "/wearos-message-path"));
      _flutterSmartWatchPlugin.addDataListener((dataEvents) {
        inspect(dataEvents);
      }, name: "main");
      _flutterSmartWatchPlugin.addDataListener((dataEvents) {
        inspect(dataEvents);
      }, uri: Uri(scheme: "wear", host: "*", path: "/data-path-2"));
      _flutterSmartWatchPlugin.addDataListener((dataEvents) {
        inspect(dataEvents);
      }, uri: Uri(scheme: "wear", host: "cf4092e", path: "/wearos-data-path"));

      _flutterSmartWatchPlugin.addCapabilityListener((capabilityInfo) {
        _updateDeviceList((capabilityInfo.associatedDevices).toList());
      }, uri: Uri.parse("wear://*/flutter_smart_watch_connected_nodes"));
    });
  }

  void _updateDeviceList(List<DeviceInfo> devices) {
    setState(() {
      _deviceList = devices;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          physics:
              AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: SingleChildScrollView(
            child: SpacingColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _devicesWidget(theme),
                if (_selectedDevice != null) _deviceUtils(theme)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _devicesWidget(ThemeData theme) {
    return Column(
      children: _deviceList.map((info) {
        bool isSelected = info.id == _selectedDevice?.id;
        Color mainColor = !isSelected ? theme.primaryColor : Colors.white;
        Color secondaryColor = isSelected ? theme.primaryColor : Colors.white;
        return Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(info.name,
                    style: theme.textTheme.headline6
                        ?.copyWith(color: theme.primaryColor)),
                Text("Device ID: ${info.id}"),
                Text("Is nearby: ${info.isNearby}")
              ],
            )),
            CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(isSelected ? "Selected" : "Select",
                      style: theme.textTheme.subtitle1
                          ?.copyWith(color: secondaryColor)),
                ),
                onPressed: () {
                  setState(() {
                    if (_selectedDevice != null) {
                      _selectedDevice = null;
                      return;
                    }
                    _selectedDevice = info;
                  });
                })
          ]),
        );
      }).toList(),
    );
  }

  Widget _deviceUtils(ThemeData theme) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(10)),
      child: SpacingColumn(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Received message: ", style: theme.textTheme.headline6),
          ..._currentMessage != null
              ? [
                  Text("Raw Data: ${_currentMessage?.data.toString()}"),
                  Text(
                      "Decrypted Data: ${String.fromCharCodes(_currentMessage!.data).toString()}"),
                  Text("Message path: ${_currentMessage!.path}"),
                  Text("Request ID: ${_currentMessage!.requestId}"),
                  Text("Device id: ${_currentMessage!.sourceNodeId}")
                ]
              : [],
          CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "Send example message",
                  style:
                      theme.textTheme.subtitle1?.copyWith(color: Colors.white),
                ),
              ),
              onPressed: () {
                List<int> list =
                    'Sample message from Android app at ${DateTime.now().millisecondsSinceEpoch}'
                        .codeUnits;
                Uint8List bytes = Uint8List.fromList(list);
                _flutterSmartWatchPlugin
                    .sendMessage(bytes,
                        deviceId: _selectedDevice!.id, path: "/sample-message")
                    .then(print);
              }),
          Text("Received data: ", style: theme.textTheme.headline6),
          ..._dataItem != null
              ? [
                  Text("Raw Data: ${_dataItem!.data.toString()}"),
                  Text(
                      "Decrypted Data: ${String.fromCharCodes(_currentMessage!.data).toString()}"),
                  Text("Data path: ${_dataItem!.uri.path}"),
                ]
              : [],
          CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "Sync current data",
                  style:
                      theme.textTheme.subtitle1?.copyWith(color: Colors.white),
                ),
              ),
              onPressed: () {
                _flutterSmartWatchPlugin
                    .syncData(path: "/data-path-2", rawMapData: {
                  "message":
                      "Data sync by AndroidOS app at ${DateTime.now().millisecondsSinceEpoch}"
                }).then((value) {
                  _flutterSmartWatchPlugin
                      .findDataItemFromUri(uri: value!.uri)
                      .then(inspect);
                });
              }),
        ],
      ),
    );
  }
}
