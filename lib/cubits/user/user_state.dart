abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserSearchSuccess extends UserState {
  final List<Map<String, dynamic>> users;
  final int total;
  final int currentPage;
  final int totalPages;

  UserSearchSuccess({
    required this.users,
    required this.total,
    required this.currentPage,
    required this.totalPages,
  });
}

class UserError extends UserState {
  final String message;

  UserError(this.message);
}
