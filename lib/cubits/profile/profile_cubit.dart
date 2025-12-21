import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/profile_service.dart';
import '../../cubit/auth_cubit.dart';

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
  AuthCubit? _authCubit;

  ProfileCubit(this._profileService) : super(ProfileInitial());

  // Méthode pour injecter l'AuthCubit
  void setAuthCubit(AuthCubit authCubit) {
    _authCubit = authCubit;
  }

  Future<void> updateProfile({
    required String userId,
    required String token,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      print('🔄 ProfileCubit: Début de updateProfile');
      print('🔄 ProfileCubit: userId=$userId, firstName=$firstName, lastName=$lastName, email=$email, phone=$phone');
      
      emit(ProfileLoading());
      
      print('🔄 ProfileCubit: Appel du service...');
      final response = await _profileService.updateProfile(
        userId: userId,
        token: token,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );
      
      print('✅ ProfileCubit: Réponse reçue: $response');
      
      // Mettre à jour l'AuthCubit avec les nouvelles données utilisateur
      if (_authCubit != null) {
        try {
          // Récupérer l'état actuel de l'AuthCubit
          final currentAuthState = _authCubit!.state;
          if (currentAuthState is AuthSuccess && currentAuthState.user != null) {
            // Créer une copie des données utilisateur mises à jour
            final updatedUserData = Map<String, dynamic>.from(currentAuthState.user!);
            
            // Mettre à jour avec les nouvelles données du profil
            if (firstName != null) updatedUserData['firstName'] = firstName;
            if (lastName != null) updatedUserData['lastName'] = lastName;
            if (email != null) updatedUserData['email'] = email;
            if (phone != null) updatedUserData['phone'] = phone;
            
            // Si l'API a retourné des données utilisateur, les utiliser
            if (response['data'] != null) {
              updatedUserData.addAll(response['data']);
            }
            
            print('🔄 ProfileCubit: Mise à jour de l\'AuthCubit avec les nouvelles données');
            print('📝 Données utilisateur mises à jour: $updatedUserData');
            
            // Mettre à jour l'AuthCubit
            _authCubit!.updateUser(updatedUserData, currentAuthState.token!);
            
            // Forcer la mise à jour de l'interface utilisateur
            print('✅ Données utilisateur mises à jour et persistées');
          }
        } catch (e) {
          print('❌ ProfileCubit: Erreur lors de la mise à jour de l\'AuthCubit: $e');
        }
      }
      
      // Vérifier si l'API a retourné des données utilisateur
      if (response['success'] == true && response['data'] != null) {
        // Inclure les données mises à jour dans l'état
        print('✅ ProfileCubit: Émission ProfileSuccess avec données');
        emit(ProfileSuccess(
          'Profil mis à jour avec succès',
          data: response['data']
        ));
      } else {
        // Si pas de données retournées, émettre l'état avec juste le message
        print('✅ ProfileCubit: Émission ProfileSuccess sans données');
        emit(ProfileSuccess('Profil mis à jour avec succès'));
      }
    } catch (e) {
      print('❌ ProfileCubit: Erreur: $e');
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> uploadProfileImage({
    required String token,
    required File imageFile,
  }) async {
    // print('📤 [PROFILE PHOTO] ProfileCubit.uploadProfileImage() appelée');
    // print('📤 [PROFILE PHOTO] Token: ${token.substring(0, 20)}...');
    // print('📤 [PROFILE PHOTO] Chemin fichier: ${imageFile.path}');
    // print('📤 [PROFILE PHOTO] Fichier existe: ${await imageFile.exists()}');
    
    try {
      // print('📤 [PROFILE PHOTO] Émission de ProfileLoading()...');
      emit(ProfileLoading());
      
      // print('📤 [PROFILE PHOTO] Appel de _profileService.uploadProfileImage()...');
      final response = await _profileService.uploadProfileImage(
        token: token,
        imageFile: imageFile,
      );
      
      // print('📤 [PROFILE PHOTO] Réponse reçue: $response');
      // print('📤 [PROFILE PHOTO] response[\'success\']: ${response['success']}');
      // print('📤 [PROFILE PHOTO] response[\'data\']: ${response['data']}');
      
      // Check if data contains updated user info
      if (response['success'] == true && response['data'] != null) {
        // print('✅ [PROFILE PHOTO] Données disponibles, émission ProfileSuccess avec data');
        // Pass the complete response data to the ProfileSuccess state
        emit(ProfileSuccess(
          'Photo de profil mise à jour avec succès',
          data: response['data']
        ));
        // print('✅ [PROFILE PHOTO] ProfileSuccess émis avec data: ${response['data']}');
      } else {
        // print('⚠️ [PROFILE PHOTO] Pas de données dans la réponse, émission ProfileSuccess sans data');
        emit(ProfileSuccess('Photo de profil mise à jour avec succès'));
        // print('✅ [PROFILE PHOTO] ProfileSuccess émis sans data');
      }
    } catch (e, stackTrace) {
      // print('❌ [PROFILE PHOTO] Erreur dans uploadProfileImage: $e');
      // print('❌ [PROFILE PHOTO] Stack trace: $stackTrace');
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
