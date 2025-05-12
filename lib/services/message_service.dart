import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MessageService {
  String? _token;

  // Récupérer toutes les conversations
  Future<Map<String, dynamic>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/messages/conversations'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les messages d'une conversation spécifique
  Future<Map<String, dynamic>> getConversationMessages(String conversationId, {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/messages/conversations/$conversationId/messages?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Ajouter un token d'authentification
  void setAuthToken(String token) {
    _token = token;
  }
}
