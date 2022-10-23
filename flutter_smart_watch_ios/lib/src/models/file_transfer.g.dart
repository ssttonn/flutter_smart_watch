// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileTransfer _$FileTransferFromJson(Map<String, dynamic> json) => FileTransfer(
    id: json['id'] as String? ?? '',
    file: fileFromPath(json['filePath'] as String?),
    isTransfering: json['isTransfering'] as bool? ?? false,
    metadata: fromRawMapToMapStringKeys(json['metadata'] as Map? ?? {}));
