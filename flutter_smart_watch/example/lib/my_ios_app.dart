import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_watch/flutter_smart_watch.dart';
import 'package:flutter_smart_watch_example/widgets/spacing_column.dart';
import 'package:image_picker/image_picker.dart';

class MyIOSApp extends StatefulWidget {
  const MyIOSApp({Key? key}) : super(key: key);

  @override
  State<MyIOSApp> createState() => _MyIOSAppState();
}

class _MyIOSAppState extends State<MyIOSApp> {
  FlutterSmartWatchIos _flutterSmartWatchPlugin = FlutterSmartWatch().ios;
  bool _isReachable = false;
  PairedDeviceInfo _pairedDeviceInfo =
      PairedDeviceInfo(false, false, false, Uri());

  Map<String, dynamic> _currentMessage = new Map();
  Map<String, dynamic> _currentReplyMessage = new Map();

  ApplicationContext _applicationContext = ApplicationContext({}, {});

  Map<String, dynamic> _receivedUserInfo = new Map();
  List<UserInfoTransfer> _userInfoPendingTransfers = [];

  Map<String, dynamic> _receivedFileData = new Map();
  List<FileTransfer> _filePendingTransfers = [];

  ActivationState _activationState = ActivationState.notActivated;

  @override
  void initState() {
    super.initState();
    _flutterSmartWatchPlugin.configureAndActivateSession();
    _flutterSmartWatchPlugin.activationStateChanged.listen((activationState) {
      if (activationState == ActivationState.activated) {
        _flutterSmartWatchPlugin.getPairedDeviceInfo().then((info) {
          setState(() {
            _pairedDeviceInfo = info;
          });
        });
      }
      setState(() {
        _activationState = activationState;
      });
    });

    _flutterSmartWatchPlugin.pairedDeviceInfoChanged.listen((info) {
      setState(() {
        _pairedDeviceInfo = info;
      });
    });
    _flutterSmartWatchPlugin.reachabilityChanged.listen((isReachable) {
      setState(() {
        _isReachable = isReachable;
      });
    });

    _flutterSmartWatchPlugin.messageReceived.listen((message) async {
      setState(() {
        _currentMessage = message.data;
      });
      if (message.onReply != null) {
        try {
          await message.onReply!({
            "message":
                "Message received on IOS app at ${DateTime.now().millisecondsSinceEpoch}"
          });
        } catch (e) {
          print(e);
        }
      }
    });

    _flutterSmartWatchPlugin.applicationContextUpdated.listen((context) {
      setState(() {
        _applicationContext = context;
      });
    });

    _flutterSmartWatchPlugin.userInfoReceived.listen((userInfo) {
      setState(() {
        _receivedUserInfo = userInfo;
      });
    });

    _flutterSmartWatchPlugin.getOnProgressUserInfoTransfers().then((transfers) {
      setState(() {
        _userInfoPendingTransfers = transfers;
      });
    });
    _flutterSmartWatchPlugin.pendingUserInfoTransferListChanged
        .listen((transfers) {
      setState(() {
        _userInfoPendingTransfers = transfers;
      });
    });
    _flutterSmartWatchPlugin.userInfoTransferDidFinish.listen((transfer) {
      inspect(transfer);
    });

    _flutterSmartWatchPlugin.fileReceived.listen((file) {
      setState(() {
        _receivedFileData = file;
      });
    });
    _flutterSmartWatchPlugin.getOnProgressFileTransfers().then((transfers) {
      setState(() {
        _filePendingTransfers = transfers;
        _filePendingTransfers.forEach((transfer) {
          transfer.setOnProgressListener((progress) {
            print("${transfer.id}: ${progress.currentProgress}");
          });
        });
      });
    });
    _flutterSmartWatchPlugin.pendingFileTransferListChanged.listen((transfers) {
      setState(() {
        _filePendingTransfers = transfers;
        _filePendingTransfers.forEach((transfer) {
          transfer.setOnProgressListener((progress) {
            print("${transfer.id}: ${progress.currentProgress}");
          });
        });
      });
    });
    _flutterSmartWatchPlugin.fileTransferDidFinish.listen((transfer) {
      inspect(transfer);
    });
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
        body: SingleChildScrollView(
          physics:
              AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: SpacingColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pairedDeviceInfoSection(theme),
              _sendMessageSection(theme),
              _updateApplicationContextSession(theme),
              _sendUserInfoSession(theme),
              _transferFileSession(theme),
            ],
          ),
        ),
      ),
    );
  }

  _pairedDeviceInfoSection(ThemeData theme) {
    return _section(theme,
        child: SpacingColumn(
          spacing: 5,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("ActivationState: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text("${_activationState}"),
            Text("isReachable: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text("${_isReachable}",
                style: theme.textTheme.subtitle2?.copyWith(
                    color:
                        _isReachable ? Colors.greenAccent : Colors.redAccent)),
            Text("isPaired: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text("${_pairedDeviceInfo.isPaired}"),
            Text("isWatchAppInstalled: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text("${_pairedDeviceInfo.isWatchAppInstalled}"),
            Text("isComplicationEnabled: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text("${_pairedDeviceInfo.isComplicationEnabled}"),
            Text("watchDirectoryURL: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text("${_pairedDeviceInfo.watchDirectoryURL?.path}")
          ],
        ));
  }

  _sendMessageSection(ThemeData theme) {
    return _section(theme,
        child: SpacingColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Text("Message received: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text(_currentMessage.toString()),
            Text("Reply received: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text(_currentReplyMessage.toString()),
            _button(theme, title: "Send Message", onPressed: () {
              if (_isReachable) {
                _flutterSmartWatchPlugin.sendMessage(
                    {"message": "This is a message send from IOS app"});
              }
            }),
            _button(theme, title: "Send Message With Reply Handler",
                onPressed: () {
              if (_isReachable) {
                _flutterSmartWatchPlugin.sendMessage({
                  "message":
                      "This is a message send from IOS app with reply handler"
                }, replyHandler: ((message) async {
                  setState(() {
                    _currentReplyMessage = message;
                  });
                }));
              }
            }),
          ],
        ));
  }

  _updateApplicationContextSession(ThemeData theme) {
    return _section(theme,
        child: SpacingColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Text("Current application context:  ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text(_applicationContext.current.toString()),
            Text("Received application context:  ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text(_applicationContext.received.toString()),
            _button(theme, title: "Update Application Context", onPressed: () {
              _flutterSmartWatchPlugin.updateApplicationContext({
                "message":
                    "Application Context updated by IOS app at ${DateTime.now().millisecondsSinceEpoch}"
              });
            }),
          ],
        ));
  }

  _sendUserInfoSession(ThemeData theme) {
    return _section(theme,
        child: SpacingColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Text("Received user info: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            Text(_receivedUserInfo.toString()),
            Text("Pending user info transfers: ",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
            ..._userInfoPendingTransfers.map((transfer) => Row(
                  children: [
                    Expanded(
                      child: Text(
                          "${transfer.id}: " + transfer.userInfo.toString(),
                          style: theme.textTheme.headline6
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(100)),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: (() async {
                          try {
                            await transfer.cancel();
                          } catch (e) {
                            print(e);
                          }
                        }))
                  ],
                )),
            _button(theme, title: "Send user info", onPressed: () async {
              _flutterSmartWatchPlugin.transferUserInfo({
                "message":
                    "User info sended by IOS app at ${DateTime.now().millisecondsSinceEpoch}"
              });
            }),
          ],
        ));
  }

  _transferFileSession(ThemeData theme) {
    return _section(theme,
        child: SpacingColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Text("Received file: ",
                  style: theme.textTheme.headline6?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
              if (_receivedFileData["file"] != null)
                Image.file(_receivedFileData["file"]),
              Text("Metadata: ",
                  style: theme.textTheme.headline6?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
              Text("${_receivedFileData["metadata"] ?? ""}"),
              Text("Pending file transfers: ",
                  style: theme.textTheme.headline6?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
              ..._filePendingTransfers.map((transfer) => Row(
                    children: [
                      Expanded(
                        child: Text(
                            "${transfer.id}: " + transfer.file.toString(),
                            style: theme.textTheme.headline6
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(100)),
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: (() async {
                            try {
                              await transfer.cancel();
                            } catch (e) {
                              print(e);
                            }
                          }))
                    ],
                  )),
              _button(theme, title: "Transfer file", onPressed: () async {
                XFile? _file =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (_file != null) {
                  FileTransfer? _fileTransfer = await _flutterSmartWatchPlugin
                      .transferFileInfo(File(_file.path));
                  if (_fileTransfer?.setOnProgressListener != null)
                    _fileTransfer?.setOnProgressListener(((progress) {
                      print("${_fileTransfer.id}: ${progress.currentProgress}");
                    }));
                }
              }),
            ]));
  }

  _section(ThemeData theme, {required Widget child}) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  _button(ThemeData theme,
      {required String title, required VoidCallback onPressed}) {
    return CupertinoButton(
        padding: EdgeInsets.all(0),
        child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(14),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.subtitle2?.copyWith(color: Colors.white),
            )),
        onPressed: onPressed);
  }
}