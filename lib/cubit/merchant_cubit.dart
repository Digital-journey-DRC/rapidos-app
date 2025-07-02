import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:immo/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      print(token);

      // if (token == null) {
      //   Navigator.of(context).pushAndRemoveUntil(
      //     MaterialPageRoute(builder: (context) => const LoginScreen()),
      //     (route) => false,
      //   );
      //   return;
      // }
      final dio = Dio();
      final response = await dio.get(
        'http://24.144.87.127:3333/vendeurs',
        options: Options(headers: {
          'Authorization':
              'Bearer $token'
        }),
      );
      final data = response.data['vendeurWITHProduct'] as List;
      emit(MerchantLoaded(data.cast<Map<String, dynamic>>()));
    } catch (e) {
      emit(MerchantError('Erreur lors du chargement des marchands '));
    }
  }
}
