import 'package:flutter/material.dart';

import 'package:flutter_smart_watch/flutter_smart_watch.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterSmartWatchPlugin = FlutterSmartWatch();

  @override
  void initState() {
    super.initState();
    _flutterSmartWatchPlugin.listenToActivateStateChanged((activateState) {
      print(activateState);
    });
    _flutterSmartWatchPlugin
        .listenToPairedDeviceInfoChanged((pairedDeviceInfo) {
      print(pairedDeviceInfo);
    });
    _flutterSmartWatchPlugin.listenToError((error) {
      print(error.message);
    });
    _flutterSmartWatchPlugin.configure();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on'),
        ),
      ),
    );
  }
}
