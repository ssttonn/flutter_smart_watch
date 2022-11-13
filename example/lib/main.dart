import 'package:flutter/material.dart';
import 'package:flutter_smart_watch/flutter_smart_watch.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final FlutterWatchOsConnectivity _flutterWatchOsConnectivity =
      FlutterSmartWatch().watchOS;

  final FlutterWearOsConnectivity _flutterWearOsConnectivity =
      FlutterSmartWatch().wearOS;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text(
                "WearOS: ${_flutterWearOsConnectivity.isSupported()}\nWatchOS: ${_flutterWatchOsConnectivity.isSupported()}"),
          )),
    );
  }
}
