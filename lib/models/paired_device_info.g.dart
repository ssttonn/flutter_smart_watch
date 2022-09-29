// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paired_device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PairedDeviceInfo _$PairedDeviceInfoFromJson(Map<String, dynamic> json) =>
    PairedDeviceInfo(
      json['isPaired'] as bool,
      json['iOSDeviceNeedsUnlockAfterRebootForReachability'] as bool,
      json['isWatchAppInstalled'] as bool,
      json['isCompanionAppInstalled'] as bool,
      json['isComplicationEnabled'] as bool,
      Uri.parse(json['watchDirectoryURL'] as String),
    );
