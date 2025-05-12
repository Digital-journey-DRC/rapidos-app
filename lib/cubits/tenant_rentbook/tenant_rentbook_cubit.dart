import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/rentbook_service.dart';
import 'tenant_rentbook_state.dart';

class TenantRentbookCubit extends Cubit<TenantRentbookState> {
  final RentbookService _rentbookService = RentbookService();

  TenantRentbookCubit() : super(TenantRentbookInitial());

  Future<void> getTenantRentbooks({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      emit(TenantRentbookLoading());

      final result = await _rentbookService.getTenantRentbooks(
        token: token,
        page: page,
        limit: limit,
      );

      emit(TenantRentbookLoaded(
        rentbooks: result['data'],
        total: result['total'],
        currentPage: result['currentPage'],
        totalPages: result['totalPages'],
      ));
    } catch (e) {
      emit(TenantRentbookError(e.toString()));
    }
  }
}
