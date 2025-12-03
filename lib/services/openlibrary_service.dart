// lib/services/openlibrary_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class OpenLibraryService {
  static const String _base = 'https://openlibrary.org';
  Duration get _timeout => const Duration(seconds: 15);

  /// Busca por título (usa /search.json?title=...)
  Future<List<Book>> searchByTitle(String title, {int page = 1}) async {
    final q = Uri.encodeQueryComponent(title);
    final uri = Uri.parse('$_base/search.json?title=$q&page=$page');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('OpenLibrary search error: ${resp.statusCode}');
    }
    final Map<String, dynamic> data = json.decode(resp.body);
    final docs = data['docs'] as List<dynamic>? ?? [];
    return docs
        .map((d) => Book.fromSearchDoc(Map<String, dynamic>.from(d as Map)))
        .toList();
  }

  /// Busca por assunto (subject)
  Future<List<Book>> searchBySubject(String subject, {int page = 1}) async {
    final q = Uri.encodeQueryComponent(subject);
    final uri = Uri.parse('$_base/search.json?subject=$q&page=$page');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) throw Exception('OpenLibrary subject error: ${resp.statusCode}');
    final Map<String, dynamic> data = json.decode(resp.body);
    final docs = data['docs'] as List<dynamic>? ?? [];
    return docs
        .map((d) => Book.fromSearchDoc(Map<String, dynamic>.from(d as Map)))
        .toList();
  }

  /// Puxa detalhes de uma obra (works/...json) — útil para tela de detalhes
  Future<Map<String, dynamic>> fetchWorkDetails(String workKey) async {
    // workKey esperado: "/works/OLxxxxW" ou "works/OLxxxW"
    final clean = workKey.startsWith('/') ? workKey : '/$workKey';
    final uri = Uri.parse('$_base$clean.json');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) throw Exception('Erro ao carregar detalhes: ${resp.statusCode}');
    return json.decode(resp.body) as Map<String, dynamic>;
  }
}
