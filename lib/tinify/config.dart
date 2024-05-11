import 'package:shared_preferences/shared_preferences.dart';

class Configuration {
  static const String tinifyApiKey = 'TINIFY_API_KEY';
  static const String tinifyApiUrl = 'TINIFY_API_URL';

  static const String _baseUrl = 'https://api.tinify.com';
  static const String _apiKey = String.fromEnvironment('API_KEY');

  static Future<String> getBaseUrl() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(tinifyApiUrl) ?? _baseUrl;
  }

  static Future<void> setBaseUrl(String value) async {
    final sp = await SharedPreferences.getInstance();
    sp.setString(tinifyApiUrl, value);
  }

  static Future<String> getApiKey() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(tinifyApiKey) ?? _apiKey;
  }

  static Future<void> setApiKey(String value) async {
    final sp = await SharedPreferences.getInstance();
    sp.setString(tinifyApiKey, value);
  }
}
