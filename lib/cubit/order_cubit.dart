import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immo/services/storage_service.dart';
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
  final List<dynamic> commandes;

  OrderListState({this.isLoading = false, this.error, this.commandes = const []});

  OrderListState copyWith({bool? isLoading, String? error, List<dynamic>? commandes}) {
    return OrderListState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      commandes: commandes ?? this.commandes,
    );
  }
}

class OrderCubit extends Cubit<OrderState> {
  OrderCubit() : super(OrderState());

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
      final token = await StorageService().getToken();
      final headers = {
        'Content-Type': 'application/json',
        // 'Content-type' :"application/x-www-form-urlencoded",
        'Authorization': 'Bearer $token',
      };

      final request = http.Request(
        'POST',
        Uri.parse('http://24.144.87.127:3333/commandes/store'),
      );

      request.body = json.encode({
        "produits": produits,
        "ville": ville,
        "commune": commune,
        "quartier": quartier,
        "avenue": avenue,
        "codePostale": "12345",
        "numero": numero == "Non spécifié" ? "Pas de détail adresse" : numero,
        "isPrincipal": true,
        "type": "livraison",
        "pays": pays,
      });

      request.headers.addAll(headers);

      print('URL: ${request.url}');
      print('HEADERS: ${request.headers}');
      print('BODY: ${request.body}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(state.copyWith(isLoading: false, success: true));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Erreur lors de la création de la commande: ${response.reasonPhrase}',
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
        "codePostale": "12345",
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

  Future<void> fetchOrders() async {
    _orderListState = _orderListState.copyWith(isLoading: true, error: null);
    emit(state.copyWith());
    try {
      final token = await StorageService().getToken();
      final userDataStr = await StorageService().getUserData();
      String role = 'vendeur';
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr);
        if (userData is Map && userData['role'] != null) {
          role = userData['role'];
        }
      }
      final headers = {
        'Authorization': 'Bearer $token',
      };
      final endpoint = role == 'acheteur'
          ? 'http://24.144.87.127:3333/commandes/acheteur'
          :
          role == 'livreur'
          ? 'http://24.144.87.127:3333/livraison/ma-liste'
          : 'http://24.144.87.127:3333/commandes/vendeur';
      print('ROLE: $role, ENDPOINT: $endpoint');
      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DATA: $data');
        print(token);
        _orderListState = _orderListState.copyWith(isLoading: false, commandes: role == 'livreur' ? data['livraison'] : data['commandes'], error: null);
      } else {
        _orderListState = _orderListState.copyWith(isLoading: false, error: response.reasonPhrase);
      }
      emit(state.copyWith());
    } catch (e) {
      _orderListState = _orderListState.copyWith(isLoading: false, error: e.toString());
      emit(state.copyWith());
    }
  }
} 