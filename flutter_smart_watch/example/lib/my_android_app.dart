import 'dart:developer';

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

  @override
  void initState() {
    super.initState();
    _flutterSmartWatchPlugin.configureWearableAPI().then((_) async {
      List<DeviceInfo> _devices =
          await _flutterSmartWatchPlugin.getConnectedDevices();
      _devices.forEach((device) {
        device.getCompanionPackageName().then(print);
      });
      DeviceInfo _localDevice = await _flutterSmartWatchPlugin.getLocalDevice();
      inspect(_localDevice);
      String? deviceId = await _flutterSmartWatchPlugin
          .findDeviceIdFromBluetoothAddress("60:3A:AF:DF:F9:EE");
      _flutterSmartWatchPlugin.removeExistingCapability("test");
      print(deviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          physics:
              AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: SpacingColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [],
          ),
        ),
      ),
    );
  }
}
