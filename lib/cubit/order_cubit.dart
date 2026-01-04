import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:immo/services/storage_service.dart';
import 'package:immo/services/order_service.dart';
import 'package:dio/dio.dart';

class OrderState {
  final bool isLoading;
  final String? error;
  final bool success;

  OrderState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  OrderState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }
}

class OrderListState {
  final bool isLoading;
  final String? error;
  final List<dynamic> orders; // Renommé de commandes à orders pour la nouvelle API
  final Map<String, dynamic> stats; // Statistiques par statut

  OrderListState({
    this.isLoading = false,
    this.error,
    this.orders = const [],
    this.stats = const {},
  });

  OrderListState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? orders,
    Map<String, dynamic>? stats,
  }) {
    return OrderListState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      orders: orders ?? this.orders,
      stats: stats ?? this.stats,
    );
  }

  // Propriété de compatibilité pour l'ancien code
  List<dynamic> get commandes => orders;
}

class OrderCubit extends Cubit<OrderState> {
  final OrderService _orderService = OrderService();
  
  OrderCubit() : super(OrderState());

  /// Initialise une commande multi-vendeurs avec calcul GPS des frais de livraison
  /// Crée automatiquement des sous-commandes séparées par vendeur
  Future<void> initializeOrder({
    required List<Map<String, dynamic>> products,
    required double latitude,
    required double longitude,
    required Map<String, dynamic> address,
  }) async {
    print('🎯 [OrderCubit] initializeOrder - Début');
    print('   Products: ${products.length}');
    print('   Latitude: $latitude, Longitude: $longitude');
    print('   Address: $address');
    
    emit(state.copyWith(isLoading: true, error: null, success: false));

    try {
      print('📞 [OrderCubit] Appel du service...');
      final result = await _orderService.initializeOrder(
        products: products,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      print('📥 [OrderCubit] Résultat reçu');
      print('   Success: ${result['success']}');
      print('   Message: ${result['message']}');
      print('   Orders: ${result['orders']?.length ?? 0}');
      print('   Summary: ${result['summary']}');

      if (result['success'] == true) {
        print('✅ [OrderCubit] Succès - Émission de l\'état success');
        emit(state.copyWith(isLoading: false, success: true));
      } else {
        print('❌ [OrderCubit] Échec - Erreur: ${result['message']}');
        emit(state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Erreur lors de l\'initialisation de la commande',
        ));
      }
    } catch (e, stackTrace) {
      print('💥 [OrderCubit] Exception capturée');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'initialisation de la commande: $e',
      ));
    }
  }

  /// @deprecated Utilisez initializeOrder à la place
  /// Crée une nouvelle commande (ancienne méthode)
  @Deprecated('Utilisez initializeOrder à la place')
  Future<void> createOrder({
    required List<Map<String, dynamic>> produits,
    required String ville,
    required String commune,
    required String quartier,
    required String avenue,
    required String codePostale,
    required String numero,
    required String pays,
  }) async {
    emit(state.copyWith(isLoading: true, error: null, success: false));

    try {
      final result = await _orderService.createOrder(
        produits: produits,
        ville: ville,
        commune: commune,
        quartier: quartier,
        avenue: avenue,
        numero: numero.isEmpty ? 'Non spécifié' : numero,
        pays: pays,
        codePostale: codePostale.isEmpty ? '' : codePostale,
      );

      if (result['success'] == true) {
        emit(state.copyWith(isLoading: false, success: true));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Erreur lors de la création de la commande',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création de la commande: $e',
      ));
    }
  }

  Future<void> createOrderDio({
    required List<Map<String, dynamic>> produits,
    required String ville,
    required String commune,
    required String quartier,
    required String avenue,
    required String codePostale,
    required String numero,
    required String pays,
  }) async {
    emit(state.copyWith(isLoading: true, error: null, success: false));
    try {
      final token = await StorageService().getToken();
      final dio = Dio();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = {
        "produits": produits,
        "ville": ville,
        "commune": commune,
        "quartier": quartier,
        "avenue": avenue,
        "codePostale": "012",
        "numero": numero.isEmpty ? "Pas de détail adresse" : numero,
        "isPrincipal": true,
        "type": "livraison",
        "pays": pays,
      };
      print('DIO BODY: ' + body.toString());
      print('DIO HEADERS: ' + headers.toString());
      final response = await dio.post(
        'http://24.144.87.127:3333/commandes/store',
        data: json.encode(body),
        options: Options(headers: headers),
      );
      print('DIO STATUS: ${response.statusCode}');
      print('DIO RESPONSE: ${response.data}');
      if (response.statusCode == 200) {
        emit(state.copyWith(isLoading: false, success: true));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Erreur lors de la création de la commande (Dio): ${response.statusMessage}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création de la commande (Dio): $e',
      ));
    }
  }

  OrderListState _orderListState = OrderListState();
  OrderListState get orderListState => _orderListState;

  /// Récupère les commandes avec filtrage optionnel par statut
  Future<void> fetchOrders({String? status}) async {
    print('🔄 [OrderCubit] fetchOrders - Début');
    print('   Status filter: ${status ?? 'Aucun'}');
    
    _orderListState = _orderListState.copyWith(isLoading: true, error: null);
    emit(state.copyWith());
    try {
      final userDataStr = await StorageService().getUserData();
      String role = 'vendeur';
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr);
        if (userData is Map && userData['role'] != null) {
          role = userData['role'];
        }
      }

      print('👤 Role détecté: $role');

      // Pour les acheteurs, utiliser le nouvel endpoint ecommerce
      if (role == 'acheteur') {
        print('📞 [OrderCubit] Appel de getBuyerOrders...');
        final result = await _orderService.getBuyerOrders(status: status);
        
        print('📥 [OrderCubit] Résultat reçu');
        print('   Success: ${result['success']}');
        print('   Orders count: ${(result['orders'] ?? []).length}');
        print('   Stats: ${result['stats']}');
        
        if (result['success'] == true) {
          _orderListState = _orderListState.copyWith(
            isLoading: false,
            orders: result['orders'] ?? [],
            stats: result['stats'] ?? {},
            error: null,
          );
          print('✅ [OrderCubit] Commandes chargées avec succès');
        } else {
          print('❌ [OrderCubit] Erreur: ${result['message']}');
          _orderListState = _orderListState.copyWith(
            isLoading: false,
            error: result['message'] ?? 'Erreur lors de la récupération des commandes',
          );
        }
      } else if (role == 'livreur') {
        // Pour le livreur, utiliser le nouvel endpoint
        print('🚚 [OrderCubit] Appel de getLivreurOrders...');
        final result = await _orderService.getLivreurOrders();
        
        print('📥 [OrderCubit] Résultat reçu pour livreur');
        print('   Success: ${result['success']}');
        print('   Orders count: ${(result['orders'] ?? []).length}');
        
        if (result['success'] == true) {
          _orderListState = _orderListState.copyWith(
            isLoading: false,
            orders: result['orders'] ?? [],
            error: null,
          );
          print('✅ [OrderCubit] Commandes livreur chargées avec succès');
        } else {
          print('❌ [OrderCubit] Erreur: ${result['message']}');
          _orderListState = _orderListState.copyWith(
            isLoading: false,
            error: result['message'] ?? 'Erreur lors de la récupération des commandes',
          );
        }
      } else {
        // Pour vendeur, utiliser l'endpoint vendeur
        final result = await _orderService.getVendeurOrders();
        
        if (result['success'] == true) {
          _orderListState = _orderListState.copyWith(
            isLoading: false,
            orders: result['orders'] ?? [],
            error: null,
          );
        } else {
          _orderListState = _orderListState.copyWith(
            isLoading: false,
            error: result['message'] ?? 'Erreur lors de la récupération des commandes',
          );
        }
      }
      emit(state.copyWith());
    } catch (e) {
      _orderListState = _orderListState.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      emit(state.copyWith());
    }
  }

  /// Met à jour le moyen de paiement pour une commande spécifique
  Future<void> updatePaymentMethod({
    required int orderId,
    required int paymentMethodId,
    String? numeroPayment,
  }) async {
    emit(state.copyWith(isLoading: true, error: null, success: false));

    try {
      final result = await _orderService.updatePaymentMethod(
        orderId: orderId,
        paymentMethodId: paymentMethodId,
        numeroPayment: numeroPayment,
      );

      if (result['success'] == true) {
        // Rafraîchir les commandes après la mise à jour
        await fetchOrders();
        emit(state.copyWith(isLoading: false, success: true));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Erreur lors de la mise à jour du moyen de paiement',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour du moyen de paiement: $e',
      ));
    }
  }

  /// Met à jour les moyens de paiement pour plusieurs commandes en batch
  Future<void> batchUpdatePaymentMethods({
    required List<Map<String, dynamic>> updates,
  }) async {
    emit(state.copyWith(isLoading: true, error: null, success: false));

    try {
      final result = await _orderService.batchUpdatePaymentMethods(
        updates: updates,
      );

      if (result['success'] == true) {
        // Rafraîchir les commandes après la mise à jour
        await fetchOrders();
        emit(state.copyWith(isLoading: false, success: true));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Erreur lors de la mise à jour des moyens de paiement',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour des moyens de paiement: $e',
      ));
    }
  }

  /// Récupère les commandes du livreur
  Future<void> fetchLivreurOrders() async {
    emit(state.copyWith(isLoading: true, error: null));
    _orderListState = _orderListState.copyWith(isLoading: true, error: null);
    emit(state.copyWith());

    try {
      final result = await _orderService.getLivreurOrders();

      if (result['success'] == true) {
        _orderListState = _orderListState.copyWith(
          isLoading: false,
          orders: result['orders'] ?? [],
          error: null,
        );
        emit(state.copyWith());
      } else {
        _orderListState = _orderListState.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Erreur lors de la récupération des commandes',
        );
        emit(state.copyWith());
      }
    } catch (e) {
      _orderListState = _orderListState.copyWith(
        isLoading: false,
        error: 'Erreur de connexion: $e',
      );
      emit(state.copyWith());
    }
  }

  /// Récupère les commandes du vendeur
  Future<void> fetchVendeurOrders() async {
    emit(state.copyWith(isLoading: true, error: null));
    _orderListState = _orderListState.copyWith(isLoading: true, error: null);
    emit(state.copyWith());

    try {
      final result = await _orderService.getVendeurOrders();

      if (result['success'] == true) {
        _orderListState = _orderListState.copyWith(
          isLoading: false,
          orders: result['orders'] ?? [],
          error: null,
        );
        emit(state.copyWith());
      } else {
        _orderListState = _orderListState.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Erreur lors de la récupération des commandes',
        );
        emit(state.copyWith());
      }
    } catch (e) {
      _orderListState = _orderListState.copyWith(
        isLoading: false,
        error: 'Erreur de connexion: $e',
      );
      emit(state.copyWith());
    }
  }

  /// Met à jour le statut d'une commande
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? reason,
  }) async {
    emit(state.copyWith(isLoading: true, error: null, success: false));

    try {
      final result = await _orderService.updateOrderStatus(
        orderId: orderId,
        status: status,
        reason: reason,
      );

      if (result['success'] == true) {
        // Rafraîchir les commandes après la mise à jour
        await fetchVendeurOrders();
        emit(state.copyWith(isLoading: false, success: true));
        return result;
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Erreur lors de la mise à jour du statut',
        ));
        return result;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour du statut: $e',
      ));
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Accepte une livraison
  Future<Map<String, dynamic>> acceptLivraison(String livraisonId) async {
    emit(state.copyWith(isLoading: true, error: null, success: false));

    try {
      final result = await _orderService.acceptLivraison(livraisonId);

      if (result['success'] == true) {
        // Rafraîchir les commandes après l'acceptation
        await fetchOrders();
        emit(state.copyWith(isLoading: false, success: true));
        return result;
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Erreur lors de l\'acceptation de la livraison',
        ));
        return result;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'acceptation de la livraison: $e',
      ));
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Upload la photo du colis
  Future<Map<String, dynamic>> uploadPackagePhoto({
    required String orderId,
    required String imagePath,
  }) async {
    emit(state.copyWith(isLoading: true, error: null, success: false));

    try {
      final result = await _orderService.uploadPackagePhoto(
        orderId: orderId,
        imagePath: imagePath,
      );

      if (result['success'] == true) {
        // Rafraîchir les commandes après l'upload
        await fetchVendeurOrders();
        emit(state.copyWith(isLoading: false, success: true));
        return result;
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Erreur lors de l\'upload de la photo',
        ));
        return result;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'upload: $e',
      ));
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }
} 