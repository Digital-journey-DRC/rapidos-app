import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

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
    required String otp,
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      emit(AuthLoading());
      final response = await _authService.register(
        otp: otp,
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      
      // Sauvegarder le token et les données utilisateur
      if (response['token'] != null) {
        await _storageService.saveToken(response['token']);
        await _storageService.saveUserData(jsonEncode(response['user']));
      }
      
      emit(AuthSuccess(
        success: response['success'],
        message: response['message'],
        token: response['token'],
        user: response['user'],
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> sendOTP({
    required String phone,
  }) async {
    try {
      emit(AuthLoading());
      final response = await _authService.sendOTP(
        phone: phone,
      );
      
      // Revenir à l'état initial après l'envoi de l'OTP
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  

    Future<void> verifyOTP({
    required String number,
    required String otp,
  }) async {
    try {
      emit(AuthLoading());
      final response = await _authService.verifyOTP(
        number: number,
        otp: otp,
      );
      
      // Émettre un état de succès au lieu de revenir à l'état initial
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }


  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      final response = await _authService.login(
        identifier: identifier,
        password: password,
      );
      
      // Sauvegarder le token et les données utilisateur
      if (response['token'] != null) {
        await _storageService.saveToken(response['token']);
        await _storageService.saveUserData(jsonEncode(response['user']));
      }
      
      emit(AuthSuccess(
        success: response['success'],
        message: 'Connexion réussie',
        token: response['token'],
        user: response['user'],
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    emit(AuthInitial());
  }
  
  Future<void> checkAuth() async {
    try {
      final token = await _storageService.getToken();
      final userData = await _storageService.getUserData();
      final lastLogin = await _storageService.getLastLoginTime();
      
      if (token != null && userData != null && lastLogin != null) {
        // Check if 23 hours have passed since last login
        final now = DateTime.now();
        final difference = now.difference(lastLogin);
        if (difference.inHours >= 23) {
          // Session expired after 23 hours
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
