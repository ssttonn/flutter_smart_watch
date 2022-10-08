import 'package:flutter_smart_watch/helpers/utils.dart';
// import 'package:json_annotation/json_annotation.dart';

part 'application_context.g.dart';

// @JsonSerializable(createToJson: false)
class ApplicationContext {
  // @JsonKey(name: "sent", fromJson: fromRawMapToMapStringKeys)
  final Map<String, dynamic> currentContext;
  // @JsonKey(name: "received", fromJson: fromRawMapToMapStringKeys)
  final Map<String, dynamic> receivedContext;

  ApplicationContext(this.currentContext, this.receivedContext);

  Map<String, dynamic> get current => currentContext;
  Map<String, dynamic> get received => receivedContext;

  factory ApplicationContext.fromJson(Map<String, dynamic> json) =>
      _$ApplicationContextFromJson(json);
}
