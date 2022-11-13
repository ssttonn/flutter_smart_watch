part of helpers;

extension EnumExtension<T> on List<T> {
  T findElementOrGetFirstItemIfNull(int index) {
    return this[index > this.length - 1 ? 0 : index];
  }
}

extension MapExtension on Map {
  Map<String, dynamic> toMapStringDynamic() {
    return this.map((key, value) => MapEntry(key.toString(), value));
  }
}
