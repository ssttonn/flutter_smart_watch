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
}
