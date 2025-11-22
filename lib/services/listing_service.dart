import 'dart:convert';
import 'package:http/http.dart' as http;

class ListingService {
  final String baseUrl = 'http://68.183.30.146:8000';

  Future<Map<String, dynamic>> createListing({
    required String apartmentId,
    required String title,
    required String description,
    required double price,
    required DateTime availableFrom,
    required int minimumStay,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/listings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'apartmentId': apartmentId,
          'title': title,
          'description': description,
          'price': price,
          'availableFrom': availableFrom.toIso8601String().split('T')[0],
          'minimumStay': minimumStay,
          'status': 'active',
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Erreur lors de la création de l\'annonce: ${response.body}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Map<String, dynamic>> getListings({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/listings?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          final listings = responseData['data'] as List<dynamic>;
          final formattedListings = listings.map((listing) {
            final apartment = listing['apartmentId'] as Map<String, dynamic>;
            final building = apartment['buildingId'] as Map<String, dynamic>;
            final address = building['address'] as Map<String, dynamic>;
            final publisher = listing['publisher'] as Map<String, dynamic>;
            final price = listing['price'] as Map<String, dynamic>;
            final apartmentPrice = apartment['price'] as Map<String, dynamic>;
            final features = apartment['features'] as Map<String, dynamic>;
            final images = listing['apartmentId']['images'] as List<dynamic>;

            return {
              'listingId': listing['_id'],
              'apartmentId': apartment['_id'],
              'buildingId': building['_id'],
              'buildingName': building['name'],
              'address': {
                'street': address['street'],
                'city': address['city'],
                'postalCode': address['postalCode'],
                'country': address['country'],
              },
              'type': apartment['type'],
              'surface': apartment['surface'],
              'rooms': apartment['rooms'],
              'bathrooms': apartment['bathrooms'],
              'price': {
                'amount': price['amount'],
                'currency': price['currency'],
                'negotiable': price['negotiable'],
                'paymentFrequency': apartmentPrice['paymentFrequency'],
              },
              'features': {
                'furnished': features['furnished'] ?? false,
                'airConditioning': features['airConditioning'] ?? false,
                'balcony': features['balcony'] ?? false,
                'internet': features['internet'] ?? false,
                'parking': features['parking'] ?? false,
                'securitySystem': features['securitySystem'] ?? false,
              },
              'images': images,
              'title': listing['title'],
              'description': listing['description'],
              'publisher': {
                'id': publisher['_id'],
                'name': '${publisher['firstName']} ${publisher['lastName']}',
                'phone': publisher['phone'],
              },
              'status': listing['status'],
              'views': listing['views'],
              // 'images': listing['images'] ?? [],
              'createdAt': listing['createdAt'],
              'updatedAt': listing['updatedAt'],
              'availability': listing['availability'],
              'contactPreferences': listing['contactPreferences'],
            };
          }).toList();

          return {
            'success': true,
            'count': responseData['count'],
            'total': responseData['total'],
            'pages': responseData['pages'],
            'currentPage': responseData['currentPage'],
            'data': formattedListings,
          };
        }
      }

      print('HTTP Error: ${response.statusCode} - ${response.body}');
      return {
        'success': false,
        'message': 'Erreur lors de la récupération des annonces (${response.statusCode})',
      };
    } on http.ClientException catch (e) {
      print('Connection error in getListings: $e');
      return {
        'success': false,
        'message': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } on Exception catch (e) {
      print('Error in getListings: $e');
      return {
        'success': false,
        'message': e.toString().contains('Timeout') 
            ? 'La connexion au serveur a pris trop de temps. Veuillez réessayer.'
            : 'Erreur de connexion: ${e.toString()}',
      };
    } catch (e, stackTrace) {
      print('Unexpected error in getListings: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue. Veuillez réessayer plus tard.',
      };
    }
  }

  Future<Map<String, dynamic>> getUserListings({
    required String token,
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/listings/user/$userId?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print('HTTP Error: ${response.statusCode} - ${response.body}');
      return {
        'success': false,
        'message': 'Erreur lors de la récupération des annonces',
      };
    } on http.ClientException catch (e) {
      print('Connection error in getUserListings: $e');
      return {
        'success': false,
        'message': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } on Exception catch (e) {
      print('Error in getUserListings: $e');
      return {
        'success': false,
        'message': e.toString().contains('Timeout') 
            ? 'La connexion au serveur a pris trop de temps. Veuillez réessayer.'
            : 'Erreur de connexion: ${e.toString()}',
      };
    } catch (e, stackTrace) {
      print('Unexpected error in getUserListings: $e');
      print('Stack trace: $stackTrace');
      
      // Gestion spécifique des erreurs de connexion
      String errorMessage = 'Une erreur est survenue';
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('SocketException')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'La connexion au serveur a pris trop de temps. Veuillez réessayer.';
      } else if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'Impossible de trouver le serveur. Vérifiez votre connexion internet.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }
}
