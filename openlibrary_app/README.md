# OpenLibrary App

Aplicativo Flutter para pesquisar livros na OpenLibrary, ver detalhes e gerenciar favoritos.
Organizado com Provider para estado e um backend simples para persistir favoritos.

## Estrutura (resumida)
- `lib/main.dart` — entrada
- `lib/models/book.dart` — modelo Book
- `lib/services/` — OpenLibrary / backend / api
- `lib/providers/` — FavoritesProvider
- `lib/screens/` — telas: splash, home, search, detail, favorites
- `lib/widgets/book_card.dart` — cartão de livro reutilizável

## Execução
```bash
flutter pub get
flutter run