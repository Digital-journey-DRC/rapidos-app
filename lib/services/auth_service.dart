import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth/login_screen.dart';

class AuthService {
  static const String baseUrl = 'http://24.144.87.127:3333';

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
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {
              "email": email,
              "password": password,
              "firstName": firstName,
              "lastName": lastName,
              "phone": phone,
              "role": role,
              "termsAccepted": true
            }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 400) {
        if (data['errors'][0]['message']?.contains('email') ?? false) {
          throw 'Cet email est déjà utilisé';
        } else if (data['errors'][0]['message']?.contains('phone') ?? false) {
          throw 'Ce numéro de téléphone est déjà utilisé';
        } else if (data['errors'][0]['message']?.contains('passe') ?? false) {
          throw data['errors'][0]['message'];
        } else if (data['errors'][0]['message']?.contains('password') ??
            false) {
          throw 'le format du mot de passe est incorrect';
        } else {
          throw "Erreur d'enregistrement";
        }
        // if (data['message']?.contains('email') ?? false) {
        //   throw 'Cet email est déjà utilisé';
        // } else if (data['message']?.contains('phone') ?? false) {
        //   throw 'Ce numéro de téléphone est déjà utilisé';
        // }
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw data['message'] ??
            'Une erreur est survenue lors de l\'inscription';
      }

      print(data);
      envoyerSms(phone, "Votre code de vérification est : ${data['otp']}");

      return data;
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Une erreur est survenue. Veuillez réessayer plus tard.';
    }
  }

  void envoyerSms(String phone, String message) async {
  final url = Uri.parse('https://nmlygy.api.infobip.com/sms/2/text/advanced');

  final headers = {
    'Authorization': 'App d5819848b9e86ee925a9ec584c4d1d91-9ed8758c-2081-4ac2-9192-b2d136e782dd',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final body = jsonEncode({
    "messages": [
      {
        "destinations": [
          {"to": phone }
        ],
        "from": "447491163443",
        "text": message
      }
    ]
  });

  try {
    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Message envoyé avec succès : ${response.body}');
    } else {
      print('Erreur lors de l\'envoi du message : ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Exception : $e');
  }
}

  Future<Map<String, dynamic>> verifyOTP(
      {required String id, required int otp}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'otp': otp}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw data['message'] ??
            'Une erreur est survenue lors de l\'envoi du code OTP';
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
        throw data['message'] ??
            'Une erreur est survenue lors de l\'envoi du code OTP';
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
    required String uid,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'password': password,
    //           "uid": "+243999999996",
    // "password": "Petitstanis@95"
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
        throw data['message'] ??
            'Une erreur est survenue lors de la réinitialisation du mot de passe';
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
