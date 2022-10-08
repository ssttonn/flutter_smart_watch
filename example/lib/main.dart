import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_smart_watch/flutter_smart_watch.dart';
import 'package:flutter_smart_watch/models/user_info_transfer.dart';
import 'package:image_picker/image_picker.dart';

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
  List<UserInfoTransfer> _transfers = [];
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
    _flutterSmartWatchPlugin.isSupported().then((supported) {
      if (supported) {
        _flutterSmartWatchPlugin.activate();
        _flutterSmartWatchPlugin
            .getOnProgressUserInfoTransfers()
            .then((value) => inspect(value));
      }
    });
    _flutterSmartWatchPlugin.messageStream.listen((message) {
      print(message);
    });
    _flutterSmartWatchPlugin.activationStateStream.listen((state) {
      setState(() {
        _activationState = state;
      });
    });
    _flutterSmartWatchPlugin.userInfoStream.listen((userInfo) {
      print("INFO");
      inspect(userInfo);
    });
    _flutterSmartWatchPlugin.userInfoTransferDidFinishStream.listen((transfer) {
      print("FINISHED");
      inspect(transfer);
    });
    _flutterSmartWatchPlugin.onProgressUserInfoTransferListStream
        .listen((transfers) {
      print("TRANSFER");
      inspect(transfers);
      _transfers = transfers;
    });
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
          final ImagePicker _picker = ImagePicker();
          // Pick an image
          final XFile? image =
              await _picker.pickImage(source: ImageSource.gallery);
          _flutterSmartWatchPlugin.transferFileInfo(File(image?.path ?? ""),
              metadata: {"abc": "ds"});
          break;
      }
    } on PlatformException catch (e) {
      print(e.message);
    }
  }
}
