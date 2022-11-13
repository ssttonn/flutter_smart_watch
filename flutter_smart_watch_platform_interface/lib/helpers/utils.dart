part of helpers;

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

Map<String, dynamic> fromRawMapToMapStringKeys(Map rawMap) {
  return rawMap.map((key, value) => MapEntry(key.toString(), value));
}

File? fileFromPath(String? path) {
  if (path == null) return null;
  return File.fromUri(Uri.parse(path));
}
