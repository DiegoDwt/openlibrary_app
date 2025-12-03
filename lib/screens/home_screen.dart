// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/openlibrary_service.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _service = OpenLibraryService();
  final ScrollController _scrollController = ScrollController();

  List<Book> results = [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = false; // indica se há mais páginas
  int _page = 1;
  String? error;
  static const int _pageSize = 100; // valor aproximado — OpenLibrary retorna até 100 por página

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // inicia uma nova busca (reseta paginação)
  Future<void> search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    // desfoca teclado
    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      error = null;
      results = [];
      _page = 1;
      hasMore = false;
    });

    try {
      final pageRes = await _service.searchByTitle(q, page: _page);
      if (!mounted) return;
      setState(() {
        results = pageRes;
        hasMore = pageRes.length >= _pageSize;
        loading = false;
      });
    } catch (e, st) {
      debugPrint('Erro ao buscar livros: $e\n$st');
      if (!mounted) return;
      setState(() {
        results = [];
        loading = false;
        error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar livros: ${e.toString()}')),
      );
    }
  }

  // carrega próxima página quando o usuário chegar perto do final
  Future<void> _loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    setState(() => loadingMore = true);
    try {
      final nextPage = _page + 1;
      final pageRes = await _service.searchByTitle(q, page: nextPage);
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        results.addAll(pageRes);
        hasMore = pageRes.length >= _pageSize;
        loadingMore = false;
      });
    } catch (e, st) {
      debugPrint('Erro loadMore: $e\n$st');
      if (!mounted) return;
      setState(() {
        loadingMore = false;
        error = e.toString();
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = 200.0; // quando faltar 200px para o fim, tenta carregar mais
    if (_scrollController.position.maxScrollExtent - _scrollController.position.pixels <= threshold) {
      _loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await search();
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final crossCount = _calculateCrossAxisCount(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca na OpenLibrary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // campo de busca
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por título ou assunto',
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                results = [];
                                error = null;
                              });
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: search,
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (_) => search(),
                  onChanged: (_) {
                    // atualiza o estado para mostrar/ocultar o botão clear
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: search, child: const Text('Buscar')),
            ]),
          ),

          // conteúdo principal
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : (error != null
                    ? Center(child: Text('Erro: $error'))
                    : (results.isEmpty
                        ? const Center(child: Text('Nenhum resultado — tente outro termo.'))
                        : RefreshIndicator(
                            onRefresh: _onRefresh,
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossCount,
                                childAspectRatio: 0.55,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: results.length + (loadingMore ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i >= results.length) {
                                  // item de loading no final
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final b = results[i];
                                // garante toque mesmo que BookCard não tenha onTap
                                return InkWell(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => DetailScreen(book: b)),
                                  ),
                                  child: BookCard(book: b),
                                );
                              },
                            ),
                          ))),
          ),
        ],
      ),
    );
  }
}
