import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ProfileService {
  final String baseUrl = 'http://24.144.87.127:3333';

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String token,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      print('🔄 Mise à jour du profil pour l\'utilisateur: $userId');
      print('📝 Données à envoyer: firstName=$firstName, lastName=$lastName, email=$email, phone=$phone');
      
      // Préparer le body JSON
      final body = <String, dynamic>{};
      if (firstName != null && firstName.isNotEmpty) body['firstName'] = firstName;
      if (lastName != null && lastName.isNotEmpty) body['lastName'] = lastName;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      
      print('📦 Body JSON: ${jsonEncode(body)}');
      
      // Faire la requête POST
      final response = await http.post(
        Uri.parse('$baseUrl/users/update/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Headers: ${response.headers}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Profil mis à jour avec succès');
        return jsonDecode(response.body);
      } else {
        print('❌ Erreur lors de la mise à jour du profil: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        throw Exception('Failed to update profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du profil: $e');
      throw Exception('Error updating profile: $e');
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage({
    required String token,
    required File imageFile,
  }) async {
    // print('📤 [PROFILE PHOTO] ProfileService.uploadProfileImage() appelée');
    // print('📤 [PROFILE PHOTO] URL: $baseUrl/users/profile/image');
    // print('📤 [PROFILE PHOTO] Chemin fichier: ${imageFile.path}');
    // print('📤 [PROFILE PHOTO] Fichier existe: ${await imageFile.exists()}');
    // if (await imageFile.exists()) {
    //   print('📤 [PROFILE PHOTO] Taille fichier: ${await imageFile.length()} bytes');
    // }
    
    try {
      final uri = Uri.parse('$baseUrl/users/profile/image');
      // print('📤 [PROFILE PHOTO] URI créée: $uri');
      
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['accept'] = '*/*';
      // print('📤 [PROFILE PHOTO] Headers configurés');
      
      // Add image file as multipart form data
      // print('📤 [PROFILE PHOTO] Création du MultipartFile...');
      var multipartFile = await http.MultipartFile.fromPath(
        'image',  // Using 'image' as the field name exactly as in the cURL command
        imageFile.path,
        // Specify content type to match the cURL command
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
      // print('✅ [PROFILE PHOTO] MultipartFile créé et ajouté à la requête');
      
      // Set timeout to avoid hanging indefinitely
      // print('📤 [PROFILE PHOTO] Envoi de la requête (timeout: 30s)...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          // print('❌ [PROFILE PHOTO] Timeout lors de l\'envoi de la requête');
          throw TimeoutException('The request timed out');
        },
      );
      // print('✅ [PROFILE PHOTO] Requête envoyée, status code: ${streamedResponse.statusCode}');
      
      final response = await http.Response.fromStream(streamedResponse);
      // print('📤 [PROFILE PHOTO] Réponse reçue');
      // print('📤 [PROFILE PHOTO] Status code: ${response.statusCode}');
      // print('📤 [PROFILE PHOTO] Response body: ${response.body}');
      // print('📤 [PROFILE PHOTO] Response body length: ${response.body.length}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // print('✅ [PROFILE PHOTO] Upload réussi (status code: ${response.statusCode})');
        // Successfully uploaded
        if (response.body.isNotEmpty) {
          // print('📤 [PROFILE PHOTO] Parsing de la réponse JSON...');
          final parsedResponse = jsonDecode(response.body);
          // print('✅ [PROFILE PHOTO] Réponse parsée: $parsedResponse');
          return parsedResponse;
        } else {
          // print('⚠️ [PROFILE PHOTO] Réponse vide, retour de {\'success\': true}');
          // Some APIs return empty body on success
          return {'success': true};
        }
      } else {
        // print('❌ [PROFILE PHOTO] Échec de l\'upload - Status code: ${response.statusCode}');
        // print('❌ [PROFILE PHOTO] Response body: ${response.body}');
        throw Exception('Failed to upload profile image. Status code: ${response.statusCode}, Response: ${response.body}');
      }
    } on TimeoutException catch (e) {
      // print('❌ [PROFILE PHOTO] TimeoutException: $e');
      throw Exception('Request timed out while uploading profile image');
    } on SocketException catch (e) {
      // print('❌ [PROFILE PHOTO] SocketException: $e');
      throw Exception('No internet connection while uploading profile image');
    } on HttpException catch (e) {
      // print('❌ [PROFILE PHOTO] HttpException: $e');
      throw Exception('HTTP error while uploading profile image');
    } catch (e, stackTrace) {
      // print('❌ [PROFILE PHOTO] Erreur inattendue: $e');
      // print('❌ [PROFILE PHOTO] Stack trace: $stackTrace');
      throw Exception('Error uploading profile image: $e');
    }
  }

  Future<Map<String, dynamic>> getUserBalance({
    required String userId,
    required String token,
  }) async {
    try {
      // Simulation de données financières (en attendant que l'API soit prête)
      await Future.delayed(const Duration(milliseconds: 800)); // Simulation de délai réseau
      
      // Données simulées
      return {
        'success': true,
        'balance': 2450.75,
        'currency': 'USD',
        'pendingIncome': 1500.00,
        'pendingExpenses': 350.25,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
      
      /* Commenté en attendant que l'API soit prête
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/balance'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user balance: ${response.body}');
      }
      */
    } catch (e) {
      throw Exception('Error getting user balance: $e');
    }
  }
  
  Future<Map<String, dynamic>> getIncomeSummary({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/income-summary'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get income summary: ${response.body}');
      }
    } on SocketException {
      throw Exception('No internet connection while fetching income summary');
    } on HttpException {
      throw Exception('HTTP error while fetching income summary');
    } catch (e) {
      throw Exception('Error getting income summary: $e');
    }
  }

  /// Met à jour le numéro de téléphone et envoie un OTP
  Future<Map<String, dynamic>> updatePhone({
    required String token,
    required String newPhone,
  }) async {
    try {
      print('🔄 Mise à jour du numéro de téléphone: $newPhone');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/update-phone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'newPhone': newPhone,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      // Gérer les cas où la réponse n'est pas du JSON valide
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('⚠️ Erreur de parsing JSON: $e');
        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Code OTP envoyé avec succès au nouveau numéro',
            'data': {},
          };
        }
      }
      
      if (response.statusCode == 200) {
        print('✅ OTP envoyé avec succès');
        return {
          'success': true,
          'message': data['message']?.toString() ?? 'Code OTP envoyé avec succès au nouveau numéro',
          'data': data,
        };
      } else if (response.statusCode == 400) {
        // Nouveau numéro requis ou identique à l'ancien
        final message = data['message']?.toString() ?? 'Le nouveau numéro de téléphone doit être différent de l\'ancien';
        throw Exception(message);
      } else if (response.statusCode == 401) {
        // Non autorisé
        final message = data['message']?.toString() ?? 'Vous devez être connecté pour modifier votre numéro de téléphone';
        throw Exception(message);
      } else if (response.statusCode == 409) {
        // Numéro déjà utilisé
        final message = data['message']?.toString() ?? 'Ce numéro de téléphone est déjà utilisé par un autre utilisateur';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur serveur
        final message = data['message']?.toString() ?? 'Erreur serveur interne. Veuillez réessayer plus tard';
        throw Exception(message);
      } else {
        print('❌ Erreur lors de l\'envoi de l\'OTP: ${response.statusCode}');
        final message = data['message']?.toString() ?? 'Erreur lors de l\'envoi de l\'OTP';
        throw Exception(message);
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du téléphone: $e');
      if (e is String) {
        throw e;
      }
      if (e.toString().contains('Exception:')) {
        // Si c'est déjà une Exception avec un message, la relancer telle quelle
        rethrow;
      }
      throw Exception('Erreur lors de la mise à jour du téléphone: $e');
    }
  }

  /// Change le mot de passe de l'utilisateur
  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      print('🔄 Changement de mot de passe');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      // Gérer les cas où la réponse n'est pas du JSON valide
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('⚠️ Erreur de parsing JSON: $e');
        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Mot de passe modifié avec succès',
            'data': {},
          };
        }
      }
      
      if (response.statusCode == 200) {
        print('✅ Mot de passe modifié avec succès');
        return {
          'success': true,
          'message': data['message']?.toString() ?? 'Mot de passe modifié avec succès',
          'data': data,
        };
      } else if (response.statusCode == 400) {
        // Ancien mot de passe incorrect ou nouveau mot de passe invalide
        final message = data['message']?.toString() ?? 'Ancien mot de passe incorrect ou nouveau mot de passe invalide';
        throw Exception(message);
      } else if (response.statusCode == 401) {
        // Non autorisé
        final message = data['message']?.toString() ?? 'Vous devez être connecté pour modifier votre mot de passe';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur serveur
        final message = data['message']?.toString() ?? 'Erreur serveur interne. Veuillez réessayer plus tard';
        throw Exception(message);
      } else {
        print('❌ Erreur lors du changement de mot de passe: ${response.statusCode}');
        final message = data['message']?.toString() ?? 'Erreur lors du changement de mot de passe';
        throw Exception(message);
      }
    } catch (e) {
      print('❌ Erreur lors du changement de mot de passe: $e');
      if (e is String) {
        throw e;
      }
      if (e.toString().contains('Exception:')) {
        // Si c'est déjà une Exception avec un message, la relancer telle quelle
        rethrow;
      }
      throw Exception('Erreur lors du changement de mot de passe: $e');
    }
  }

  /// Vérifie l'OTP pour le nouveau numéro de téléphone
  Future<Map<String, dynamic>> verifyPhoneOTP({
    required String token,
    required String otp,
    required String newPhone,
  }) async {
    try {
      print('🔄 Vérification de l\'OTP pour le téléphone: $newPhone');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/verify-phone-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'otp': otp,
          'newPhone': newPhone,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Numéro de téléphone vérifié avec succès');
        return {
          'success': true,
          'data': data,
        };
      } else {
        print('❌ Erreur lors de la vérification de l\'OTP: ${response.statusCode}');
        throw Exception(data['message'] ?? 'Code OTP incorrect');
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'OTP: $e');
      if (e is String) {
        throw e;
      }
      throw Exception('Erreur lors de la vérification de l\'OTP: $e');
    }
  }
}
