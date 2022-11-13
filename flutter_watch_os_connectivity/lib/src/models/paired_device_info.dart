part of models;

class PairedDeviceInfo {
  final bool isPaired;
  final bool isWatchAppInstalled;
  final bool isComplicationEnabled;
  final Uri? watchDirectoryURL;

  PairedDeviceInfo(this.isPaired, this.isWatchAppInstalled,
      this.isComplicationEnabled, this.watchDirectoryURL);

  factory PairedDeviceInfo.fromJson(Map<String, dynamic> json) =>
      PairedDeviceInfo(
        json['isPaired'] as bool? ?? false,
        json['isWatchAppInstalled'] as bool? ?? false,
        json['isComplicationEnabled'] as bool? ?? false,
        urlToUri(json['watchDirectoryURL'] as String?),
      );
}
