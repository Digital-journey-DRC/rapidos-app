import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

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

  Future<void> fetchMerchants() async {
    emit(MerchantLoading());
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://24.144.87.127:3333/vendeurs',
        options: Options(
          headers: {
            'Authorization': 'Bearer oat_NDc.eFhWeFR1LXVoMHUwT0FUZF9Ed1ljQnJ4c25COXhCOXVpbGFGc3FqYjIzNDk3NTM5NzU'
          }
        ),
      );
      final data = response.data['vendeurWITHProduct'] as List;
      emit(MerchantLoaded(data.cast<Map<String, dynamic>>()));
    } catch (e) {
      emit(MerchantError('Erreur lors du chargement des marchands'));
    }
  }
} 