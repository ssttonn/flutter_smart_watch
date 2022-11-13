part of models;

class WatchOSMessage {
  final Map<String, dynamic> data;
  final MessageReplyHandler? onReply;
  WatchOSMessage({required this.data, this.onReply});
}
