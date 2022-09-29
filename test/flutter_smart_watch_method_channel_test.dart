import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_watch/flutter_smart_watch_method_channel.dart';

void main() {
  MethodChannelFlutterSmartWatch platform = MethodChannelFlutterSmartWatch();
  const MethodChannel channel = MethodChannel('flutter_smart_watch');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
