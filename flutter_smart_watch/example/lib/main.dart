import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_smart_watch/flutter_smart_watch.dart';
import 'package:flutter_smart_watch_example/widgets/spacing_column.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSmartWatch().initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterSmartWatchIos _flutterSmartWatchPlugin = FlutterSmartWatch().ios;
  bool _isReachable = false;
  PairedDeviceInfo _pairedDeviceInfo =
      PairedDeviceInfo(false, false, false, Uri());

  Map<String, dynamic> _currentMessage = new Map();
  Map<String, dynamic> _currentReplyMessage = new Map();

  ApplicationContext _applicationContext = ApplicationContext({}, {});

  Map<String, dynamic> _receivedUserInfo = new Map();
  List<UserInfoTransfer> _userInfoPendingTransfers = [];

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
              _sendUserInfoSession(theme)
            ],
          ),
        ),
      ),
    );
  }

  _pairedDeviceInfoSection(ThemeData theme) {
    return _section(theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("ActivationState: ${_activationState}",
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text("isReachable: ${_isReachable}",
                style: theme.textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isReachable ? Colors.greenAccent : Colors.red)),
            Text("isPaired: ${_pairedDeviceInfo.isPaired}",
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(
                "isWatchAppInstalled: ${_pairedDeviceInfo.isWatchAppInstalled}",
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(
                "isComplicationEnabled: ${_pairedDeviceInfo.isComplicationEnabled}",
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(
                "watchDirectoryURL: ${_pairedDeviceInfo.watchDirectoryURL?.path}",
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600))
          ],
        ));
  }

  _sendMessageSection(ThemeData theme) {
    return _section(theme,
        child: SpacingColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Text("Message received: \n" + _currentMessage.toString(),
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text("Reply received: \n" + _currentReplyMessage.toString(),
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
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
            Text(
                "Current application context: \n" +
                    _applicationContext.current.toString(),
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(
                "Received application context: \n" +
                    _applicationContext.received.toString(),
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
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
            Text("Received user info: \n" + _receivedUserInfo.toString(),
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text("Pending user info transfers: \n",
                style: theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w600)),
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
                          await transfer.cancel();
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
