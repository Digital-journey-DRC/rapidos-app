import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants.dart';

class ProfileService {
  final String baseUrl = 'http://68.183.30.146:8000/api/v1';

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String token,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
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
