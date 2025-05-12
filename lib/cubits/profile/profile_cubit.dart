import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/profile_service.dart';

// States
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  final String message;
  final Map<String, dynamic>? data;
  
  ProfileSuccess(this.message, {this.data});
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class BalanceLoaded extends ProfileState {
  final Map<String, dynamic> balanceData;
  BalanceLoaded(this.balanceData);
}

class IncomeSummaryLoaded extends ProfileState {
  final Map<String, dynamic> incomeSummaryData;
  IncomeSummaryLoaded(this.incomeSummaryData);
}

// Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService _profileService;

  ProfileCubit(this._profileService) : super(ProfileInitial());

  Future<void> updateProfile({
    required String userId,
    required String token,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      emit(ProfileLoading());
      final response = await _profileService.updateProfile(
        userId: userId,
        token: token,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );
      
      // Vérifier si l'API a retourné des données utilisateur
      if (response['success'] == true && response['data'] != null) {
        // Inclure les données mises à jour dans l'état
        emit(ProfileSuccess(
          'Profil mis à jour avec succès',
          data: response['data']
        ));
      } else {
        // Si pas de données retournées, émettre l'état avec juste le message
        emit(ProfileSuccess('Profil mis à jour avec succès'));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> uploadProfileImage({
    required String token,
    required File imageFile,
  }) async {
    try {
      emit(ProfileLoading());
      final response = await _profileService.uploadProfileImage(
        token: token,
        imageFile: imageFile,
      );
      
      // Check if data contains updated user info
      if (response['success'] == true && response['data'] != null) {
        // Pass the complete response data to the ProfileSuccess state
        emit(ProfileSuccess(
          'Photo de profil mise à jour avec succès',
          data: response['data']
        ));
      } else {
        emit(ProfileSuccess('Photo de profil mise à jour avec succès'));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> getUserBalance({
    required String userId,
    required String token,
  }) async {
    try {
      emit(ProfileLoading());
      final response = await _profileService.getUserBalance(
        userId: userId,
        token: token,
      );
      
      emit(BalanceLoaded(response));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> getIncomeSummary({
    required String token,
  }) async {
    try {
      emit(ProfileLoading());
      final response = await _profileService.getIncomeSummary(
        token: token,
      );
      
      emit(IncomeSummaryLoaded(response));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
