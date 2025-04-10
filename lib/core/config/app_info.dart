import 'package:escola/core/utils/valid_data.dart';

class AppInfo {
  const AppInfo(this.json);

  final Map<String, dynamic> json;

  String get appName => validateString(json['app_name']);
  String get privacyUrl => validateString(json['privacy_url']);
  String get iosUrl => validateString(json['ios_url']);
  String get androidUrl => validateString(json['android_url']);
  String get appStoreId => validateString(json['app_store_id']);
}
