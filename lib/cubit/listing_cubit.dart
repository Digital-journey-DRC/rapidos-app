import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/listing_service.dart';
import 'listing_state.dart';

class ListingCubit extends Cubit<ListingState> {
  final ListingService _listingService;

  ListingCubit(this._listingService) : super(ListingInitial());

  Future<void> getListings({int page = 1, int limit = 10}) async {
    try {
      emit(ListingLoading());
      
      final response = await _listingService.getListings(
        page: page,
        limit: limit,
        token: '',
      );

      if (response['success'] == true) {
        emit(ListingSuccess(response));
      } else {
        emit(ListingError(response['message'] ?? 'Une erreur est survenue'));
      }
    } catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> createListing({
    required String apartmentId,
    required String title,
    required String description,
    required double price,
    required DateTime availableFrom,
    required int minimumStay,
    required String token,
  }) async {
    try {
      emit(ListingLoading());

      final response = await _listingService.createListing(
        apartmentId: apartmentId,
        title: title,
        description: description,
        price: price,
        availableFrom: availableFrom,
        minimumStay: minimumStay,
        token: token,
      );

      if (response['success'] == true) {
        emit(ListingSuccess(response));
      } else {
        emit(ListingError(response['message'] ?? 'Une erreur est survenue'));
      }
    } catch (e) {
      emit(ListingError(e.toString()));
    }
  }

  Future<void> getUserListings({
    required String token,
    required String userId,
    required int page,
    required int limit,
  }) async {
    try {
      if (page == 1) {
        emit(ListingLoading());
      }

      final response = await _listingService.getUserListings(
        token: token,
        userId: userId,
        page: page,
        limit: limit,
      );

      if (response['success'] == true) {
        emit(ListingSuccess(response));
      } else {
        emit(ListingError(response['message'] ?? 'Une erreur est survenue'));
      }
    } catch (e) {
      emit(ListingError(e.toString()));
    }
  }
}