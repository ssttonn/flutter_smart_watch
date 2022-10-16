// import 'package:json_annotation/json_annotation.dart';

part 'paired_device_info.g.dart';

Uri? urlToUri(String? url) {
  return Uri.tryParse(url ?? "");
}

// @JsonSerializable(createToJson: false)
class PairedDeviceInfo {
  // @JsonKey(defaultValue: false)
  final bool isPaired;
  // @JsonKey(defaultValue: false)
  final bool isWatchAppInstalled;
  // @JsonKey(defaultValue: false)
  final bool isComplicationEnabled;
  // @JsonKey(defaultValue: null, fromJson: urlToUri)
  final Uri? watchDirectoryURL;

  PairedDeviceInfo(this.isPaired, this.isWatchAppInstalled,
      this.isComplicationEnabled, this.watchDirectoryURL);

  factory PairedDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$PairedDeviceInfoFromJson(json);
}
