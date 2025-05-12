import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth/login_screen.dart';

class AuthService {
  static const String baseUrl = 'http://68.183.30.146:8000';

  Future<void> checkAuth(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/auth/verify-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        await prefs.remove('token');
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<Map<String, dynamic>> register({
    required String otp,
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'otp': otp,
          'phone': phone,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 400) {
        if (data['message']?.contains('email') ?? false) {
          throw 'Cet email est déjà utilisé';
        } else if (data['message']?.contains('phone') ?? false) {
          throw 'Ce numéro de téléphone est déjà utilisé';
        }
      }
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw data['message'] ?? 'Une erreur est survenue lors de l\'inscription';
      }
      
      return data;
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Une erreur est survenue. Veuillez réessayer plus tard.';
    }
  }

    Future<Map<String, dynamic>> verifyOTP({
    required String number,
    required String otp
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'number': number,
          'otp': otp
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw data['message'] ?? 'Une erreur est survenue lors de l\'envoi du code OTP';
      }
      return data;
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Une erreur est survenue. Veuillez réessayer plus tard.';
    }
  }


  Future<Map<String, dynamic>> sendOTP({
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'number': phone,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw data['message'] ?? 'Une erreur est survenue lors de l\'envoi du code OTP';
      }
      return data;
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Une erreur est survenue. Veuillez réessayer plus tard.';
    }
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 400) {
        if (data['message']?.contains('password') ?? false) {
          throw 'Mot de passe incorrect';
        } else if (data['message']?.contains('user') ?? false) {
          throw 'Numéro de téléphone non trouvé';
        }
      }
      
      if (response.statusCode != 200) {
        throw data['message'] ?? 'Une erreur est survenue lors de la connexion';
      }
      return data;
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Une erreur est survenue. Veuillez réessayer plus tard.';
    }
  }
  
  Future<Map<String, dynamic>> changePasswordWithOTP({
    required String number,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/change-password-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'number': number,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw data['message'] ?? 'Une erreur est survenue lors de la réinitialisation du mot de passe';
      }
      return data;
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Une erreur est survenue. Veuillez réessayer plus tard.';
    }
  }
}
