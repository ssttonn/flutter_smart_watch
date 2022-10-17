import 'dart:io';
import 'package:flutter_smart_watch_ios/src/helpers/utils.dart';
// import 'package:json_annotation/json_annotation.dart';

part 'file_transfer.g.dart';

// @JsonSerializable(createToJson: false)
class FileTransfer {
  // @JsonKey(defaultValue: "")
  final String id;

  // @JsonKey(name: "filePath", fromJson: fileFromPath)
  final File? file;

  // @JsonKey(defaultValue: false)
  final bool isTransfering;

  FileTransfer(
      {required this.id, required this.file, this.isTransfering = false});
  factory FileTransfer.fromJson(Map<String, dynamic> json) =>
      _$FileTransferFromJson(json);
}
