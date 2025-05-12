part of 'apartment_cubit.dart';

@immutable
abstract class ApartmentState {}

class ApartmentInitial extends ApartmentState {}

class ApartmentLoading extends ApartmentState {}

class ApartmentSuccess extends ApartmentState {
  final String message;

  ApartmentSuccess(this.message);
}

class ApartmentError extends ApartmentState {
  final String error;

  ApartmentError(this.error);
}

class ApartmentsLoaded extends ApartmentState {
  final List<Map<String, dynamic>> apartments;

  ApartmentsLoaded(this.apartments);
}

class ImagesUploaded extends ApartmentState {
  final String message;

  ImagesUploaded(this.message);
}
