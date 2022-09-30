import 'package:flutter/cupertino.dart';
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
  int count = 0;

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

  Widget _iconButton(IconData iconData, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: theme.colorScheme.primary,
        ),
        child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(iconData, color: Colors.white),
            onPressed: onPressed));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconButton(Icons.remove, () {
                setState(() {
                  count--;
                });
                _flutterSmartWatchPlugin.sendMessage({"count": count});
              }),
              SizedBox(width: 10),
              Text(count.toString(),
                  style: theme.textTheme.headline5
                      ?.copyWith(color: theme.colorScheme.primary)),
              SizedBox(width: 10),
              _iconButton(Icons.add, () {
                setState(() {
                  count++;
                });
                _flutterSmartWatchPlugin.sendMessage({"count": count});
              })
            ],
          ),
        ),
      ),
    );
  }
}
