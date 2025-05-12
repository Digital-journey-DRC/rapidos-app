abstract class UtilityBillState {}

class UtilityBillInitial extends UtilityBillState {}

class UtilityBillLoading extends UtilityBillState {}

class UtilityBillCreated extends UtilityBillState {
  final String message;
  final Map<String, dynamic> bill;

  UtilityBillCreated({required this.message, required this.bill});
}

class UtilityBillsLoaded extends UtilityBillState {
  final List<dynamic> bills;

  UtilityBillsLoaded({required this.bills});
}

class UtilityBillError extends UtilityBillState {
  final String message;

  UtilityBillError({required this.message});
}
