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
  FlutterSmartWatch _flutterSmartWatchPlugin = FlutterSmartWatch.getInstance();
  int count = 0;
  bool isReachable = false;

  @override
  void initState() {
    super.initState();
    _flutterSmartWatchPlugin.activationStateStream.listen((activationState) {
      if (activationState == ActivationState.activated) {
        _flutterSmartWatchPlugin.getLatestApplicationContext().then((context) {
          if (context.received.containsKey("count")) {
            setState(() {
              count = context.received["count"] as int? ?? 0;
            });
          } else if (context.sent.containsKey("count")) {
            setState(() {
              count = context.sent["count"] as int? ?? 0;
            });
          }
        });
      }
    });
    _flutterSmartWatchPlugin.pairedDeviceInfoStream.listen((pairedDeviceInfo) {
      print(pairedDeviceInfo);
    });
    _flutterSmartWatchPlugin.messageStream.listen((message) {
      if (message.containsKey("count")) {
        setState(() {
          count = message["count"] as int? ?? 0;
        });
      }
    });
    _flutterSmartWatchPlugin.reachabilityStream.listen((isReachable) {
      setState(() {
        this.isReachable = isReachable;
      });
    });
    _flutterSmartWatchPlugin.applicationContextStream
        .listen((applicationContext) {
      if (applicationContext.received.containsKey("count")) {
        setState(() {
          count = applicationContext.received["count"] as int? ?? 0;
        });
      }
    });
    _flutterSmartWatchPlugin.userInfoStream.listen((userInfo) {});
    _flutterSmartWatchPlugin.errorStream.listen((error) {
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
  void dispose() {
    super.dispose();
    _flutterSmartWatchPlugin.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: StreamBuilder<ActivationState>(
            stream: _flutterSmartWatchPlugin.activationStateStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data != ActivationState.activated) {
                return Container(
                  child: Text("Your session isn't activated"),
                );
              }
              return Center(
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
              );
            }),
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
