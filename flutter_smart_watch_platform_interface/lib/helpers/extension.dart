extension EnumExtension<T> on List<T> {
  T findElementOrGetFirstItemIfNull(int index) {
    return this[index > this.length - 1 ? 0 : index];
  }
}
