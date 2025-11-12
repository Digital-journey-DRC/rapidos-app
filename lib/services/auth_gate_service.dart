import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class AuthGateService {
  static const String _kToken = 'token';  // Utiliser la même clé que StorageService
  static const String _kUserData = 'user_data';
  static const String _kLastLogin = 'last_login';
  static const String _kExpiry = 'auth_expiry';
  static const String _kIsFirst = 'is_first';
  
  // Identifiants par défaut pour l'auto-login
  static const String _defaultUsername = '+243842613999';
  static const String _defaultPassword = '0826016607Makengo@';
  
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  /// Vérifie si une session valide existe
  Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kToken);
      final userDataStr = prefs.getString(_kUserData);
      final lastLoginStr = prefs.getString(_kLastLogin);
      final expiryStr = prefs.getString(_kExpiry);

      print('🔍 Vérification de session - Token: ${token != null ? "Présent" : "Absent"}');
      print('🔍 Vérification de session - UserData: ${userDataStr != null ? "Présent" : "Absent"}');
      print('🔍 Vérification de session - LastLogin: $lastLoginStr');

      // Vérifier si toutes les données nécessaires sont présentes
      if (token == null || userDataStr == null) {
        print('❌ Données de session manquantes');
        return false;
      }

      // 📌 Ancien contrôle d'expiration désactivé pour conserver la session indefinitely.
      // Nous conservons les logs pour le suivi et la compatibilité.
      if (expiryStr != null) {
        try {
          final expiry = DateTime.parse(expiryStr);
          print('ℹ️ Expiration enregistrée: $expiry');
        } catch (e) {
          print('❌ Erreur lors du parsing de l\'expiration: $e');
        }
      }

      if (lastLoginStr != null) {
        try {
          final lastLogin = DateTime.parse(lastLoginStr);
          final hoursSinceLastLogin = DateTime.now().difference(lastLogin).inHours;
          print('ℹ️ Heures depuis la dernière connexion: $hoursSinceLastLogin');
        } catch (e) {
          print('❌ Erreur lors du parsing de la date de connexion: $e');
        }
      }

      // Vérifier que les données utilisateur sont valides
      try {
        final userData = jsonDecode(userDataStr);
        if (userData['id'] == null) {
          print('❌ Données utilisateur invalides');
          await clearSession();
          return false;
        }
        print('✅ Session valide trouvée pour l\'utilisateur: ${userData['firstName']} ${userData['lastName']}');
        return true;
      } catch (e) {
        print('❌ Erreur lors du parsing des données utilisateur: $e');
        await clearSession();
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification de session: $e');
      return false;
    }
  }

  /// Tente l'auto-login avec les identifiants par défaut
  Future<bool> tryAutoLogin() async {
    try {
      print('🔄 Tentative d\'auto-login avec les identifiants par défaut...');
      print('🔑 Username: $_defaultUsername');
      print('🔑 Password: $_defaultPassword');
      
      final response = await _authService.login(
        uid: _defaultUsername,
        password: _defaultPassword,
      );

      print('📱 Réponse auto-login complète: $response');
      print('📱 Token présent: ${response['token'] != null}');
      print('📱 User présent: ${response['user'] != null}');

      // Utiliser exactement la même logique que AuthCubit
      if (response['token'] != null) {
        print('💾 Sauvegarde de la session...');
        
        // Sauvegarder le token et les données utilisateur (même logique que AuthCubit)
        await _saveSession(
          token: response['token']['token'],  // response['token']['token'] comme dans AuthCubit
          userData: response['user'],         // response['user'] comme dans AuthCubit
          expiry: response['token']['expiresAt'] ?? null,
        );
        
        print('✅ Auto-login réussi et session sauvegardée');
        print('✅ Token sauvegardé: ${response['token']['token']}');
        print('✅ User sauvegardé: ${response['user']}');
        return true;
      } else {
        print('❌ Auto-login échoué - token manquant dans la réponse');
        print('❌ Réponse complète: $response');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'auto-login: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Sauvegarde la session utilisateur (même logique que AuthCubit)
  Future<void> _saveSession({
    required String token,
    required Map<String, dynamic> userData,
    String? expiry,
  }) async {
    try {
      print('💾 AuthGateService: Sauvegarde de la session...');
      
      // Sauvegarder avec SharedPreferences directement (pour compatibilité)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, token);
      await prefs.setString(_kUserData, jsonEncode(userData));
      await prefs.setString(_kLastLogin, DateTime.now().toIso8601String());
      
      if (expiry != null) {
        await prefs.setString(_kExpiry, expiry);
      }
      
      // AUSSI sauvegarder avec StorageService (pour que les cubits puissent récupérer)
      await _storageService.saveToken(token);
      await _storageService.saveUserData(jsonEncode(userData));
      
      // Marquer que ce n'est plus la première fois après un login réussi
      await markAsNotFirstTime();
      
      print('✅ Session sauvegardée avec succès');
      print('✅ Sauvegardé dans SharedPreferences ET StorageService');
      print('✅ Token: $token');
      print('✅ UserData: ${userData['firstName']} ${userData['lastName']}');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de session: $e');
    }
  }

  /// Vérifie si c'est la première fois que l'utilisateur lance l'app
  Future<bool> isFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirst = prefs.getBool(_kIsFirst) ?? true;
      print('🔍 AuthGateService: Première fois? $isFirst');
      return isFirst;
    } catch (e) {
      print('❌ Erreur lors de la vérification isFirst: $e');
      return true; // Par défaut, considérer comme première fois
    }
  }

  /// Marque que l'utilisateur n'est plus à sa première utilisation
  Future<void> markAsNotFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsFirst, false);
      print('✅ AuthGateService: Marqué comme non-première fois');
    } catch (e) {
      print('❌ Erreur lors du marquage isFirst: $e');
    }
  }

  /// Remet isFirst à true (pour les tests ou reset)
  Future<void> resetToFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsFirst, true);
      print('🔄 AuthGateService: Remis comme première fois');
    } catch (e) {
      print('❌ Erreur lors du reset isFirst: $e');
    }
  }

  /// Efface la session utilisateur
  Future<void> clearSession() async {
    try {
      print('🗑️ AuthGateService: Effacement de la session...');
      
      // Effacer avec SharedPreferences directement
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
      await prefs.remove(_kUserData);
      await prefs.remove(_kLastLogin);
      await prefs.remove(_kExpiry);
      
      // AUSSI effacer avec StorageService
      await _storageService.clearAll();
      
      print('✅ Session effacée avec succès');
      print('✅ Effacé dans SharedPreferences ET StorageService');
    } catch (e) {
      print('❌ Erreur lors de l\'effacement de session: $e');
    }
  }

  /// Efface tout (session + isFirst) - pour les tests
  Future<void> clearAll() async {
    try {
      print('🗑️ AuthGateService: Effacement complet...');
      await clearSession();
      await resetToFirstTime();
      print('✅ Tout effacé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'effacement complet: $e');
    }
  }

  /// Récupère le token actuel
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kToken);
    } catch (e) {
      print('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Récupère les données utilisateur
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(_kUserData);
      if (userDataStr != null) {
        return jsonDecode(userDataStr);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

  /// Récupère le rôle de l'utilisateur actuel
  Future<String?> getUserRole() async {
    try {
      final userData = await getUserData();
      if (userData != null && userData['role'] != null) {
        return userData['role'].toString();
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération du rôle utilisateur: $e');
      return null;
    }
  }
}

