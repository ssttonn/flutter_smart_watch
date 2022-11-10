// import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_smart_watch_platform_interface/helpers/utils.dart';

part 'application_context.g.dart';

// @JsonSerializable(createToJson: false)
class ApplicationContext {
  // @JsonKey(name: "current", fromJson: fromRawMapToMapStringKeys)
  final Map<String, dynamic> _currentContext;
  // @JsonKey(name: "received", fromJson: fromRawMapToMapStringKeys)
  final Map<String, dynamic> _receivedContext;

  ApplicationContext(this._currentContext, this._receivedContext);

  Map<String, dynamic> get current => _currentContext;
  Map<String, dynamic> get received => _receivedContext;

  factory ApplicationContext.fromJson(Map<String, dynamic> json) =>
      _$ApplicationContextFromJson(json);
}
