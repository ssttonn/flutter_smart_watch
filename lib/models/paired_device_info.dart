// import 'package:json_annotation/json_annotation.dart';

part 'paired_device_info.g.dart';

// @JsonSerializable(createToJson: false)
class PairedDeviceInfo {
  final bool isPaired;
  final bool iOSDeviceNeedsUnlockAfterRebootForReachability;
  final bool isWatchAppInstalled;
  final bool isCompanionAppInstalled;
  final bool isComplicationEnabled;
  final Uri watchDirectoryURL;

  PairedDeviceInfo(
      this.isPaired,
      this.iOSDeviceNeedsUnlockAfterRebootForReachability,
      this.isWatchAppInstalled,
      this.isCompanionAppInstalled,
      this.isComplicationEnabled,
      this.watchDirectoryURL);

  factory PairedDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$PairedDeviceInfoFromJson(json);
}
