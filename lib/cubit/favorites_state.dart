part of 'favorites_cubit.dart';

abstract class FavoritesState {
  const FavoritesState();
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

class FavoritesLoaded extends FavoritesState {
  final List<Map<String, dynamic>> favorites;
  const FavoritesLoaded(this.favorites);
}

class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);
} 