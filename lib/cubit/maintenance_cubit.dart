import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/maintenance_service.dart';
import '../services/storage_service.dart';

part 'maintenance_state.dart';

class MaintenanceCubit extends Cubit<MaintenanceState> {
  final MaintenanceService _maintenanceService;
  final StorageService _storageService = StorageService();

  MaintenanceCubit(this._maintenanceService) : super(MaintenanceInitial());

  Future<void> createMaintenance({
    required String title,
    required String description,
    required String apartmentId,
  }) async {
    try {
      emit(MaintenanceLoading());

      final token = await _storageService.getToken();

      if (token == null) {
        emit(const MaintenanceError('Non authentifié'));
        return;
      }

      final maintenanceData = {
        "apartmentId": apartmentId,
        "title": title,
        "description": description,
        "date": DateTime.now().toIso8601String().split('T')[0],
        "cost": {
          "amount": 0,
          "currency": "USD"
        },
        "status": "planifié",
        "notes": "Intervention urgente requise"
      };

      print('Sending maintenance data: $maintenanceData'); // Debug log
      final response = await _maintenanceService.createMaintenance(maintenanceData, token);
      print('Received response: $response'); // Debug log

      if (response['success'] == true && response['data'] != null) {
        final maintenanceId = response['data']['_id'];
        print('Emitting success with maintenanceId: $maintenanceId'); // Debug log
        if (maintenanceId != null) {
          emit(MaintenanceSuccess('Maintenance créée avec succès', maintenanceId: maintenanceId));
        } else {
          emit(const MaintenanceError('ID de maintenance manquant dans la réponse'));
        }
      } else {
        emit(MaintenanceError(response['message'] ?? 'Erreur lors de la création de la maintenance'));
      }
    } catch (e) {
      print('Error in createMaintenance: $e'); // Debug log
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> uploadMaintenanceImages({
    required String maintenanceId,
    required List<File> images,
  }) async {
    try {
      emit(MaintenanceLoading());

      final token = await _storageService.getToken();

      if (token == null) {
        emit(const MaintenanceError('Non authentifié'));
        return;
      }

      final response = await _maintenanceService.uploadMaintenanceImages(
        maintenanceId: maintenanceId,
        images: images,
        token: token,
      );

      if (response['success'] == true) {
        emit(MaintenanceSuccess('Images ajoutées avec succès'));
      } else {
        emit(MaintenanceError(response['message'] ?? 'Erreur lors de l\'ajout des images'));
      }
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }
}
