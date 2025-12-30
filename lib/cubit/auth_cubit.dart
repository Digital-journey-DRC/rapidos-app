import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/screens/auth/otp_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/auth_gate_service.dart';

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final bool success;
  final String message;
  final String? token;
  final Map<String, dynamic>? user;

  AuthSuccess({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final StorageService _storageService = StorageService();

  AuthCubit(this._authService) : super(AuthInitial());

  Future<void> register({
    required String email,
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    required BuildContext context,
  }) async {
    try {
      emit(AuthLoading());
      final response = await _authService.register(
        email: email,
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      if (response['status'] == 200 || response['status'] == 201) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => OTPScreen(user: {
            'id': response['id'].toString(),
            'otp': response['otp'],
            'phone': phone,
            'password': password,
            'firstName': firstName,
            'lastName': lastName,
            'role': role,
            'resetPassword': false,
          }),
        ));
      }

      // Sauvegarder le token et les données utilisateur
      if (response['token'] != null) {
        await _storageService.saveToken(response['token']);
        await _storageService.saveUserData(jsonEncode(response['user']));
      }

      emit(AuthInitial());

      // emit(AuthSuccess(
      //   success: response['success'],
      //   message: response['message'],
      //   token: response['token'],
      //   user: response['user'],
      // ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> sendOTP({
    required String phone,
  }) async {
    try {
      emit(AuthLoading());
      await _authService.sendOTP(phone: phone);

      // Revenir à l'état initial après l'envoi de l'OTP
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyOTP({
    required String id,
    required int otp,
    required BuildContext context,
  }) async {
    try {
      emit(AuthLoading());
      final response = await _authService.verifyOTP(
        id: id,
        otp: otp,
      );

      print(response);
       Navigator.pushNamed(context, '/login');

      if (response['status'] == 200 || response['status'] == 201) {
        Navigator.pushNamed(context, '/login');
      }

      // Émettre un état de succès au lieu de revenir à l'état initial
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> login({
    required String uid,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      
      // VÉRIFIER D'ABORD si le compte a été supprimé AVANT d'appeler l'API
      final prefs = await SharedPreferences.getInstance();
      final removeAccountStr = prefs.getString('removeAccount');
      
      print('🔍 AuthCubit: Vérification removeAccount AVANT connexion: $removeAccountStr');
      
      if (removeAccountStr != null) {
        try {
          final removeAccountData = jsonDecode(removeAccountStr);
          final isRemove = removeAccountData['isRemove'] ?? false;
          final phone = removeAccountData['phone'] ?? '';
          
          print('🔍 AuthCubit: isRemove: $isRemove, phone: $phone, uid: $uid');
          
          if (isRemove == true && phone == uid) {
            print('🚫 AuthCubit: Compte supprimé détecté pour ce numéro, refus de connexion');
            // Effacer la variable removeAccount après vérification
            await prefs.remove('removeAccount');
            emit(AuthError('Mot de passe ou identifiant incorrect'));
            return;
          }
        } catch (e) {
          print('⚠️ AuthCubit: Erreur lors du parsing removeAccount: $e');
        }
      }
      
      // Si pas de blocage, procéder à la connexion
      final response = await _authService.login(
        uid: uid,
        password: password,
      );

      print(response);

      // Vérifier si la connexion a réussi (status 200 ou équivalent)
      if (response['token'] != null) {
        final token = response['token'] is Map 
            ? response['token']['token'] 
            : response['token'];
        
        print('🔑 [AuthCubit] Token reçu lors de la connexion:');
        print('   Token complet: $token');
        print('   Longueur du token: ${token.toString().length} caractères');
        
        print('💾 [AuthCubit] Sauvegarde de la session...');
        
        // Sauvegarder le token et les données utilisateur avec StorageService
        await _storageService.saveToken(token.toString());
        await _storageService.saveUserData(jsonEncode(response['user']));
        
        // AUSSI sauvegarder dans SharedPreferences avec les mêmes clés que AuthGateService
        // pour garantir la persistance de session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token.toString()); // Même clé que AuthGateService
        await prefs.setString('user_data', jsonEncode(response['user'])); // Même clé que AuthGateService
        await prefs.setString('last_login', DateTime.now().toIso8601String());
        
        if (response['token'] is Map && response['token']['expiresAt'] != null) {
          await prefs.setString('auth_expiry', response['token']['expiresAt']);
        }
        
        // Marquer que ce n'est plus la première fois
        await prefs.setBool('is_first', false);
        
        print('✅ [AuthCubit] Session sauvegardée avec succès');
        print('✅ Token sauvegardé: $token');
        print('✅ User sauvegardé: ${response['user']}');
      }

      print(response);

      emit(AuthSuccess(
        success: true,
        message: 'Connexion réussie',
        token: response['token']['token'],
        user: response['user'],
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    // Reset complet : effacer via StorageService ET AuthGateService
    await _storageService.clearAll();
    final authGateService = AuthGateService();
    await authGateService.clearSession();
    emit(AuthInitial());
  }

  Future<void> checkAuth() async {
    try {
      print('🔍 [AuthCubit] Vérification de l\'authentification...');
      
      // Essayer d'abord avec StorageService (clé 'auth_token')
      var token = await _storageService.getToken();
      var userData = await _storageService.getUserData();
      
      // Si pas trouvé, essayer avec les clés de AuthGateService (clé 'token')
      if (token == null || userData == null) {
        print('🔍 [AuthCubit] Token non trouvé dans StorageService, vérification SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('token'); // Clé utilisée par AuthGateService
        userData = prefs.getString('user_data'); // Clé utilisée par AuthGateService
        
        // Si trouvé dans SharedPreferences, synchroniser avec StorageService
        if (token != null && userData != null) {
          print('✅ [AuthCubit] Session trouvée dans SharedPreferences, synchronisation...');
          await _storageService.saveToken(token);
          await _storageService.saveUserData(userData);
        }
      }

      if (token != null && userData != null) {
        // Session valable indéfiniment tant que l'utilisateur ne se déconnecte pas
        try {
          final user = jsonDecode(userData);
          print('✅ [AuthCubit] Session restaurée pour: ${user['firstName']} ${user['lastName']}');
          emit(AuthSuccess(
            success: true,
            message: 'Session restaurée',
            token: token,
            user: user,
          ));
        } catch (e) {
          print('❌ [AuthCubit] Erreur lors du parsing des données utilisateur: $e');
          await _storageService.clearAll();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('user_data');
          emit(AuthInitial());
        }
      } else {
        print('❌ [AuthCubit] Aucune session trouvée');
        emit(AuthInitial());
      }
    } catch (e) {
      print('❌ [AuthCubit] Erreur lors de la vérification: $e');
      await _storageService.clearAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_data');
      emit(AuthInitial());
    }
  }

  // Method to update the user information after profile changes (like profile image)
  Future<void> updateUser(Map<String, dynamic> userData, String token) async {
    try {
      // Save the updated user data
      await _storageService.saveUserData(jsonEncode(userData));

      // Update the current state with the new user data
      emit(AuthSuccess(
        success: true,
        message: 'Informations utilisateur mises à jour',
        token: token,
        user: userData,
      ));
    } catch (e) {
      // Don't change the state on error, just log it or handle silently
      print('Error updating user data: $e');
    }
  }
}
