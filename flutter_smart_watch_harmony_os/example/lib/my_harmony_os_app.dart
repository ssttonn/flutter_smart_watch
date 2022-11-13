import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_smart_watch_harmony_os/flutter_smart_watch_harmony_os.dart';

class MyHarmonyOsApp extends StatefulWidget {
  const MyHarmonyOsApp({Key? key}) : super(key: key);

  @override
  State<MyHarmonyOsApp> createState() => _MyHarmonyOsAppState();
}

class _MyHarmonyOsAppState extends State<MyHarmonyOsApp> {
  FlutterSmartWatchHarmonyOs _flutterSmartWatchPlugin =
      FlutterSmartWatchHarmonyOs();

  @override
  void initState() {
    super.initState();
    _flutterSmartWatchPlugin.configure().then((value) {
      _flutterSmartWatchPlugin..hasAvailableDevices().then(inspect);
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(),
      body: _body(theme),
    ));
  }

  Widget _body(ThemeData theme) {
    return Container();
  }
}
