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
  @override
  void initState() {
    super.initState();
    FlutterSmartWatch.ios.initialize();
    FlutterSmartWatch.ios.activationStateStream.listen((state) {});
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
