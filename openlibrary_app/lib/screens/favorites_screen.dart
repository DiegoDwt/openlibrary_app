// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import '../providers/favorites_provider.dart';
import 'book_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<FavoritesProvider>();
      if (!prov.loading && prov.favorites.isEmpty) {
        prov.loadFavorites();
      }
    });
  }

  Future<void> _confirmAndDelete(BuildContext context, Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover'),
        content: Text('Remover "${book.title}" dos favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (book.id != null) {
        final ok = await context.read<FavoritesProvider>().removeFavorite(book.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Removido dos favoritos' : 'Falha ao remover')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID não encontrado para remover')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch para reagir a mudanças no provider (loading, favorites)
    final prov = context.watch<FavoritesProvider>();
    final loading = prov.loading;
    final favorites = prov.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: [
          IconButton(
            onPressed: prov.loadFavorites,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (favorites.isEmpty
              ? const Center(child: Text('Nenhum favorito salvo'))
              : RefreshIndicator(
                  onRefresh: prov.loadFavorites,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: favorites.length,
                    itemBuilder: (context, i) {
                      final book = favorites[i];

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          BookCard(
                            key: ValueKey('fav-${book.id ?? book.title}'),
                            book: book,
                            isFavorite: true,
                            onFavoriteToggle: () => _confirmAndDelete(context, book),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookDetailsScreen(book: book),
                                ),
                              );
                            },
                          ),

                          // Botão X para remover
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _confirmAndDelete(context, book),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white70,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )),
    );
  }
}
