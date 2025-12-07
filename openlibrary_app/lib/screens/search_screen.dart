// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import '../services/openlibrary_service.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import 'book_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final OpenLibraryService _service = OpenLibraryService();

  bool isLoading = false;
  List<Book> results = [];
  String? error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Converte valores variados em List<String> ou null
  List<String>? _toStringList(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (v is String) return v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return null;
  }

  // Tenta criar um Book a partir de um Map bruto (doc OpenLibrary ou objeto backend)
  Book? _mapFromRawMap(Map rawMap) {
    final Map<String, dynamic> m = Map<String, dynamic>.from(rawMap);

    // Normalizações úteis:
    // - edition_key ou edition_keys -> edition_key (Book.fromSearchDoc expects 'edition_key')
    // - author_name -> author_name
    // - cover_i -> cover_i
    // Não precisamos alterar as chaves do Map se Book.fromSearchDoc já entende as chaves do OpenLibrary.
    try {
      // Caso pareça um doc do /search.json da OpenLibrary
      if (m.containsKey('title') && (m.containsKey('author_name') || m.containsKey('edition_key') || m.containsKey('cover_i') || m.containsKey('has_fulltext'))) {
        try {
          return Book.fromSearchDoc(m);
        } catch (_) {
          // fallback para fromJson abaixo
        }
      }

      // Se parecer vindo do backend (list.php) ou já em formato amigável
      try {
        return Book.fromJson(m);
      } catch (_) {
        // fallback manual: tentar construir um Book mínimo
        final title = (m['title'] ?? '').toString();
        final authors = _toStringList(m['authors']) ?? _toStringList(m['author']) ?? <String>[];
        final coverId = (m['cover_id'] is int)
            ? (m['cover_id'] as int)
            : (m['cover_i'] is int ? (m['cover_i'] as int) : (m['coverId'] is int ? (m['coverId'] as int) : null));
        final editionKeys = _toStringList(m['edition_key'] ?? m['edition_keys'] ?? m['editionKeys']);
        final hasFulltext = m['has_fulltext'] == true || m['hasFullText'] == true || (m['fulltext'] == true);

        return Book(
          // Book constructor requires title and authors; other fields are optional
          title: title.isEmpty ? 'Sem título' : title,
          authors: authors,
          coverId: coverId,
          key: m['key'] as String?,
          firstPublishYear: m['first_publish_year'] is int ? (m['first_publish_year'] as int) : (m['first_publish_year'] != null ? int.tryParse(m['first_publish_year'].toString()) : null),
          isbns: _toStringList(m['isbn'] ?? m['isbns']),
          hasFulltext: hasFulltext,
          ebookCount: (m['ebook_count_i'] is int) ? (m['ebook_count_i'] as int) : 0,
          editionKeys: editionKeys,
          description: (m['description'] is String) ? m['description'] as String : (m['description'] is Map ? (m['description']['value']?.toString() ?? null) : null),
          sourceUrl: (m['source_url'] ?? m['sourceUrl'] ?? m['openlibrary_url'])?.toString(),
        );
      }
    } catch (e) {
      // qualquer erro ao criar o Book ignora o item
      debugPrint('Erro ao mapear item da busca para Book: $e');
      return null;
    }
  }

  Future<void> searchBooks() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      error = null;
      results = [];
    });

    try {
      // Chama o serviço; pode retornar List<Book>, List<Map>, Map (com 'docs') ou outro formato
      final dynamic raw = await _service.searchByTitle(query);

      final List<Book> mapped = [];

      if (raw is List<Book>) {
        mapped.addAll(raw);
      } else if (raw is List) {
        for (final item in raw) {
          if (item is Book) {
            mapped.add(item);
            continue;
          }
          if (item is Map) {
            final b = _mapFromRawMap(item);
            if (b != null) mapped.add(b);
          }
        }
      } else if (raw is Map) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
        if (m.containsKey('docs') && m['docs'] is List) {
          for (final doc in (m['docs'] as List)) {
            if (doc is Map) {
              final b = _mapFromRawMap(doc);
              if (b != null) mapped.add(b);
            }
          }
        } else {
          // tenta interpretar o Map como um único Book (backend) ou doc
          final b = _mapFromRawMap(m);
          if (b != null) mapped.add(b);
        }
      } else if (raw is Book) {
        mapped.add(raw);
      } else {
        throw Exception('Resposta inesperada do serviço: ${raw.runtimeType}');
      }

      if (!mounted) return;
      setState(() {
        results = mapped;
        isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Erro ao buscar OpenLibrary: $e\n$st');
      if (!mounted) return;
      setState(() {
        results = [];
        isLoading = false;
        error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar Livros")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: "Digite o nome do livro",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => searchBooks(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: searchBooks,
                  child: const Text("Buscar"),
                )
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (error != null
                      ? Center(child: Text('Erro: $error'))
                      : results.isEmpty
                          ? const Center(child: Text('Nenhum resultado'))
                          : ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, __) => const Divider(height: 8),
                              itemBuilder: (_, index) {
                                final book = results[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  title: BookCard(
                                    book: book,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookDetailsScreen(book: book),
                                        ),
                                      );
                                    },
                                  ),
                                  // Exibe subtítulo com ano + badge de disponibilidade para ajudar UX
                                  subtitle: Row(
                                    children: [
                                      if (book.firstPublishYear != null) Text('${book.firstPublishYear}'),
                                      if (book.firstPublishYear != null) const SizedBox(width: 8),
                                      if (book.hasFulltext == true || (book.editionKeys != null && book.editionKeys!.isNotEmpty))
                                        Chip(
                                          label: const Text('Disponível'),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            )),
            )
          ],
        ),
      ),
    );
  }
}
