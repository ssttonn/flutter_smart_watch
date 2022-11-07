import 'package:flutter/material.dart';

class MyHarmonyOsApp extends StatefulWidget {
  const MyHarmonyOsApp({Key? key}) : super(key: key);

  @override
  State<MyHarmonyOsApp> createState() => _MyHarmonyOsAppState();
}

class _MyHarmonyOsAppState extends State<MyHarmonyOsApp> {
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(),
      body: _body(theme),
    ));
  }

  Widget _body(ThemeData theme) {
    return Container();
  }
}
