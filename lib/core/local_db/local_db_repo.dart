import 'package:escola/core/models/user_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

// To add model to the local database :
// 1- create the model manullay with  toJson() &  toJson() functions
// 2- add the key to this class
// 3- create abstract functions to get and add the model
// 4- implement these functions to the hive or other implemented DB
// 5- Add functions uses toJson() to the model and get functions use fromJson()

abstract class LocalDatabaseRepo {
  Future<void> initDB();

  Future<void> clearDB();

  Future<dynamic>? read({required String key});

  Future<bool> has({required String key});

  Future<void> write({required String key, required dynamic value});

  Future<void> delete({required String key});

  Future<String> dbPath() async {
    // On web there is no filesystem; Hive uses IndexedDB and ignores the
    // path argument. Returning a sentinel keeps the call sites uniform.
    if (kIsWeb) return 'web';
    // Get the application's document directory
    var appDir = await getApplicationDocumentsDirectory();
    // Get the chosen sub-directory for database files

    return '${appDir.path}/jeel';
  }

  //save token
  Future<void> saveToken(String token);

  // get Token
  Future<String?> getToken();

  Future<void> saveUser(UserModel user);

  Future<void> removeUser();

  // Future<UserModel?> getUser();
}

abstract class LocalKeys {
  static const tokenKey = "token";
  static const kUserKey = "user";
  static const last_otp_request = "last_otp_request";
  static const last_otp_phone = "last_otp_phone";
  static const rememberMe = "rememberMe";
  static const seenFeaturedEvents = "seen_featured_events";
  static const last_email_otp_request = "last_email_otp_request";
  static const last_email_otp_email = "last_email_otp_email";
  static const last_login_mode = "last_login_mode";
  static const en = "en";
  static const ar = "ar";
}
