# Flutter Smart Watch
[![Version](https://img.shields.io/pub/v/flutter_smart_watch?color=%23212121&label=Version&style=for-the-badge)](https://pub.dev/packages/flutter_smart_watch)
[![Publisher](https://img.shields.io/pub/publisher/flutter_smart_watch?color=E94560&style=for-the-badge)](https://pub.dev/publishers/sstonn.xyz)
[![Points](https://img.shields.io/pub/points/flutter_smart_watch?color=FF9F29&style=for-the-badge)](https://pub.dev/packages/flutter_smart_watch)
[![LINCENSE](https://img.shields.io/github/license/ssttonn/flutter_smart_watch?color=0F3460&style=for-the-badge)](https://github.com/ssttonn/flutter_smart_watch/blob/master/flutter_smart_watch/LICENSE)

Plugin provides communication layer between the Flutter app and the WearOS, WatchOS applications.

## Features
Use this plugin in your Flutter app to:
- Communicate with smart watch application, 
- Transfer raw data.
- Transfer files.
- Check for wearable device info.
- Detect wearable reachability.

## Getting started
For WatchOS companion app, this plugin uses [Watch Connectivity](https://developer.apple.com/documentation/watchconnectivity) framework under the hood to communicate with IOS app.

For WearOS companion app, this plugin uses [Data Layer API](https://developer.android.com/training/wearables/data/data-layer) under the hood to communicate with Android app.

## Configuration

### Android

1. Create an WearOS companion app, you can follow this [instruction](https://developer.android.com/training/wearables/get-started/creating#creating) to create new WearOS app.

> Note: The WearOS companion app package name must be same as your Android app package name in order to communicate with each other.

That's all, you're ready to communicate with WearOS app now.

### IOS

1. Create an WatchOS companion app, you can follow this [instruction](https://developer.apple.com/tutorials/swiftui/creating-a-watchos-app) to create new WatchOS app.

> Note: If you've created a WatchOS app with UIKit, the WatchOS companion app must have Bundle ID with the following format in order to communicate with IOS app: YOUR_IOS_BUNDLE_ID.watchkitapp.

That's all, you're ready to communicate with WatchOS app now.

## How to use
## How to use <a name="how_to_use"/>
### Get started <a name="get_started"/>
#### Import the library <a name="get_started_1"/>

```dart
import 'package:flutter_watch_os_connectivity/flutter_watch_os_connectivity.dart';
```
### Android
#### Create new instance of `FlutterWearOsConnectivity` <a name="get_started_2"/>

```dart
final FlutterWearOsConnectivity _flutterWearOsConnectivity = FlutterSmartWatch().wearOS;
```

And then, please follow [this documentation](https://pub.dev/packages/flutter_wear_os_connectivity#how_to_use) to integrate futher with Android app.
### IOS
#### Create new instance of `FlutterWatchOsConnectivity` <a name="get_started_2"/>

```dart
final FlutterWatchOsConnectivity _flutterWatchOsConnectivity = FlutterSmartWatch().watchOS;
```

Please follow [this documentation](https://pub.dev/packages/flutter_watch_os_connectivity#how_to_use) to integrate futher with IOS app.
