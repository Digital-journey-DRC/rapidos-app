import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/user_service.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserService _userService = UserService();

  UserCubit() : super(UserInitial());

  Future<void> searchUsers({
    required String query,
    required String token,
    String role = 'locataire',
    int limit = 10,
    int page = 1,
  }) async {
    try {
      emit(UserLoading());

      final result = await _userService.searchUsers(
        query: query,
        token: token,
        role: role,
        limit: limit,
        page: page,
      );

      if (result['success'] == true) {
        final List<Map<String, dynamic>> users = 
            (result['data'] as List).map((user) => user as Map<String, dynamic>).toList();

        emit(UserSearchSuccess(
          users: users,
          total: result['total'] ?? 0,
          currentPage: result['currentPage'] ?? 1,
          totalPages: result['totalPages'] ?? 1,
        ));
      } else {
        emit(UserError(result['message'] ?? 'Erreur lors de la recherche des utilisateurs'));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
