import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_watch/flutter_smart_watch.dart';
import 'package:flutter_smart_watch/flutter_smart_watch_platform_interface.dart';
import 'package:flutter_smart_watch/flutter_smart_watch_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSmartWatchPlatform 
    with MockPlatformInterfaceMixin
    implements FlutterSmartWatchPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterSmartWatchPlatform initialPlatform = FlutterSmartWatchPlatform.instance;

  test('$MethodChannelFlutterSmartWatch is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterSmartWatch>());
  });

  test('getPlatformVersion', () async {
    FlutterSmartWatch flutterSmartWatchPlugin = FlutterSmartWatch();
    MockFlutterSmartWatchPlatform fakePlatform = MockFlutterSmartWatchPlatform();
    FlutterSmartWatchPlatform.instance = fakePlatform;
  
    expect(await flutterSmartWatchPlugin.getPlatformVersion(), '42');
  });
}
