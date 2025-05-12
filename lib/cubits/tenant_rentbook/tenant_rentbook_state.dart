abstract class TenantRentbookState {}

class TenantRentbookInitial extends TenantRentbookState {}

class TenantRentbookLoading extends TenantRentbookState {}

class TenantRentbookLoaded extends TenantRentbookState {
  final List<dynamic> rentbooks;
  final int total;
  final int currentPage;
  final int totalPages;

  TenantRentbookLoaded({
    required this.rentbooks,
    required this.total,
    required this.currentPage,
    required this.totalPages,
  });
}

class TenantRentbookError extends TenantRentbookState {
  final String message;

  TenantRentbookError(this.message);
}
