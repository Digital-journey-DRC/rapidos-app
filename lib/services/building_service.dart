import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/building.dart';
import '../cubit/auth_cubit.dart';

class BuildingService {
  static const String baseUrl = 'http://68.183.30.146:8000';

  Future<void> createBuilding(Building building, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/buildings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(building.toJson()),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Erreur lors de la création: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Map<String, dynamic>> getUserBuildings(String userId, String token, {int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/buildings/user/$userId?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la récupération: ${response.body}');
      }

      final data = jsonDecode(response.body);
      print('Raw API Response: ${response.body}'); // Debug print
      return data;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Map<String, dynamic>> createApartment(String token, Map<String, dynamic> apartmentData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/apartments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(apartmentData),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Erreur lors de la création: ${response.body}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Map<String, dynamic>> getBuilding(String buildingId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/buildings/$buildingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la récupération: ${response.body}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Map<String, dynamic>> getUserBuildingsWithApartments(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/buildings/user/$userId/apartments'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la récupération: ${response.body}');
      }

      final data = jsonDecode(response.body);
      print('Raw API Response: ${response.body}'); // Debug print
      return data;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Map<String, dynamic>> uploadBuildingImages({
    required String buildingId, 
    required List<String> imagePaths, 
    required String token,
    Function? onSuccess,
  }) async {
    try {
      print('Début de uploadBuildingImages pour buildingId: $buildingId');
      print('Nombre d\'images à télécharger: ${imagePaths.length}');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/buildings/$buildingId/images'),
      );

      // Ajouter le token d'authentification et les en-têtes comme dans la requête curl
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': '*/*',
      });
      
      // Calculer la taille totale des fichiers pour le debug
      int totalSize = 0;
      for (String path in imagePaths) {
        final file = File(path);
        if (file.existsSync()) {
          totalSize += file.lengthSync();
        }
      }
      print('Taille totale à uploader: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB');

      // Ajouter les fichiers à la requête, un par un, comme dans la requête curl
      int filesAdded = 0;
      for (String path in imagePaths) {
        final file = File(path);
        if (file.existsSync()) {
          final fileName = path.split('/').last;
          print('Ajout du fichier: $fileName, taille: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB');
          
          // Déterminer le type MIME basé sur l'extension du fichier
          String mimeType = 'image/jpeg'; // Par défaut
          if (fileName.toLowerCase().endsWith('.png')) {
            mimeType = 'image/png';
          } else if (fileName.toLowerCase().endsWith('.gif')) {
            mimeType = 'image/gif';
          } else if (fileName.toLowerCase().endsWith('.webp')) {
            mimeType = 'image/webp';
          }
          
          final fileStream = http.ByteStream(file.openRead());
          final fileLength = file.lengthSync();
          
          // Utiliser exactement le même nom de champ que dans la requête curl: 'images'
          final multipartFile = http.MultipartFile(
            'images',
            fileStream,
            fileLength,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          );
          
          request.files.add(multipartFile);
          filesAdded++;
          
          print('Fichier ajouté à la requête: $fileName avec type MIME: $mimeType');
        } else {
          print('ATTENTION: Le fichier n\'existe pas: $path');
        }
      }
      
      print('Nombre de fichiers ajoutés à la requête: $filesAdded');
      
      if (filesAdded == 0) {
        throw Exception('Aucun fichier valide à télécharger');
      }
      
      print('Envoi de la requête...');
      print('URL: ${request.url}');
      print('Headers: ${request.headers}');

      // Envoyer la requête
      final response = await request.send();
      
      // Lire la réponse
      final responseString = await response.stream.bytesToString();
      print('Réponse du serveur (status: ${response.statusCode}): $responseString');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Succès
        print('Téléchargement réussi!');
        
        // Appeler le callback de succès si fourni
        if (onSuccess != null) {
          onSuccess();
        }
        
        try {
          return jsonDecode(responseString);
        } catch (e) {
          print('Erreur lors du décodage de la réponse: $e');
          return {'message': 'Images téléchargées avec succès'};
        }
      } else {
        // Erreur
        print('Erreur HTTP ${response.statusCode}');
        print('Headers de la réponse: ${response.headers}');
        
        // Essayer de décoder la réponse pour voir s'il y a un message d'erreur
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(responseString);
          print('Message d\'erreur du serveur: ${errorData['message'] ?? 'Aucun message'}');
        } catch (e) {
          print('Impossible de décoder la réponse d\'erreur: $e');
        }
        
        throw Exception('Erreur lors du téléchargement des images: ${response.statusCode}. ${errorData['message'] ?? responseString}');
      }
    } catch (e) {
      print('Exception dans uploadBuildingImages: $e');
      throw Exception('Erreur lors du téléchargement des images: $e');
    }
  }
}
