import 'package:flutter_smart_watch/helpers/utils.dart';
// import 'package:json_annotation/json_annotation.dart';

part 'user_info_transfer.g.dart';

// @JsonSerializable(createToJson: false)
class UserInfoTransfer {
  // @JsonKey(defaultValue: "")
  final String id;
  // @JsonKey(defaultValue: false)
  final bool isCurrentComplicationInfo;
  // @JsonKey(fromJson: fromRawMapToMapStringKeys)
  final Map<String, dynamic> userInfo;
  // @JsonKey(defaultValue: false)
  final bool isTransfering;

  UserInfoTransfer(
      {required this.id,
      required this.isCurrentComplicationInfo,
      required this.userInfo,
      required this.isTransfering});

  factory UserInfoTransfer.fromJson(Map<String, dynamic> json) =>
      _$UserInfoTransferFromJson(json);
}
