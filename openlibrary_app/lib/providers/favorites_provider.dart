import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/backend_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final BackendService backend;
  List<Book> favorites = [];
  bool loading = false;

  FavoritesProvider({required this.backend});

  Future<void> loadFavorites() async {
    loading = true;
    notifyListeners();
    try {
      favorites = await backend.listSaved();
    } catch (e) {
      favorites = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> addFavorite(Book book) async {
    try {
      final id = await backend.saveBook(book);
      if (id != null) {
        // recarrega a lista
        await loadFavorites();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFavorite(int id) async {
    try {
      final ok = await backend.deleteBook(id);
      if (ok) {
        await loadFavorites();
      }
      return ok;
    } catch (e) {
      return false;
    }
  }
}
