import 'package:flutter_smart_watch_harmony_os/helpers/enums.dart';

class WearEngineNotification {
  final NotificationTemplate template;
  final String? companionAppPackageName;
  final String title;
  final String content;
  final Map<int, String> buttonContents;

  WearEngineNotification(
      {required this.template,
      required this.title,
      required this.content,
      required this.buttonContents,
      this.companionAppPackageName});

  factory WearEngineNotification.fromJson(Map<String, dynamic> json) {
    return WearEngineNotification(
        template: NotificationTemplate
            .values[(json["templateId"] as int? ?? 50) - 50],
        title: json["title"] as String? ?? "",
        content: json["content"] as String? ?? "",
        buttonContents: (json["buttonContents"] as Map? ?? {}).map(
            (key, value) =>
                MapEntry(int.tryParse(key.toString()) ?? -1, value.toString())),
        companionAppPackageName: json["packageName"] as String? ?? "");
  }

  factory WearEngineNotification.fromNotifcationOptions(
      WearEngineNotificationSendOptions options) {
    return WearEngineNotification(
        template: NotificationTemplate.values[options.buttonContents.length],
        title: options.title,
        content: options.content,
        buttonContents: NotificationTemplate.values.asMap().map(
            (key, value) => MapEntry(key + 50, options.buttonContents[key])),
        companionAppPackageName: options.packageName);
  }
}

class WearEngineNotificationSendOptions {
  final List<String> buttonContents;
  final String? packageName;
  final String title;
  final String content;
  WearEngineNotificationSendOptions(
      {this.buttonContents = const [],
      this.packageName,
      required this.title,
      required this.content})
      : assert(buttonContents.length <= 3);

  Map<String, dynamic> toJson() {
    return {
      "buttonContents": buttonContents,
      "wearablePackageName": packageName,
      "title": title,
      "content": content
    };
  }
}
