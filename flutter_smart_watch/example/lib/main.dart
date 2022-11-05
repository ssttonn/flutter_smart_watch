import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_smart_watch/flutter_smart_watch.dart';
import 'package:flutter_smart_watch_example/my_android_app.dart';

import 'my_ios_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Platform.isIOS ? const MyIOSApp() : const MyAndroidApp());
}
