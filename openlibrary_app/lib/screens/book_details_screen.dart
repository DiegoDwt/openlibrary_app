// lib/screens/book_details_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import '../services/api_service.dart'; // usado só para salvar favoritos

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final ApiService _api = ApiService();
  bool _saving = false;

  // disponibilidade derivada do próprio OpenLibrary (ou consulta direta à OpenLibrary)
  bool _available = false;
  String? _readUrl;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // tenta usar dados já presentes no objeto Book (provenientes da busca)
    _setAvailabilityFromBook(widget.book);
    // se necessário, consulta a OpenLibrary diretamente (NÃO o seu backend)
    if (!_available && widget.book.key != null) {
      _fetchFirstEditionFromOpenLibrary(widget.book);
    }
  }

  void _setAvailabilityFromBook(Book b) {
    // usa somente campos locais (vindos da busca)
    if (b.hasFulltext == true) {
      _available = true;
      _readUrl = _bestReadUrlFromBook(b);
    } else if (b.editionKeys != null && b.editionKeys!.isNotEmpty) {
      _available = true;
      _readUrl = "https://openlibrary.org/books/${b.editionKeys!.first}";
    } else {
      _available = false;
      _readUrl = null;
    }
    setState(() {});
  }

  // monta a melhor readUrl a partir do Book (prefere edition, depois work)
  String? _bestReadUrlFromBook(Book b) {
    if (b.editionKeys != null && b.editionKeys!.isNotEmpty) {
      return "https://openlibrary.org/books/${b.editionKeys!.first}";
    }
    if (b.key != null && b.key!.isNotEmpty) {
      return "https://openlibrary.org${b.key}";
    }
    if (b.sourceUrl != null && b.sourceUrl!.isNotEmpty) {
      return b.sourceUrl;
    }
    return null;
  }

  Future<void> _fetchFirstEditionFromOpenLibrary(Book b) async {
    // consulta direta a OpenLibrary (sem envolver backend)
    if (b.key == null || b.key!.isEmpty) return;
    final workPath = b.key!; // ex: "/works/OLxxxxW"
    final url = 'https://openlibrary.org$workPath/editions.json?limit=1';
    try {
      setState(() => _checking = true);
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final js = jsonDecode(res.body);
        if (js is Map && js['entries'] is List && (js['entries'] as List).isNotEmpty) {
          final first = (js['entries'] as List).first;
          if (first is Map) {
            // primeiro caso: key = "/books/OLxxxM"
            if (first.containsKey('key') && first['key'] is String) {
              final k = (first['key'] as String).trim();
              if (k.startsWith('/books/') || k.startsWith('OL')) {
                final editionKey = k.replaceAll('/books/', '').replaceAll('/','');
                _readUrl = "https://openlibrary.org/books/$editionKey";
                _available = true;
                setState(() {});
                return;
              }
            }
            // outras heurísticas poderiam ir aqui (ocaid, etc.)
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao consultar OpenLibrary editions: $e');
    } finally {
      setState(() => _checking = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL inválida')));
      return;
    }
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não é possível abrir $url')));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _authorsText(Book b) {
    return (b.authors.isEmpty) ? 'Autor desconhecido' : b.authors.join(', ');
  }

  String _descriptionText(Book b) {
    final d = b.description;
    if (d == null || d.toString().trim().isEmpty) return 'Sem descrição disponível';
    return d.toString();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final id = await _api.saveBook(widget.book);
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Livro salvo! ID: $id')));
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    final authors = _authorsText(b);
    final desc = _descriptionText(b);

    return Scaffold(
      appBar: AppBar(title: Text(b.title)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(height: 220, child: IgnorePointer(child: BookCard(book: b))),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: Text(b.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Text(authors, style: TextStyle(color: Colors.grey[700]))),
            const SizedBox(height: 8),

            // badge
            Align(
              alignment: Alignment.centerLeft,
              child: _checking
                  ? Row(children: const [SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)), SizedBox(width:8), Text('Verificando...')])
                  : (_available ? Chip(label: const Text('Disponível para ler/baixar'), avatar: Icon(Icons.book)) : Chip(label: const Text('Somente informação'), avatar: Icon(Icons.info_outline))),
            ),

            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: Text(desc, style: const TextStyle(fontSize: 14)))),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.save),
                    label: Text(_saving ? 'Salvando...' : 'Salvar nos Favoritos'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final url = _bestReadUrlFromBook(b) ?? b.sourceUrl ?? (b.key != null ? 'https://openlibrary.org${b.key}' : null);
                      if (url != null) _openUrl(url);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir fonte'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_available)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _readUrl != null ? () => _openUrl(_readUrl!) : null,
                      icon: const Icon(Icons.download),
                      label: Text(_readUrl != null ? 'Ler / Baixar' : 'Abrir página'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
