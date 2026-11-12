import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyActiveSchoolId = 'active_school_id';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyUserData = 'user_data';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  StorageService({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  })  : _secureStorage = secureStorage,
        _prefs = prefs;

  // Secure Token
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: _keyToken);
  }

  // Active School Context
  Future<void> saveActiveSchoolId(String schoolId) async {
    await _prefs.setString(_keyActiveSchoolId, schoolId);
  }

  String? getActiveSchoolId() {
    return _prefs.getString(_keyActiveSchoolId);
  }

  // Cached User JSON
  Future<void> saveUserData(String jsonString) async {
    await _prefs.setString(_keyUserData, jsonString);
  }

  String? getUserData() {
    return _prefs.getString(_keyUserData);
  }

  // Onboarding Status
  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboardingCompleted, value);
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  // Clear all session data on logout
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.remove(_keyActiveSchoolId);
    await _prefs.remove(_keyUserData);
  }
}
