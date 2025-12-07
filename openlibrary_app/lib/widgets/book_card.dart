import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openlibrary_app/models/book.dart';
import 'package:openlibrary_app/providers/favorites_provider.dart';

/// Componente visual que mostra capa, título, autores e ações de um livro.
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  /// Callback disparada quando o usuário pressiona o botão de favoritar.
  /// Se não fornecida, o widget tenta usar o FavoritesProvider presente no contexto.
  final VoidCallback? onFavoriteToggle;

  /// Indica visualmente se o item já é favorito (altera o ícone).
  final bool isFavorite;

  const BookCard({
    Key? key,
    required this.book,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  }) : super(key: key);

  // Resolve a URL da capa: primeiro tenta coverUrl do modelo, depois tenta gerar
  // a URL a partir do primeiro ISBN (se existir).
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

  // Junta autores em uma única string separada por vírgula.
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
      onTap: onTap, // permite ação ao tocar no card (ex.: abrir detalhe)
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Área da capa (expandida para ocupar espaço disponível)
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

            // Corpo com título, autores e botões (link + favoritar)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título — truncado em 2 linhas
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Autores — somente se houver
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
                    Row(
                      children: [
                        const Spacer(),

                        // Ícone de link (apenas indicador visual)
                        if (hasLink) Icon(Icons.link, size: 16, color: Colors.grey[600]),

                        // Botão de favoritar:
                        IconButton(
                          key: const Key('fav_button'),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                          ),
                          tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                          onPressed: () async {
                            if (onFavoriteToggle != null) {
                              onFavoriteToggle!();
                              return;
                            }
                            try {
                              final provider = Provider.of<FavoritesProvider>(context, listen: false);
                              await provider.addFavorite(book);
                            } catch (e) {
                              // Se não houver provider no contexto ou ocorrer erro, não quebra a UI.
                              // Você pode logar ou mostrar um SnackBar aqui se desejar.
                            }
                          },
                        ),
                      ],
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder simples usado quando não há capa.
  Widget _placeholderCover() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.book, size: 48, color: Colors.grey),
      ),
    );
  }
}
