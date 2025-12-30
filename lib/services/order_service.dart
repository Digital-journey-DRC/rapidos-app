import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

class OrderService {
  final String baseUrl = 'http://24.144.87.127:3333';

  /// Initialise une commande multi-vendeurs avec calcul GPS des frais de livraison
  /// Endpoint: POST /ecommerce/commandes/initialize
  /// Authentification: REQUISE
  /// 
  /// Crée automatiquement des sous-commandes séparées par vendeur.
  /// Calcule la distance entre l'acheteur et chaque vendeur pour déterminer les frais de livraison.
  /// Assigne automatiquement le moyen de paiement par défaut de chaque vendeur.
  Future<Map<String, dynamic>> initializeOrder({
    required List<Map<String, dynamic>> products,
    required double latitude,
    required double longitude,
    required Map<String, dynamic> address,
  }) async {
    print('🚀 [OrderService] initializeOrder - Début');
    print('📍 Latitude: $latitude, Longitude: $longitude');
    print('📦 Produits: ${products.length}');
    for (var product in products) {
      print('   - ProductId: ${product['productId']}, Quantite: ${product['quantite']}');
    }
    print('🏠 Adresse: $address');
    
    try {
      final token = await StorageService().getToken();
      print('🔑 Token récupéré: ${token != null ? 'Oui (${token.substring(0, 20)}...)' : 'Non'}');

      if (token == null) {
        print('❌ [OrderService] Token manquant');
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final url = '$baseUrl/ecommerce/commandes/initialize';
      final requestBody = {
        'products': products,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };
      
      final bodyJson = jsonEncode(requestBody);
      
      print('🌐 [OrderService] Envoi de la requête...');
      print('   URL: $url');
      print('═══════════════════════════════════════════════════════');
      print('📦 BODY ENVOYÉ:');
      print(bodyJson);
      print('═══════════════════════════════════════════════════════');
      
      // Breakpoint virtuel - peut être utilisé pour debugger
      assert(() {
        print('🛑 BREAKPOINT: Body avant envoi');
        return true;
      }());

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ [OrderService] Timeout après 15 secondes');
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      print('📡 [OrderService] Réponse reçue');
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ [OrderService] Succès (201)');
        print('   Orders count: ${(responseData['orders'] ?? []).length}');
        print('   Summary: ${responseData['summary']}');
        print('   Message: ${responseData['message']}');
        
        return {
          'success': true,
          'orders': responseData['orders'] ?? [],
          'summary': responseData['summary'] ?? {},
          'message': responseData['message'] ?? 'Commande(s) créée(s) avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ [OrderService] Erreur (${response.statusCode})');
        print('   Error data: $errorData');
        
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de l\'initialisation de la commande',
        };
      }
    } catch (e, stackTrace) {
      print('💥 [OrderService] Exception capturée');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupère toutes les commandes de l'acheteur connecté avec statistiques par statut
  /// Endpoint: GET /ecommerce/commandes/buyer/me
  /// Authentification: REQUISE
  /// 
  /// [status] (optionnel): Filtrer par statut (pending_payment, pending, en_preparation, etc.)
  Future<Map<String, dynamic>> getBuyerOrders({String? status}) async {
    print('📥 [OrderService] getBuyerOrders - Début');
    print('   Status filter: ${status ?? 'Aucun'}');
    
    try {
      final token = await StorageService().getToken();
      print('🔑 Token récupéré: ${token != null ? 'Oui (${token.substring(0, 20)}...)' : 'Non'}');

      if (token == null) {
        print('❌ [OrderService] Token manquant');
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
          'orders': [],
          'stats': {},
        };
      }

      // Construire l'URL avec le paramètre de statut si fourni
      final uri = status != null
          ? Uri.parse('$baseUrl/ecommerce/commandes/buyer/me?status=$status')
          : Uri.parse('$baseUrl/ecommerce/commandes/buyer/me');

      print('🌐 [OrderService] Envoi de la requête GET...');
      print('   URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ [OrderService] Timeout après 15 secondes');
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      print('📡 [OrderService] Réponse reçue');
      print('   Status Code: ${response.statusCode}');
      print('   Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ [OrderService] Succès (200)');
        print('   Orders count: ${(responseData['orders'] ?? []).length}');
        print('   Stats: ${responseData['stats']}');
        print('   Message: ${responseData['message']}');
        
        // Print des statistiques comme dans l'exemple JavaScript
        final stats = responseData['stats'] ?? {};
        print('📊 Statistiques reçues:');
        print('   Total: ${stats['total'] ?? 0} commandes');
        print('   En attente de paiement: ${stats['pending_payment'] ?? 0}');
        
        // Print des commandes comme dans l'exemple JavaScript
        final orders = responseData['orders'] ?? [];
        for (var order in orders) {
          final orderId = order['id']?.toString() ?? '';
          // Convertir total et deliveryFee qui peuvent être String ou double
          final totalValue = order['total'];
          final total = totalValue is double 
              ? totalValue 
              : (totalValue is String 
                  ? double.tryParse(totalValue) ?? 0.0 
                  : (totalValue is int 
                      ? totalValue.toDouble() 
                      : 0.0));
          
          final deliveryFeeValue = order['deliveryFee'];
          final deliveryFee = deliveryFeeValue is double 
              ? deliveryFeeValue 
              : (deliveryFeeValue is String 
                  ? double.tryParse(deliveryFeeValue) ?? 0.0 
                  : (deliveryFeeValue is int 
                      ? deliveryFeeValue.toDouble() 
                      : 0.0));
          
          final vendeur = order['vendeur'] ?? {};
          final paymentMethod = order['paymentMethod'] ?? {};
          print('📦 Commande #$orderId: ${total.toStringAsFixed(0)} FC + ${deliveryFee.toStringAsFixed(0)} FC livraison');
          print('   Vendeur: ${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}');
          print('   Moyen de paiement: ${paymentMethod['name'] ?? ''} (${paymentMethod['numeroCompte'] ?? ''})');
        }
        
        return {
          'success': true,
          'orders': orders,
          'stats': stats,
          'message': responseData['message'] ?? 'Commandes récupérées avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ [OrderService] Erreur (${response.statusCode})');
        print('   Error data: $errorData');
        
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des commandes',
          'orders': [],
          'stats': {},
        };
      }
    } catch (e, stackTrace) {
      print('💥 [OrderService] Exception capturée');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'orders': [],
        'stats': {},
      };
    }
  }

  /// Met à jour le moyen de paiement pour une commande spécifique
  /// Endpoint: PATCH /ecommerce/commandes/:id/payment-method
  /// Authentification: REQUISE
  /// 
  /// Le moyen de paiement doit appartenir au vendeur de la commande.
  /// Le statut passe automatiquement de "pending_payment" à "pending" après la mise à jour.
  Future<Map<String, dynamic>> updatePaymentMethod({
    required int orderId,
    required int paymentMethodId,
    String? numeroPayment,
  }) async {
    print('🔄 [OrderService] updatePaymentMethod - Début');
    print('   📦 OrderId (ID de la commande): $orderId');
    print('   💳 PaymentMethodId: $paymentMethodId');
    print('   📱 NumeroPayment: ${numeroPayment ?? 'Non fourni'}');
    
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        print('❌ [OrderService] Token manquant');
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final body = <String, dynamic>{
        'paymentMethodId': paymentMethodId,
      };
      
      if (numeroPayment != null && numeroPayment.isNotEmpty) {
        body['numeroPayment'] = numeroPayment;
      }

      print('📤 [OrderService] Requête PATCH: $baseUrl/ecommerce/commandes/$orderId/payment-method');
      print('📤 [OrderService] Body envoyé: ${jsonEncode(body)}');

      final response = await http.patch(
        Uri.parse('$baseUrl/ecommerce/commandes/$orderId/payment-method'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );
      
      print('📥 [OrderService] Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ [OrderService] Moyen de paiement mis à jour avec succès pour la commande $orderId');
        print('📦 [OrderService] Données de la commande mise à jour: ${responseData['order']?['id'] ?? 'N/A'}');
        return {
          'success': true,
          'order': responseData['order'] ?? {},
          'message': responseData['message'] ?? 'Moyen de paiement mis à jour avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ [OrderService] Erreur lors de la mise à jour - Status: ${response.statusCode}');
        print('❌ [OrderService] Message d\'erreur: ${errorData['message'] ?? 'Erreur inconnue'}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la mise à jour du moyen de paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Met à jour les moyens de paiement pour plusieurs commandes en une seule requête
  /// Endpoint: PATCH /ecommerce/commandes/batch-update-payment-methods
  /// Authentification: REQUISE
  /// 
  /// Utilise une transaction atomique (tout réussit ou tout échoue).
  /// Idéal pour éviter de faire plusieurs requêtes séparées.
  /// 
  /// [updates] : Liste de mises à jour, chaque élément contient:
  ///   - commandeId (required): ID de la commande
  ///   - paymentMethodId (required): ID du nouveau moyen de paiement
  ///   - numeroPayment (optional): Numéro de transaction de paiement
  Future<Map<String, dynamic>> batchUpdatePaymentMethods({
    required List<Map<String, dynamic>> updates,
  }) async {
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      if (updates.isEmpty) {
        return {
          'success': false,
          'message': 'La liste des mises à jour ne peut pas être vide',
        };
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/ecommerce/commandes/batch-update-payment-methods'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'updates': updates,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'orders': responseData['orders'] ?? [],
          'summary': responseData['summary'] ?? {},
          'message': responseData['message'] ?? 'Commande(s) mise(s) à jour avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la mise à jour des moyens de paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupère les commandes du vendeur
  /// Endpoint: GET /ecommerce/commandes/vendeur
  /// Authentification: REQUISE
  Future<Map<String, dynamic>> getVendeurOrders() async {
    print('🔄 [OrderService] getVendeurOrders - Début');
    
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        print('❌ [OrderService] Token manquant');
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
          'orders': [],
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/ecommerce/commandes/vendeur'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      print('📥 [OrderService] Réponse reçue - Status: ${response.statusCode}');
      print('📥 [OrderService] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final commandes = responseData['commandes'] ?? [];
        print('✅ [OrderService] ${commandes.length} commandes récupérées');
        
        // Transformer les commandes pour correspondre à la structure attendue
        final orders = commandes.map<Map<String, dynamic>>((commande) {
          // Helper pour parser les montants
          double parseAmount(dynamic value) {
            if (value is double) return value;
            if (value is int) return value.toDouble();
            if (value is String) return double.tryParse(value) ?? 0.0;
            return 0.0;
          }
          
          // Calculer totalAvecLivraison
          final total = parseAmount(commande['total'] ?? 0);
          final deliveryFee = parseAmount(commande['deliveryFee'] ?? 0);
          final totalAvecLivraison = total + deliveryFee;
          
          // Construire l'objet buyer à partir de client (string) et phone
          final buyer = {
            'email': commande['client'] ?? '',
            'phone': commande['phone'] ?? '',
          };
          
          // Transformer items en products pour la compatibilité
          final products = (commande['items'] as List? ?? []).map((item) {
            return {
              'name': item['name'] ?? '',
              'price': item['price'] ?? 0,
              'quantity': item['quantity'] ?? 1,
              'idVendeur': item['idVendeur'] ?? commande['vendorId'],
              'productId': item['productId'] ?? 0,
            };
          }).toList();
          
          return {
            'id': commande['id'],
            'orderId': commande['orderId'],
            'status': commande['status'],
            'vendeurId': commande['vendorId'],
            'buyer': buyer,
            'products': products,
            'items': products, // Pour compatibilité avec OrderDetailsScreen
            'client': commande['client'] ?? '', // Ajout direct pour OrderDetailsScreen
            'phone': commande['phone'] ?? '', // Ajout direct pour OrderDetailsScreen
            'total': total.toStringAsFixed(2),
            'deliveryFee': deliveryFee,
            'totalAvecLivraison': totalAvecLivraison,
            'address': commande['address'] ?? {},
            'latitude': commande['latitude']?.toString() ?? '',
            'longitude': commande['longitude']?.toString() ?? '',
            'paymentMethod': commande['paymentMethod'] ?? {},
            'packagePhoto': commande['packagePhoto'],
            'packagePhotoPublicId': commande['packagePhotoPublicId'],
            'paymentMethodId': commande['paymentMethodId'],
            'numeroPayment': commande['numeroPayment'],
            'codeColis': commande['codeColis'],
            'distanceKm': commande['distanceKm']?.toString() ?? '',
            'createdAt': commande['createdAt'],
            'updatedAt': commande['updatedAt'],
          };
        }).toList();
        
        return {
          'success': true,
          'orders': orders,
          'message': responseData['message'] ?? 'Commandes récupérées avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ [OrderService] Erreur (${response.statusCode})');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des commandes',
          'orders': [],
        };
      }
    } catch (e) {
      print('💥 [OrderService] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'orders': [],
      };
    }
  }

  /// Met à jour le statut d'une commande
  /// Endpoint: PATCH /ecommerce/commandes/:orderId/status
  /// Authentification: REQUISE
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? reason,
  }) async {
    print('🔄 [OrderService] updateOrderStatus - Début');
    print('   📦 OrderId: $orderId');
    print('   📊 Status: $status');
    print('   📝 Reason: ${reason ?? 'Non fourni'}');
    
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        print('❌ [OrderService] Token manquant');
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final body = <String, dynamic>{
        'status': status,
      };
      
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      print('📤 [OrderService] Requête PATCH: $baseUrl/ecommerce/commandes/$orderId/status');
      print('📤 [OrderService] Body envoyé: ${jsonEncode(body)}');

      final response = await http.patch(
        Uri.parse('$baseUrl/ecommerce/commandes/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      print('📥 [OrderService] Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ [OrderService] Statut mis à jour avec succès');
        return {
          'success': true,
          'order': responseData['order'] ?? {},
          'message': responseData['message'] ?? 'Statut mis à jour avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ [OrderService] Erreur - Status: ${response.statusCode}');
        print('❌ [OrderService] Message: ${errorData['message'] ?? 'Erreur inconnue'}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la mise à jour du statut',
        };
      }
    } catch (e) {
      print('💥 [OrderService] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Upload la photo du colis
  /// Endpoint: POST /ecommerce/upload/package-photo
  /// Authentification: REQUISE
  Future<Map<String, dynamic>> uploadPackagePhoto({
    required String orderId,
    required String imagePath,
  }) async {
    print('🔄 [OrderService] uploadPackagePhoto - Début');
    print('   📦 OrderId: $orderId');
    print('   📷 ImagePath: $imagePath');
    
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        print('❌ [OrderService] Token manquant');
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ecommerce/upload/package-photo'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      });

      request.fields['orderId'] = orderId;
      
      final file = await http.MultipartFile.fromPath(
        'packagePhoto',
        imagePath,
      );
      request.files.add(file);

      print('📤 [OrderService] Upload de la photo du colis...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: L\'upload a pris trop de temps');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('📥 [OrderService] Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ [OrderService] Photo uploadée avec succès');
        return {
          'success': true,
          'order': responseData['order'] ?? {},
          'photoUrl': responseData['photoUrl'] ?? responseData['order']?['packagePhoto'] ?? '',
          'message': responseData['message'] ?? 'Photo uploadée avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ [OrderService] Erreur - Status: ${response.statusCode}');
        print('❌ [OrderService] Message: ${errorData['message'] ?? 'Erreur inconnue'}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de l\'upload de la photo',
        };
      }
    } catch (e) {
      print('💥 [OrderService] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur lors de l\'upload: $e',
      };
    }
  }

  // ============================================================================
  // MÉTHODES DÉPRÉCIÉES (conservées pour compatibilité)
  // ============================================================================

  /// @deprecated Utilisez [initializeOrder] à la place
  /// Crée une nouvelle commande (ancienne méthode)
  /// Endpoint: POST /ecommerce/commandes/store
  /// Authentification: REQUISE
  @Deprecated('Utilisez initializeOrder à la place')
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> produits,
    required String ville,
    required String commune,
    required String quartier,
    required String avenue,
    required String numero,
    required String pays,
    required String codePostale,
  }) async {
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ecommerce/commandes/store'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'produits': produits,
          'ville': ville,
          'commune': commune,
          'quartier': quartier,
          'avenue': avenue,
          'numero': numero,
          'pays': pays,
          'codePostale': codePostale,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'orderId': responseData['orderId'],
          'status': responseData['status'],
          'message': responseData['message'] ?? 'Commande créée avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la création de la commande',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// @deprecated Utilisez [getBuyerOrders] à la place
  /// Récupère la liste des commandes de l'acheteur connecté (ancienne méthode)
  /// Endpoint: GET /ecommerce/commandes/acheteur
  /// Authentification: REQUISE
  @Deprecated('Utilisez getBuyerOrders à la place')
  Future<Map<String, dynamic>> getAcheteurOrders() async {
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
          'commandes': [],
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/ecommerce/commandes/acheteur'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'commandes': responseData['commandes'] ?? [],
          'message': responseData['message'] ?? 'Commandes récupérées avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des commandes',
          'commandes': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'commandes': [],
      };
    }
  }
}

