import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String lastLoginKey = 'last_login';

  // Sauvegarder le token
  Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    // Save token and update last login time
    await prefs.setString(lastLoginKey, DateTime.now().toIso8601String());
    return prefs.setString(tokenKey, token);
  }

  // Récupérer le token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Supprimer le token
  Future<bool> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(tokenKey);
  }

  // Récupérer le timestamp de dernière connexion
  Future<DateTime?> getLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginStr = prefs.getString(lastLoginKey);
    if (lastLoginStr != null) {
      return DateTime.parse(lastLoginStr);
    }
    return null;
  }

  // Sauvegarder les données utilisateur
  Future<bool> saveUserData(String userData) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userKey, userData);
  }

  // Récupérer les données utilisateur
  Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userKey);
  }

  // Supprimer les données utilisateur
  Future<bool> removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(userKey);
  }

  // Effacer toutes les données
  Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}
