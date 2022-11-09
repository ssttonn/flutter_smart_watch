class MonitorData {
  final int? intData;
  final Map<String, dynamic>? mapData;
  final bool? boolData;
  final String? stringData;
  MonitorData(
      {required this.intData,
      required this.mapData,
      required this.boolData,
      required this.stringData});

  factory MonitorData.fromJson(Map<String, dynamic> json) {
    return MonitorData(
        intData: json["intData"] as int?,
        mapData: json["mapData"] == null
            ? (json["mapData"] as Map)
                .map((key, value) => MapEntry(key.toString(), value))
            : null,
        boolData: json["boolData"] as bool?,
        stringData: json["stringData"] as String?);
  }
}
