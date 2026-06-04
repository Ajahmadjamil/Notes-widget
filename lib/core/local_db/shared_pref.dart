import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static String loginKey = "login_data";

  // Future<void> setLoginData(LoginData loginData) async {
  //   SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  //   final String jsonString = jsonEncode(loginData.toJson());
  //   await sharedPreferences.setString(loginKey, jsonString);
  // }
  //
  // Future<LoginData?> getLoginData() async {
  //   SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  //   final jsonString = sharedPreferences.getString(loginKey);
  //   if (jsonString == null || jsonString.isEmpty) return null;
  //   final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
  //   return LoginData.fromJson(jsonMap);
  // }

  Future<void> setBearerToken(String user) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString('bearerToken', user);
  }

  Future<String> getBearerToken() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('bearerToken') ?? '';
  }

  Future<void> remove(String value) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.remove(value);
  }

  Future<void> clearAll() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.clear();
  }
}
