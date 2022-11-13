import 'dart:io';

import '../helpers/enums.dart';

class WearEngineMessage {
  final Map<String, dynamic>? data;
  final File? file;
  final String description;
  final MessageType type;
  final bool isEnableEncrypt;

  WearEngineMessage(
      {this.data,
      this.file,
      this.description = "",
      this.type = MessageType.data,
      this.isEnableEncrypt = true});

  factory WearEngineMessage.fromJson(Map<String, dynamic> json) {
    return WearEngineMessage(
        data: json["messageData"] == null
            ? null
            : (json["messageData"] as Map? ?? {})
                .map((key, value) => MapEntry(key.toString(), value)),
        file: json["filePath"] == null ? null : File(json["filePath"]),
        description: json["description"] as String? ?? "",
        type: MessageType.values[json["type"] as int? ?? 0],
        isEnableEncrypt: json["isEnableEncrypt"] as bool? ?? false);
  }
}
