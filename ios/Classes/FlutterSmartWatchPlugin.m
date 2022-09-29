#import "FlutterSmartWatchPlugin.h"
#if __has_include(<flutter_smart_watch/flutter_smart_watch-Swift.h>)
#import <flutter_smart_watch/flutter_smart_watch-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_smart_watch-Swift.h"
#endif

@implementation FlutterSmartWatchPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterSmartWatchPlugin registerWithRegistrar:registrar];
}
@end
