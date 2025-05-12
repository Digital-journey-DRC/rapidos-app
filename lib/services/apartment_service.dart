import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApartmentService {
  static const String baseUrl = 'http://68.183.30.146:8000';

  Future<List<Map<String, dynamic>>> getApartmentsByBuilding(String buildingId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/apartments/building/$buildingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      print('Response Data: $responseData'); // Debug print
      
      if (responseData['success'] == true && responseData['data'] != null) {
        if (responseData['data'] is List) {
          final List<dynamic> apartments = responseData['data'];
          return apartments.map((apartment) => apartment as Map<String, dynamic>).toList();
        } else if (responseData['data'] is Map) {
          // Si data est un objet unique, on le retourne dans une liste
          return [responseData['data'] as Map<String, dynamic>];
        } else {
          throw Exception('Format de données inattendu');
        }
      } else {
        throw Exception('Format de réponse invalide');
      }
    } else {
      throw Exception('Impossible de récupérer les appartements: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createApartment({
    required String token,
    required String buildingId,
    required String number,
    required String type,
    required int floor,
    required double surface,
    required int rooms,
    required int bathrooms,
    required double amount,
    required String currency,
    required String paymentFrequency,
    required String description,
    required Map<String, bool> features,
    required String status,
    required bool taxe,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/apartments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'buildingId': buildingId,
        'number': number,
        'type': type,
        'floor': floor,
        'surface': surface,
        'rooms': rooms,
        'bathrooms': bathrooms,
        'price': {
          'amount': amount,
          'currency': currency,
          'paymentFrequency': paymentFrequency,
        },
        'description': description,
        'features': features,
        'status': status,
        'taxe': taxe,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create apartment: ${response.body}');
    }
  }

    Future<Map<String, dynamic>> uploadApartmentImages({
    required String apartmentId, 
    required List<String> imagePaths, 
    required String token
  }) async {
    try {
      print('Début de uploadBuildingImages pour buildingId: $apartmentId');
      print('Nombre d\'images à télécharger: ${imagePaths.length}');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/apartments/$apartmentId/images'),
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
