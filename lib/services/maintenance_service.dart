import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class MaintenanceService {
  final String baseUrl = 'http://68.183.30.146:8000';

  Future<Map<String, dynamic>> createMaintenance(Map<String, dynamic> maintenanceData, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/maintenances'),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(maintenanceData),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      print('API Response: $responseData');

      if (response.statusCode == 201) {
        final maintenanceId = responseData['_id'] ?? responseData['data']?['_id'];
        print('Maintenance ID: $maintenanceId');
        
        return {
          'success': true,
          'message': 'Maintenance créée avec succès',
          'data': {
            '_id': maintenanceId,
            ...responseData
          }
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Erreur lors de la création de la maintenance'
      };
    } catch (e) {
      print('Error creating maintenance: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }

  Future<Map<String, dynamic>> uploadMaintenanceImages({
    required String maintenanceId,
    required List<File> images,
    required String token,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/api/v1/maintenances/$maintenanceId/images');
      var request = http.MultipartRequest('POST', uri);
      
      request.headers.addAll({
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      });

      // Add each image as a separate 'images' field
      for (var image in images) {
        String ext = path.extension(image.path).toLowerCase();
        String mimeType = ext == '.png' ? 'image/png' : 'image/jpeg';
        
        var stream = http.ByteStream(image.openRead());
        var length = await image.length();
        
        var multipartFile = http.MultipartFile(
          'images', // Field name must be 'images' for each file
          stream,
          length,
          filename: path.basename(image.path),
          contentType: MediaType.parse(mimeType),
        );
        
        request.files.add(multipartFile);
      }

      print('Uploading ${images.length} images to maintenance $maintenanceId');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          responseData = {'message': 'Images téléchargées avec succès'};
        }
        
        return {
          'success': true,
          'message': 'Images téléchargées avec succès',
          'data': responseData
        };
      }

      Map<String, dynamic> errorData;
      try {
        errorData = jsonDecode(response.body);
      } catch (e) {
        errorData = {'message': 'Erreur lors du téléchargement des images'};
      }

      return {
        'success': false,
        'message': errorData['message'] ?? 'Erreur lors du téléchargement des images'
      };
    } catch (e) {
      print('Error uploading images: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }
}
