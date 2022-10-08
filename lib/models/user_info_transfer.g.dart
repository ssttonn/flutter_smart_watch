// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfoTransfer _$UserInfoTransferFromJson(Map<String, dynamic> json) =>
    UserInfoTransfer(
      id: json['id'] as String? ?? '',
      isCurrentComplicationInfo:
          json['isCurrentComplicationInfo'] as bool? ?? false,
      userInfo: fromRawMapToMapStringKeys(json['userInfo'] as Map),
      isTransfering: json['isTransfering'] as bool? ?? false,
    );
