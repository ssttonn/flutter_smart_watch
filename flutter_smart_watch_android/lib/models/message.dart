import 'dart:typed_data';

class Message {
  final Uint8List data;
  final String path;
  final int requestId;
  final String sourceNodeId;

  Message(
      {required this.data,
      required this.path,
      required this.requestId,
      required this.sourceNodeId});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
      data: json["data"] ?? Uint8List(0),
      path: json["path"] as String? ?? "",
      requestId: json["requestId"] as int? ?? 0,
      sourceNodeId: json["sourceNodeId"] as String? ?? "");
}
