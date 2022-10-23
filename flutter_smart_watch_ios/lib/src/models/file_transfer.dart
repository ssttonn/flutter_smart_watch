import 'dart:io';
import 'package:flutter/material.dart';
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

  // @JsonKey(fromJson: fromRawMapToMapStringKeys)
  final Map<String, dynamic>? metadata;

  // @JsonKey(ignore:  true)
  Future<void> Function() cancel = () async {};

  void Function(void Function(Progress)) setOnProgressListener = ((p0) {});

  FileTransfer(
      {required this.id,
      required this.file,
      this.isTransfering = false,
      this.metadata});
  factory FileTransfer.fromJson(Map<String, dynamic> json) =>
      _$FileTransferFromJson(json);
}

class Progress {
  final int currentProgress;
  final int estimateTimeLeft;

  Progress({required this.currentProgress, required this.estimateTimeLeft});

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
        currentProgress: json['currentProgress'] as int? ?? 0,
        estimateTimeLeft: json["estimateTimeRemaining"] as int? ?? 0);
  }
}
