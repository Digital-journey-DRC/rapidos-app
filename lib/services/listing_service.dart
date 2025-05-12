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
          'Authorization': 'Bearer $token',
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
        'message': 'Erreur lors de la récupération des annonces',
      };
    } catch (e, stackTrace) {
      print('Error in getListings: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Une erreur est survenue',
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
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print('HTTP Error: ${response.statusCode} - ${response.body}');
      return {
        'success': false,
        'message': 'Erreur lors de la récupération des annonces',
      };
    } catch (e, stackTrace) {
      print('Error in getUserListings: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Une erreur est survenue',
      };
    }
  }
}
