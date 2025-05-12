import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'dart:async';
import '../../services/apartment_service.dart';

part 'apartment_state.dart';

class ApartmentCubit extends Cubit<ApartmentState> {
  final ApartmentService _apartmentService;

  // Stream pour signaler que des images ont été téléchargées
  static final StreamController<String> _imageUploadStreamController = StreamController<String>.broadcast();
  static Stream<String> get imageUploadStream => _imageUploadStreamController.stream;

  ApartmentCubit(this._apartmentService) : super(ApartmentInitial());

  Future<void> getApartmentsByBuilding(String buildingId, String token) async {
    try {
      emit(ApartmentLoading());
      final apartments = await _apartmentService.getApartmentsByBuilding(buildingId, token);
      print('Apartments received: $apartments'); // Debug print
      emit(ApartmentsLoaded(apartments));
    } catch (e) {
      print('Error loading apartments: $e'); // Debug print
      emit(ApartmentError(e.toString()));
    }
  }

  Future<void> createApartment({
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
    required bool taxe,
    required Map<String, bool> features,
    required String status,
  }) async {
    try {
      emit(ApartmentLoading());

      await _apartmentService.createApartment(
        token: token,
        buildingId: buildingId,
        number: number,
        type: type,
        floor: floor,
        surface: surface,
        rooms: rooms,
        bathrooms: bathrooms,
        amount: amount,
        taxe: taxe,
        currency: currency,
        paymentFrequency: paymentFrequency,
        description: description,
        features: features,
        status: status,
      );

      emit(ApartmentSuccess('Appartement créé avec succès'));
    } catch (e) {
      emit(ApartmentError(e.toString()));
    }
  }

  Future<void> uploadApartmentImages({
    required String apartmentId,
    required List<String> imagePaths,
    required String token,
  }) async {
    try {
      emit(ApartmentLoading());
      print('ApartmentCubit: Début de l\'upload des images');
      
      final result = await _apartmentService.uploadApartmentImages(
        apartmentId: apartmentId,
        imagePaths: imagePaths,
        token: token,
      );
      
      print('ApartmentCubit: Résultat de l\'upload: $result');
      
      // Extraire le message de la réponse ou utiliser un message par défaut
      String message = 'Images téléchargées avec succès';
      if (result is Map<String, dynamic> && result.containsKey('message')) {
        message = result['message'];
      }
      
      // Notifier que des images ont été téléchargées pour cet appartement
      _imageUploadStreamController.add(apartmentId);
      
      emit(ImagesUploaded(message));
      
      // Rafraîchir les données de l'appartement
      print('ApartmentCubit: Rafraîchissement des données de l\'appartement');
      // On pourrait ajouter une méthode pour récupérer les détails d'un appartement ici
    } catch (e) {
      print('ApartmentCubit: Erreur lors de l\'upload: $e');
      emit(ApartmentError(e.toString()));
    }
  }
}
