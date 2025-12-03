// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import '../widgets/book_card.dart';

class DetailScreen extends StatefulWidget {
  final Book book;
  const DetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ApiService _api = ApiService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // debug seguro
    try {
      debugPrint('DEBUG DetailScreen received book: ${widget.book.toJson()}');
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final id = await _api.saveBook(widget.book);
      setState(() => _saving = false);
      if (id != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Livro salvo (id: $id)')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Livro salvo, sem id retornado')));
      }
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      debugPrint('DEBUG save error: $e');
    }
  }

  String _authorsText(Book b) {
    final a = b.authors;
    if (a.isEmpty) return 'Autor desconhecido';
    return a.join(', ');
  }

  String _descriptionText(Book b) {
    try {
      final d = b.description;
      if (d == null || d.toString().trim().isEmpty) return 'Sem descrição disponível';
      return d.toString();
    } catch (e) {
      return 'Sem descrição disponível';
    }
  }

  String? _sourceUrl(Book b) {
    // prefer openLibraryUrl se existir, senão sourceUrl
    return b.openLibraryUrl ?? b.sourceUrl;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL inválida')));
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    final authors = _authorsText(b);
    final description = _descriptionText(b);
    final source = _sourceUrl(b);

    return Scaffold(
      appBar: AppBar(title: Text(b.title)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: IgnorePointer(
                ignoring: true,
                child: BookCard(book: b),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(b.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(authors, style: TextStyle(color: Colors.grey[700])),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(description, style: const TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Salvando...' : 'Salvar nos Favoritos'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: source != null ? () => _openUrl(source) : null,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir fonte'),
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
