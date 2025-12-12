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
        // Sauvegarder le token et les données utilisateur
        await _storageService.saveToken(response['token']['token']);
        await _storageService.saveUserData(jsonEncode(response['user']));
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
      final token = await _storageService.getToken();
      final userData = await _storageService.getUserData();
      final lastLogin = await _storageService.getLastLoginTime();

      if (token != null && userData != null && lastLogin != null) {
        // Session valable 24h depuis la dernière connexion
        final now = DateTime.now();
        final difference = now.difference(lastLogin);
        if (difference.inHours >= 24) {
          // Session expirée après 24h
          await _storageService.clearAll();
          emit(AuthInitial());
          return;
        }

        try {
          final user = jsonDecode(userData);
          emit(AuthSuccess(
            success: true,
            message: 'Session restaurée',
            token: token,
            user: user,
          ));
        } catch (e) {
          await _storageService.clearAll();
          emit(AuthInitial());
        }
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      await _storageService.clearAll();
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
