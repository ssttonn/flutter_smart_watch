// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paired_device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PairedDeviceInfo _$PairedDeviceInfoFromJson(Map<String, dynamic> json) =>
    PairedDeviceInfo(
      json['isPaired'] as bool? ?? false,
      json['isWatchAppInstalled'] as bool? ?? false,
      json['isComplicationEnabled'] as bool? ?? false,
      urlToUri(json['watchDirectoryURL'] as String?),
    );
