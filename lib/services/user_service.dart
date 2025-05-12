import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'http://68.183.30.146:8000';

  Future<Map<String, dynamic>> searchUsers({
    required String query,
    required String token,
    String role = 'locataire',
    int limit = 10,
    int page = 1,
  }) async {
    try {
      // Utiliser Uri.http pour encoder correctement les paramètres de requête
      final uri = Uri.http(
        baseUrl.replaceAll('http://', ''),
        '/api/v1/users/search',
        {
          'query': query,
          'role': role,
          'limit': limit.toString(),
          'page': page.toString(),
        },
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Erreur lors de la recherche des utilisateurs');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
