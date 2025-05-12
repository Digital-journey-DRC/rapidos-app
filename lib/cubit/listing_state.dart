import 'package:equatable/equatable.dart';

abstract class ListingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ListingInitial extends ListingState {}

class ListingLoading extends ListingState {}

class ListingSuccess extends ListingState {
  final Map<String, dynamic> data;

  ListingSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class ListingError extends ListingState {
  final String message;

  ListingError(this.message);

  @override
  List<Object?> get props => [message];
}