import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool isReachable = false;

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
    _flutterSmartWatchPlugin.onMessageReceived((message) {
      if (message.containsKey("count")) {
        setState(() {
          count = message["count"] as int? ?? 0;
        });
      }
    });
    _flutterSmartWatchPlugin.onReachabilityChanged((isReachable) {
      setState(() {
        this.isReachable = isReachable;
      });
    });
    _flutterSmartWatchPlugin.onApplicationContextReceived((context) {
      if (context.containsKey("count")) {
        setState(() {
          count = context["count"] as int? ?? 0;
        });
      }
    });
    _flutterSmartWatchPlugin.listenToError((error) {
      print(error.message);
    });
    _flutterSmartWatchPlugin.configure().then((value) {
      _flutterSmartWatchPlugin.getCurrentApplicationContext().then((context) {
        if (context.containsKey("count")) {
          setState(() {
            count = context["count"] as int? ?? 0;
          });
        }
      });
    });
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconButton(Icons.remove, () async {
                    setState(() {
                      count--;
                    });
                    _sendMessage();
                  }),
                  SizedBox(width: 10),
                  Text(count.toString(),
                      style: theme.textTheme.headline5
                          ?.copyWith(color: theme.colorScheme.primary)),
                  SizedBox(width: 10),
                  _iconButton(Icons.add, () async {
                    setState(() {
                      count++;
                    });
                    _sendMessage();
                  })
                ],
              ),
              SizedBox(height: 10),
              Text("isReachable: ${this.isReachable}"),
            ],
          ),
        ),
      ),
    );
  }

  _sendMessage() async {
    try {
      if (isReachable) {
        //* send data when the watch is in foreground
        await _flutterSmartWatchPlugin.sendMessage({"count": count},
            replyHandler: (replyMessage) {
          print(replyMessage);
        });
      } else {
        //* send data when the watch is in background
        _flutterSmartWatchPlugin.updateApplicationContext({"count": count});
      }
    } on PlatformException catch (e) {
      print(e.message);
    }
  }
}
