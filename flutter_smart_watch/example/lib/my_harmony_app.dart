import 'package:flutter/material.dart';
import 'package:flutter_smart_watch/flutter_smart_watch.dart';

class MyHarmonyApp extends StatefulWidget {
  const MyHarmonyApp({Key? key}) : super(key: key);

  @override
  State<MyHarmonyApp> createState() => _MyHarmonyAppState();
}

class _MyHarmonyAppState extends State<MyHarmonyApp> {
  FlutterSmartWatchHarmonyOs _flutterSmartWatchPlugin =
      FlutterSmartWatch().harmonyOs;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
      ),
    );
  }
}
