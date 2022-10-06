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
  Map<String, dynamic> _applicationContext = new Map();
  List<String> _dataTransferTypes = [
    "Message",
    "Application Context",
    "User Info"
  ];
  ActivationState _activationState = ActivationState.notActivated;

  String _selectedTransferType = "";

  bool isAbleToSendData(String type) {
    return (_activationState != ActivationState.activated ||
        (type == "Message" && !isReachable));
  }

  @override
  void initState() {
    super.initState();
    _selectedTransferType = _dataTransferTypes[0];
    _flutterSmartWatchPlugin.activationStateStream.listen((activationState) {
      setState(() {
        _activationState = activationState;
      });
      if (activationState == ActivationState.activated) {
        _flutterSmartWatchPlugin.getLatestApplicationContext().then((context) {
          _applicationContext = context.current;
          _updateCount();
        });
      }
    });
    _flutterSmartWatchPlugin.pairedDeviceInfoStream.listen((pairedDeviceInfo) {
      print(pairedDeviceInfo);
    });
    // _flutterSmartWatchPlugin.messageStream.listen((message) {
    //   if (message.containsKey("count")) {
    //     setState(() {
    //       count = message["count"] as int? ?? 0;
    //     });
    //   }
    // });
    _flutterSmartWatchPlugin.reachabilityStream.listen((isReachable) {
      setState(() {
        this.isReachable = isReachable;
      });
    });
    _flutterSmartWatchPlugin.applicationContextStream
        .listen((applicationContext) {
      _applicationContext = applicationContext.received;
      _updateCount();
    });
    _flutterSmartWatchPlugin.userInfoStream.listen((userInfo) {});
    _flutterSmartWatchPlugin.errorStream.listen((error) {
      print(error.message);
    });
    _flutterSmartWatchPlugin.configure();
  }

  _updateCount() {
    if (_applicationContext.containsKey("count")) {
      setState(() {
        count = _applicationContext["count"] as int? ?? 0;
      });
    }
  }

  Widget _iconButton(IconData iconData, VoidCallback? onPressed) {
    final theme = Theme.of(context);
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: onPressed != null ? theme.colorScheme.primary : Colors.grey,
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._dataTransferTypes.map((type) {
                return RadioListTile<String>(
                    value: type,
                    groupValue: _selectedTransferType,
                    selected: type == _selectedTransferType,
                    title: Text(type),
                    onChanged: isAbleToSendData(type)
                        ? null
                        : ((value) {
                            setState(() {
                              _selectedTransferType = value ?? "";
                            });
                          }));
              }),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconButton(
                      Icons.remove,
                      isAbleToSendData(_selectedTransferType)
                          ? null
                          : () async {
                              setState(() {
                                count--;
                              });
                              _sendData();
                            }),
                  SizedBox(width: 10),
                  Text(count.toString(),
                      style: theme.textTheme.headline5
                          ?.copyWith(color: theme.colorScheme.primary)),
                  SizedBox(width: 10),
                  _iconButton(
                      Icons.add,
                      isAbleToSendData(_selectedTransferType)
                          ? null
                          : () async {
                              setState(() {
                                count++;
                              });
                              _sendData();
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

  _sendData() async {
    try {
      switch (_selectedTransferType) {
        case "Message":
          _flutterSmartWatchPlugin.sendMessage({"count": count});
          break;
        case "Application Context":
          _applicationContext["count"] = count;
          _flutterSmartWatchPlugin
              .updateApplicationContext(_applicationContext);
          break;
        case "User Info":
          break;
      }
    } on PlatformException catch (e) {
      print(e.message);
    }
  }
}
