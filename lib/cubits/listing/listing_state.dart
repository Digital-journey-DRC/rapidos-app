import 'package:equatable/equatable.dart';

abstract class ListingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ListingInitial extends ListingState {}

class ListingLoading extends ListingState {}

class ListingError extends ListingState {
  final String message;

  ListingError(this.message);

  @override
  List<Object?> get props => [message];
}

class ListingsLoaded extends ListingState {
  final List<dynamic> listings;
  final int totalPages;

  ListingsLoaded({required this.listings, required this.totalPages});

  @override
  List<Object?> get props => [listings, totalPages];
}
