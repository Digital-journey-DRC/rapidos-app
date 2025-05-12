import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/building.dart';
import '../../services/building_service.dart';
import 'building_state.dart';

class BuildingCubit extends Cubit<BuildingState> {
  final BuildingService _buildingService;
  String? _currentUserId;
  
  // Stream pour notifier qu'un téléchargement d'images a réussi
  static final _imageUploadSuccessController = StreamController<String>.broadcast();
  static Stream<String> get imageUploadSuccess => _imageUploadSuccessController.stream;

  BuildingCubit(this._buildingService) : super(BuildingInitial());

  String? get currentUserId => _currentUserId;

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  Future<void> createBuilding({
    required String name,
    required String street,
    required String city,
    required String postalCode,
    required String country,
    required String description,
    required List<String> features,
    required int totalApartments,
    required int availableApartments,
    required int constructionYear,
    required String token,
  }) async {
    try {
      emit(BuildingLoading());

      final building = Building(
        name: name,
        address: Address(
          street: street,
          city: city,
          postalCode: postalCode,
          country: country,
        ),
        description: description,
        features: features,
        totalApartments: totalApartments,
        availableApartments: availableApartments,
        status: 'en_construction',
        constructionYear: constructionYear,
      );

      // Créer le building
      await _buildingService.createBuilding(building, token);
      emit(BuildingSuccess(building));
    } catch (e) {
      emit(BuildingError(e.toString()));
    }
  }

  Future<void> loadUserBuildings(String userId, String token, {int page = 1, int limit = 10}) async {
    try {
      emit(BuildingLoading());
      _currentUserId = userId;
      
      // Get buildings list
      final buildingsResponse = await _buildingService.getUserBuildings(userId, token);
      final List<dynamic> buildingsJson = buildingsResponse['data']['buildings'] ?? [];
      final buildings = buildingsJson
          .map((json) => Building.fromJson(json))
          .toList();

      // Get totals from apartments endpoint
      final totalsResponse = await _buildingService.getUserBuildingsWithApartments(userId, token);
      final totalBuildings = totalsResponse['totalBuildings'] ?? 0;
      final totalApartments = totalsResponse['totalApartments'] ?? 0;

      emit(BuildingsLoaded(
        buildings: buildings,
        total: totalBuildings,
        totalApartments: totalApartments,
        page: page,
        pages: buildingsResponse['data']['pages'] ?? 1,
      ));
    } catch (e) {
      print('Error loading buildings: $e'); // Debug print
      emit(BuildingError(e.toString()));
    }
  }

  Future<void> createApartment({
    required String buildingId,
    required String number,
    required String type,
    required double price,
    required double surface,
    required String description,
    required List<String> features,
    required String status,
    required String token,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User ID not set. Please login again.');
      }

      emit(BuildingLoading());

      final apartmentData = {
        'buildingId': buildingId,
        'number': number,
        'type': type,
        'price': price,
        'surface': surface,
        'description': description,
        'features': features,
        'status': status,
      };

      final result = await _buildingService.createApartment(token, apartmentData);
      emit(ApartmentCreated('Appartement créé avec succès'));
      
      // Refresh building list after creating apartment
      await loadUserBuildings(_currentUserId!, token);
    } catch (e) {
      emit(BuildingError(e.toString()));
    }
  }

  Future<void> fetchBuilding(String buildingId, String token) async {
    try {
      emit(BuildingLoading());
      
      final result = await _buildingService.getBuilding(buildingId, token);
      final building = Building.fromJson(result['data']);
      
      emit(BuildingLoaded(building: building));
    } catch (e) {
      emit(BuildingError(e.toString()));
    }
  }

  Future<void> uploadBuildingImages({
    required String buildingId,
    required List<String> imagePaths,
    required String token,
    Function? onSuccess,
  }) async {
    emit(BuildingLoading());
    try {
      print('BuildingCubit: Début de l\'upload des images');
      
      final result = await _buildingService.uploadBuildingImages(
        buildingId: buildingId,
        imagePaths: imagePaths,
        token: token,
      );
      
      print('BuildingCubit: Résultat de l\'upload: $result');
      
      // Extraire le message de la réponse ou utiliser un message par défaut
      String message = 'Images téléchargées avec succès';
      if (result is Map<String, dynamic> && result.containsKey('message')) {
        message = result['message'];
      }
      
      emit(ImagesUploaded(message));
      
      // Notifier via le stream que le téléchargement a réussi
      _imageUploadSuccessController.add(buildingId);
      
      // Si un callback onSuccess est fourni, l'exécuter
      if (onSuccess != null) {
        onSuccess();
      } else {
        fetchBuilding(buildingId, token);
      }
    } catch (e) {
      print('BuildingCubit: Erreur lors de l\'upload: $e');
      emit(BuildingError(e.toString()));
    }
  }
}
