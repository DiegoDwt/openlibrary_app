import 'package:flutter_test/flutter_test.dart';
import 'package:openlibrary_app/models/book.dart';

void main() {
  test('Book toJson/fromJson roundtrip', () {
    final book = Book(id: 1, title: 'O teste', authors: ['A', 'B']);
    final map = book.toJson();
    final book2 = Book.fromJson(map);
    expect(book2.id, book.id);
    expect(book2.title, book.title);
    expect(book2.authors, book.authors);
  });
}
