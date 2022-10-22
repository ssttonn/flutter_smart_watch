import 'package:flutter_smart_watch_ios/watch_os_observer.dart';

class Message {
  final Map<String, dynamic> data;
  final MessageReplyHandler? onReply;
  Message({required this.data, this.onReply});
}
