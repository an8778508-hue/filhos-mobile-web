import 'dart:io';

import 'package:escola/core/models/user_model.dart';
import 'package:hive/hive.dart';
import 'package:escola/core/local_db/local_db_repo.dart';

class LocalDatabaseImpl extends LocalDatabaseRepo {
  @override
  Future<void> initDB() async {
    Hive.init(await dbPath());
  }

  @override
  Future<void> clearDB() async {
    await Hive.close();
    var hiveDb = Directory(await dbPath());
    await hiveDb.delete(recursive: true);
  }

  @override
  Future<dynamic>? read({required String key}) async {
    final box = await Hive.openBox(key);
    final value = box.get(key);

    return value;
  }

  @override
  Future<void> write({required String key, required value}) async {
    final box = await Hive.openBox(key);
    box.put(key, value);
  }

  @override
  Future<void> delete({required String key}) async {
    final box = await Hive.openBox(key);
    box.delete(key);
  }

  @override
  Future<void> saveToken(String token) async {
    await write(key: LocalKeys.tokenKey, value: token);
  }

  @override
  Future<bool> has({required String key}) async {
    final box = await Hive.openBox(key);
    final value = box.containsKey(key);

    return value;
  }

  @override
  Future<String?> getToken() async {
    return await read(key: LocalKeys.tokenKey);
  }

  // @override
  // Future<UserModel?> getUser() async {
  //   final user = await read(key: LocalKeys.kUserKey);
  //   if (user != null) {
  //     return UserModel.fromJson(Map<String,dynamic>.from(user));
  //   }
  //   return null;
  // }

  @override
  Future<void> saveUser(UserModel user) {
    return write(key: LocalKeys.kUserKey, value: user.toJson());
  }

  @override
  Future<void> removeUser() async {
    return await delete(key: LocalKeys.kUserKey, );
  }
}
