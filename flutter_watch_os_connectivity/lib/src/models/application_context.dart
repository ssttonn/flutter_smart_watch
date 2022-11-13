part of models;

class ApplicationContext {
  final Map<String, dynamic> _currentContext;
  final Map<String, dynamic> _receivedContext;

  ApplicationContext(this._currentContext, this._receivedContext);

  Map<String, dynamic> get current => _currentContext;
  Map<String, dynamic> get received => _receivedContext;

  factory ApplicationContext.fromJson(Map<String, dynamic> json) =>
      ApplicationContext(
        fromRawMapToMapStringKeys(json['current'] as Map),
        fromRawMapToMapStringKeys(json['received'] as Map),
      );
}
