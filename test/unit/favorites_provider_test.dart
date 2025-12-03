import 'package:flutter_test/flutter_test.dart';
import 'package:openlibrary_app/providers/favorites_provider.dart';
import 'package:openlibrary_app/services/backend_service.dart';
import 'package:openlibrary_app/models/book.dart';

/// Fake simples do BackendService para testes.
class FakeBackendService implements BackendService {
  final List<Book> _store = [];
  int _nextId = 1;

  @override
  Future<List<Book>> listSaved() async {
    // retorna cópia para simular IO
    return List<Book>.from(_store);
  }

  @override
  Future<int?> saveBook(Book book) async {
    // Se sua Book não tem copyWith, criamos uma nova instância com o novo id.
    // Assumimos que Book tem named params id, title e authors — ajuste se necessário.
    final int assignedId = (book.id == 0 || book.id == null) ? _nextId : book.id!;
    final newBook = Book(
      id: assignedId,
      title: book.title,
      authors: book.authors,
      // se tiver outros campos públicos (ex: coverUrl), adicione aqui:
      // coverUrl: (book as dynamic).coverUrl ?? null,
    );

    // Se o book já tiver id > 0 e existir, removemos o anterior (evita duplicatas)
    _store.removeWhere((b) => b.id == newBook.id);
    _store.add(newBook);

    // retorna id se foi atribuído novo, ou o próprio id se já havia
    if (assignedId == _nextId) {
      _nextId++;
      return assignedId;
    }
    return assignedId;
  }

  @override
  Future<bool> deleteBook(int id) async {
    // removeWhere retorna void — então verificamos tamanho antes/depois
    final before = _store.length;
    _store.removeWhere((b) => b.id == id);
    final after = _store.length;
    return after < before;
  }
}

void main() {
  group('FavoritesProvider', () {
    late FakeBackendService backend;
    late FavoritesProvider provider;

    setUp(() {
      backend = FakeBackendService();
      provider = FavoritesProvider(backend: backend);
    });

    test('loadFavorites popula a lista e atualiza loading', () async {
      // antes de carregar
      expect(provider.loading, false);
      final future = provider.loadFavorites();
      // durante carregamento loading -> true
      expect(provider.loading, true);
      await future;
      expect(provider.loading, false);
      expect(provider.favorites, isA<List<Book>>());
    });

    test('addFavorite chama backend.saveBook e recarrega lista', () async {
      final book = Book(id: 0, title: 'Título de teste', authors: ['Autor A']);
      final ok = await provider.addFavorite(book);
      expect(ok, isTrue);
      expect(provider.favorites.length, 1);
      expect(provider.favorites.first.title, 'Título de teste');
    });

    test('removeFavorite chama backend.deleteBook e atualiza lista', () async {
      // primeiro salva direto no backend fake (retorna id)
      final book = Book(id: 0, title: 'Para remover', authors: ['X']);
      final id = await backend.saveBook(book);
      // recarrega
      await provider.loadFavorites();
      expect(provider.favorites.length, 1);
      final removed = await provider.removeFavorite(id!);
      expect(removed, isTrue);
      expect(provider.favorites.length, 0);
    });
  });
}
