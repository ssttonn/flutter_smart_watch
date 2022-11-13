part of helpers;

Uri? urlToUri(String? url) {
  return Uri.tryParse(url ?? "");
}
