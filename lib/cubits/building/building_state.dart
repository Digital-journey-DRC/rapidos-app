import 'package:equatable/equatable.dart';
import '../../models/building.dart';

abstract class BuildingState extends Equatable {
  const BuildingState();

  @override
  List<Object?> get props => [];
}

class BuildingInitial extends BuildingState {}

class BuildingLoading extends BuildingState {}

class BuildingSuccess extends BuildingState {
  final Building building;

  const BuildingSuccess(this.building);

  @override
  List<Object?> get props => [building];
}

class BuildingsLoaded extends BuildingState {
  final List<Building> buildings;
  final int total;
  final int totalApartments;
  final int page;
  final int pages;

  const BuildingsLoaded({
    required this.buildings,
    required this.total,
    required this.totalApartments,
    required this.page,
    required this.pages,
  });

  @override
  List<Object?> get props => [buildings, total, totalApartments, page, pages];
}

class BuildingLoaded extends BuildingState {
  final Building building;

  const BuildingLoaded({required this.building});

  @override
  List<Object?> get props => [building];
}

class BuildingError extends BuildingState {
  final String message;

  const BuildingError(this.message);

  @override
  List<Object?> get props => [message];
}

class ApartmentCreated extends BuildingState {
  final String message;

  const ApartmentCreated(this.message);

  @override
  List<Object?> get props => [message];
}

class ImagesUploaded extends BuildingState {
  final String message;

  const ImagesUploaded(this.message);

  @override
  List<Object?> get props => [message];
}
