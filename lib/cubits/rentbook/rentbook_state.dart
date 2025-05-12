abstract class RentbookState {}

class RentbookInitial extends RentbookState {}

class RentbookLoading extends RentbookState {}

class RentbookCreated extends RentbookState {
  final Map<String, dynamic> rentbook;

  RentbookCreated(this.rentbook);
}

class RentbookError extends RentbookState {
  final String message;

  RentbookError(this.message);
}

class RentbooksLoaded extends RentbookState {
  final List<dynamic> rentbooks;
  final int total;
  final int currentPage;
  final int totalPages;

  RentbooksLoaded({
    required this.rentbooks,
    required this.total,
    required this.currentPage,
    required this.totalPages,
  });
}
