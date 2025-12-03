// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class ApiService {
  // Default para Android emulator. Se for usar dispositivo físico, passe baseUrl no construtor.
  static const String _defaultBase = 'http://10.0.2.2/meuapp';

  final String base;

  ApiService({String? baseUrl}) : base = baseUrl ?? _defaultBase;

  Duration get _timeout => const Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('$base/$path');

  // -----------------------
  // Helper: limpa um body que pode conter texto antes/depois do JSON
  // -----------------------
  String _extractJson(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;

    // procura array primeiro
    final firstArr = s.indexOf('[');
    final lastArr = s.lastIndexOf(']');
    if (firstArr != -1 && lastArr != -1 && lastArr >= firstArr) {
      return s.substring(firstArr, lastArr + 1);
    }

    // tenta objeto
    final firstObj = s.indexOf('{');
    final lastObj = s.lastIndexOf('}');
    if (firstObj != -1 && lastObj != -1 && lastObj >= firstObj) {
      return s.substring(firstObj, lastObj + 1);
    }

    // nada encontrado — retorna original (fallthrough)
    return s;
  }

  // Lista todos os livros salvos (list.php)
  Future<List<Book>> listSaved() async {
    final uri = _uri('list.php');
    try {
      final res = await http.get(uri).timeout(_timeout);
      print('DEBUG ApiService.listSaved - ${uri.toString()} -> status=${res.statusCode}');
      if (res.statusCode != 200) throw Exception('Erro listSaved: ${res.statusCode}');

      final raw = res.body;
      final cleaned = _extractJson(raw);

      try {
        final data = jsonDecode(cleaned);
        if (data is List) {
          return data
              .map<Book>((e) => Book.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          throw Exception('Resposta inesperada do list.php: não é array');
        }
      } on FormatException catch (e) {
        // inclui corpo original para ajudar debug
        throw Exception('Falha ao decodificar JSON em listSaved: ${e.message} -- body not JSON\n${res.body}');
      }
    } on TimeoutException {
      throw Exception('Timeout ao conectar em $uri');
    } catch (e) {
      rethrow;
    }
  }

  // Salva um livro (save.php) - envia JSON e espera id no retorno (201/200)
  Future<int?> saveBook(Book book) async {
    final uri = _uri('save.php');

    // primeiro, tenta obter um payload via métodos do model (toJsonForSave / toJson)
    Map<String, dynamic> payload = {};

    final dyn = book as dynamic;

    try {
      payload = (dyn.toJsonForSave() as Map<String, dynamic>);
    } catch (_) {
      try {
        payload = (dyn.toJson() as Map<String, dynamic>);
      } catch (_) {
        // fallback: construir payload seguro com campos conhecidos
        String? isbn;
        try {
          isbn = dyn.isbn?.toString();
        } catch (_) {
          isbn = null;
        }

        String? coverUrl;
        try {
          final c = dyn.coverUrl;
          coverUrl = (c is String && c.trim().isNotEmpty) ? c : null;
        } catch (_) {
          coverUrl = null;
        }

        String? description;
        try {
          description = dyn.description as String?;
        } catch (_) {
          description = null;
        }

        String? sourceUrl;
        try {
          sourceUrl = dyn.sourceUrl as String?;
        } catch (_) {
          try {
            sourceUrl = dyn.openLibraryUrl as String?;
          } catch (_) {
            sourceUrl = null;
          }
        }

        dynamic authorsDynamic;
        try {
          authorsDynamic = dyn.authors;
        } catch (_) {
          authorsDynamic = null;
        }

        payload = {
          'title': book.title,
          'authors': authorsDynamic ?? book.authors,
          'isbn': isbn,
          'cover_url': coverUrl,
          'description': description,
          'source_url': sourceUrl,
        };
      }
    }

    // ---------
    // Normalizações finais antes de enviar
    // ---------

    // authors: se veio como List, converte para string "A, B, C"
    try {
      final a = payload['authors'];
      if (a is List) {
        payload['authors'] = a.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');
      } else if (a != null) {
        payload['authors'] = a.toString();
      } else {
        payload.remove('authors');
      }
    } catch (_) {
      // ignore
    }

    // cover_url: se existir como coverUrl (getter) e payload.cover_url vazio, tenta preencher
    try {
      if ((payload['cover_url'] == null || payload['cover_url'].toString().trim().isEmpty)) {
        final dynCover = dyn.coverUrl;
        if (dynCover is String && dynCover.trim().isNotEmpty) {
          payload['cover_url'] = dynCover;
        } else {
          // tenta property coverUrlOrNull (se o model tiver)
          try {
            final alt = dyn.coverUrlOrNull;
            if (alt is String && alt.trim().isNotEmpty) payload['cover_url'] = alt;
          } catch (_) {}
        }
      }
    } catch (_) {}

    // source_url: preferir openLibraryUrl se não informado
    try {
      if (payload['source_url'] == null || payload['source_url'].toString().trim().isEmpty) {
        final alt = (dyn.openLibraryUrl ?? null);
        if (alt is String && alt.trim().isNotEmpty) payload['source_url'] = alt;
      }
    } catch (_) {}

    // DEBUG: imprimir payload
    print('DEBUG ApiService.saveBook - POST $uri');
    print('DEBUG ApiService.saveBook - payload: $payload');

    try {
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
          .timeout(_timeout);

      print('DEBUG ApiService.saveBook - status: ${res.statusCode}');
      print('DEBUG ApiService.saveBook - body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        // tentar extrair JSON (defensivo)
        final raw = res.body;
        final cleaned = _extractJson(raw);
        try {
          final js = jsonDecode(cleaned);
          if (js is Map) {
            if (js.containsKey('id')) {
              final idVal = js['id'];
              if (idVal is int) return idVal;
              return int.tryParse(idVal?.toString() ?? '');
            }
            if (js.containsKey('ok') && js['ok'] == true) return null;
            throw Exception('Resposta inesperada do servidor: $js');
          } else {
            throw Exception('Resposta NÃO-JSON esperada do servidor');
          }
        } on FormatException catch (e) {
          throw Exception('Falha ao decodificar JSON: $e -- body: ${res.body}');
        }
      } else {
        // inclui body para facilitar debug do 500
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } on TimeoutException {
      throw Exception('Timeout ao conectar em $uri');
    } catch (e) {
      rethrow;
    }
  }

  // Deleta livro por id (delete.php) - usa POST com body {"id": X}
  Future<bool> deleteBook(int id) async {
    final uri = _uri('delete.php');
    try {
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'id': id}))
          .timeout(_timeout);
      print('DEBUG ApiService.deleteBook - status: ${res.statusCode} body: ${res.body}');
      if (res.statusCode != 200) throw Exception('Erro deleteBook: ${res.statusCode}');
      final js = jsonDecode(res.body);
      if (js is Map && js.containsKey('ok')) return js['ok'] == true;
      return false;
    } on TimeoutException {
      throw Exception('Timeout ao conectar em $uri');
    } on FormatException catch (e) {
      throw Exception('Falha ao decodificar JSON deleteBook: $e');
    } catch (e) {
      rethrow;
    }
  }
}
