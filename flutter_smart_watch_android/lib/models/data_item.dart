import 'dart:typed_data';

class DataItem {
  final Uri uri;
  final Uint8List data;
  final Map<String, dynamic> mapData;
  DataItem({required this.uri, required this.data, required this.mapData});

  factory DataItem.fromJson(Map<String, dynamic> json) {
    return DataItem(
        uri: Uri.tryParse(json["uri"]) ?? Uri(),
        data: json["data"] ?? Uint8List(0),
        mapData: (json["map"] as Map? ?? {})
            .map((key, value) => MapEntry(key.toString(), value)));
  }
}
