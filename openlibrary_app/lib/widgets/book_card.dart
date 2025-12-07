import 'package:flutter/material.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  /// Essa callback continua existindo, mas NÃO renderiza mais um botão aqui.
  final VoidCallback? onFavoriteToggle;

  final bool isFavorite;

  const BookCard({
    Key? key,
    required this.book,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  }) : super(key: key);

  String? _resolveCoverUrl() {
    final cover = (book.coverUrl).trim();
    if (cover.isNotEmpty) return cover;

    if (book.isbns != null && book.isbns!.isNotEmpty) {
      final first = book.isbns!.first.trim();
      if (first.isNotEmpty) {
        return 'https://covers.openlibrary.org/b/isbn/${Uri.encodeComponent(first)}-M.jpg';
      }
    }
    return null;
  }

  String _authorsToString() {
    if (book.authors.isEmpty) return '';
    return book.authors.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final cover = _resolveCoverUrl();
    final authors = _authorsToString();
    final hasLink =
        (book.openLibraryUrl != null && book.openLibraryUrl!.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: cover != null
                    ? Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderCover(),
                      )
                    : _placeholderCover(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    if (authors.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          authors,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Agora só mostra o link!
                    Row(
                      children: [
                        const Spacer(),
                        if (hasLink)
                          Icon(Icons.link,
                              size: 16, color: Colors.grey[600]),
                      ],
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.book, size: 48, color: Colors.grey),
      ),
    );
  }
}
