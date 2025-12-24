/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Catio Atlas';
  static const String appVersion = '1.0.0';

  // File extensions
  static const List<String> supportedImageExtensions = ['png'];
  static const String atlasExtension = 'png';
  static const String metadataExtension = 'json';

  // Default atlas settings
  static const int defaultMaxAtlasWidth = 2048;
  static const int defaultMaxAtlasHeight = 2048;
  static const int defaultPadding = 2;
}
