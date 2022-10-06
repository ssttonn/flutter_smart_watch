// import 'package:json_annotation/json_annotation.dart';

part 'application_context.g.dart';

Map<String, dynamic> fromRawMap(Map rawMap) {
  return rawMap.map((key, value) => MapEntry(key.toString(), value));
}

// @JsonSerializable(createToJson: false)
class ApplicationContext {
  // @JsonKey(name: "sent", fromJson: fromRawMap)
  final Map<String, dynamic> _sentContext;
  // @JsonKey(name: "received", fromJson: fromRawMap)
  final Map<String, dynamic> _receivedContext;

  ApplicationContext(this._sentContext, this._receivedContext);

  Map<String, dynamic> get current => _sentContext;
  Map<String, dynamic> get received => _receivedContext;

  factory ApplicationContext.fromJson(Map<String, dynamic> json) =>
      _$ApplicationContextFromJson(json);
}
