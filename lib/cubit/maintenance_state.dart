part of 'maintenance_cubit.dart';

abstract class MaintenanceState extends Equatable {
  const MaintenanceState();

  @override
  List<Object?> get props => [];
}

class MaintenanceInitial extends MaintenanceState {}

class MaintenanceLoading extends MaintenanceState {}

class MaintenanceSuccess extends MaintenanceState {
  final String message;
  final String? maintenanceId;

  const MaintenanceSuccess(this.message, {this.maintenanceId});

  @override
  List<Object?> get props => [message, maintenanceId];
}

class MaintenanceError extends MaintenanceState {
  final String message;

  const MaintenanceError(this.message);

  @override
  List<Object> get props => [message];
}
