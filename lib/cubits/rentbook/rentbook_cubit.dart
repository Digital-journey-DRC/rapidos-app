import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/rentbook_service.dart';
import 'rentbook_state.dart';

class RentbookCubit extends Cubit<RentbookState> {
  final RentbookService _rentbookService = RentbookService();

  RentbookCubit() : super(RentbookInitial());

  Future<void> createRentbook({
    required String apartmentId,
    required String tenantId,
    required DateTime leaseStartDate,
    required DateTime leaseEndDate,
    required double monthlyRent,
    required double securityDeposit,
    required String token,
  }) async {
    try {
      emit(RentbookLoading());

      final result = await _rentbookService.createRentbook(
        apartmentId: apartmentId,
        tenantId: tenantId,
        leaseStartDate: leaseStartDate,
        leaseEndDate: leaseEndDate,
        monthlyRent: monthlyRent,
        securityDeposit: securityDeposit,
        token: token,
      );

      emit(RentbookCreated(result));
    } catch (e) {
      emit(RentbookError(e.toString()));
    }
  }
  
  Future<void> getOwnerRentbooks({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      emit(RentbookLoading());

      final result = await _rentbookService.getOwnerRentbooks(
        token: token,
        page: page,
        limit: limit,
      );

      emit(RentbooksLoaded(
        rentbooks: result['data'],
        total: result['total'],
        currentPage: result['currentPage'],
        totalPages: result['totalPages'],
      ));
    } catch (e) {
      emit(RentbookError(e.toString()));
    }
  }
}
