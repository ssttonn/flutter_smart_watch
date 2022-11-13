part of models;

class UserInfoTransfer {
  final String id;
  final bool isCurrentComplicationInfo;
  final Map<String, dynamic> userInfo;
  final bool isTransfering;
  Future<void> Function() cancel = () async {};

  UserInfoTransfer(
      {required this.id,
      required this.isCurrentComplicationInfo,
      required this.userInfo,
      required this.isTransfering});

  factory UserInfoTransfer.fromJson(Map<String, dynamic> json) =>
      UserInfoTransfer(
        id: json['id'] as String? ?? '',
        isCurrentComplicationInfo:
            json['isCurrentComplicationInfo'] as bool? ?? false,
        userInfo: fromRawMapToMapStringKeys(json['userInfo'] as Map),
        isTransfering: json['isTransfering'] as bool? ?? false,
      );
}
