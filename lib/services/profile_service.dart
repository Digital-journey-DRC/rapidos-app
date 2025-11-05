import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants.dart';

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
    try {
      final uri = Uri.parse('$baseUrl/users/profile/image');
      
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['accept'] = '*/*';
      
      // Add image file as multipart form data
      var multipartFile = await http.MultipartFile.fromPath(
        'image',  // Using 'image' as the field name exactly as in the cURL command
        imageFile.path,
        // Specify content type to match the cURL command
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
      
      // Set timeout to avoid hanging indefinitely
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('The request timed out');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Successfully uploaded
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        } else {
          // Some APIs return empty body on success
          return {'success': true};
        }
      } else {
        throw Exception('Failed to upload profile image. Status code: ${response.statusCode}, Response: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timed out while uploading profile image');
    } on SocketException {
      throw Exception('No internet connection while uploading profile image');
    } on HttpException {
      throw Exception('HTTP error while uploading profile image');
    } catch (e) {
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
}
