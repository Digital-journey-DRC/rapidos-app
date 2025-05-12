import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'listing_state.dart';

class ListingCubit extends Cubit<ListingState> {
  ListingCubit() : super(ListingInitial());

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

      final response = await http.get(
        Uri.parse('http://68.183.30.146:8000/api/v1/listings/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final listings = data['data'] as List;
        final totalPages = (data['count'] / limit).ceil();

        if (page == 1) {
          emit(ListingsLoaded(listings: listings, totalPages: totalPages));
        } else {
          if (state is ListingsLoaded) {
            final currentState = state as ListingsLoaded;
            emit(ListingsLoaded(
              listings: [...currentState.listings, ...listings],
              totalPages: totalPages,
            ));
          }
        }
      } else {
        emit(ListingError('Failed to load listings'));
      }
    } catch (e) {
      emit(ListingError(e.toString()));
    }
  }
}
