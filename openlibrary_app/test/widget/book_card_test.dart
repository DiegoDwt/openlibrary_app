import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:openlibrary_app/widgets/book_card.dart';
import 'package:openlibrary_app/models/book.dart';
import 'package:openlibrary_app/providers/favorites_provider.dart';
import 'package:openlibrary_app/services/backend_service.dart';

class FakeBackendService implements BackendService {
  final List<Book> _store = [];
  int _nextId = 1;

  @override
  Future<List<Book>> listSaved() async => List<Book>.from(_store);

  @override
  Future<int?> saveBook(Book book) async {
    _store.add(book);
    return _nextId++;
  }

  @override
  Future<bool> deleteBook(int id) async {
    final before = _store.length;
    _store.removeWhere((b) => b.id == id);
    return _store.length < before;
  }
}

void main() {
  testWidgets('BookCard mostra titulo e botão de favoritar funciona', (WidgetTester tester) async {
    final backend = FakeBackendService();
    final provider = FavoritesProvider(backend: backend);
    final book = Book(id: 0, title: 'Título Teste', authors: ['Autor']);

    await tester.pumpWidget(
      ChangeNotifierProvider<FavoritesProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: BookCard(book: book),
          ),
        ),
      ),
    );

    // verifica se o título aparece
    expect(find.text('Título Teste'), findsOneWidget);

    // supondo que o BookCard possui um IconButton com Key('fav_button')
    final favButton = find.byKey(Key('fav_button'));
    expect(favButton, findsOneWidget);

    await tester.tap(favButton);
    await tester.pumpAndSettle();

    // depois de favoritar a lista de favorites deve conter 1 item
    expect(provider.favorites.length, 1);
    expect(provider.favorites.first.title, 'Título Teste');
  });
}
