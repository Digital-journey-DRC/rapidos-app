import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:immo/cubit/auth_cubit.dart';

abstract class MerchantState {}

class MerchantLoading extends MerchantState {}

class MerchantLoaded extends MerchantState {
  final List<Map<String, dynamic>> merchants;
  MerchantLoaded(this.merchants);
}

class MerchantError extends MerchantState {
  final String message;
  MerchantError(this.message);
}

class MerchantCubit extends Cubit<MerchantState> {
  MerchantCubit() : super(MerchantLoading());

  Future<void> fetchMerchants(BuildContext context) async {
    emit(MerchantLoading());
    try {
      // Récupérer le token depuis AuthCubit au lieu de SharedPreferences
      final authCubit = context.read<AuthCubit>();
      final authState = authCubit.state;
      
      print('🏪 MerchantCubit: État AuthCubit: ${authState.runtimeType}');

      if (authState is! AuthSuccess || authState.token == null) {
        print('❌ MerchantCubit: Token manquant ou utilisateur non connecté');
        print('❌ MerchantCubit: authState: $authState');
        emit(MerchantError('Token d\'authentification manquant. Veuillez vous reconnecter.'));
        return;
      }

      final token = authState.token;
      print('✅ MerchantCubit: Token récupéré depuis AuthCubit');
      
      print('🔄 MerchantCubit: Chargement des marchands...');
      final dio = Dio();
      final response = await dio.get(
        'http://24.144.87.127:3333/vendeurs',
        options: Options(headers: {
          'Authorization': 'Bearer $token'
        }),
      );
      
      print('📡 MerchantCubit: Réponse API - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data['vendeurWITHProduct'] as List?;
        if (data != null) {
          print('✅ MerchantCubit: ${data.length} marchands chargés');
          emit(MerchantLoaded(data.cast<Map<String, dynamic>>()));
        } else {
          print('❌ MerchantCubit: Aucun marchand dans la réponse');
          emit(MerchantError('Aucun marchand trouvé'));
        }
      } else {
        print('❌ MerchantCubit: Erreur API - ${response.statusCode}');
        emit(MerchantError('Erreur lors du chargement des marchands: ${response.statusCode}'));
      }
    } catch (e) {
      print('❌ MerchantCubit: Erreur: $e');
      emit(MerchantError('Erreur lors du chargement des marchands: $e'));
    }
  }
}
