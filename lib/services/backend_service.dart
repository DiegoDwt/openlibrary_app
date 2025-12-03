import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

// Base URL para o XAMPP rodando no host quando o app roda no Android emulator:
const String baseUrl = 'http://10.0.2.2/meuapp'; // ajuste se usar IP do PC

class BackendService {
  // lista livros salvos no backend (list.php)
  Future<List<Book>> listSaved() async {
    final res = await http.get(Uri.parse('$baseUrl/list.php'));
    if (res.statusCode != 200) throw Exception('Erro ao listar salvos: ${res.statusCode}');
    final json = jsonDecode(res.body) as List<dynamic>;
    return json.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  // salva um livro chamando save.php (POST JSON)
  Future<int?> saveBook(Book book) async {
    final res = await http.post(
      Uri.parse('$baseUrl/save.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(book.toJsonForSave()),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final js = jsonDecode(res.body);
      return js['id'] is int ? js['id'] : int.tryParse('${js['id']}');
    } else {
      throw Exception('Erro ao salvar livro: ${res.statusCode} ${res.body}');
    }
  }

  // deleta por id (delete.php) - usamos POST com JSON para simplicidade
  Future<bool> deleteBook(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/delete.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );
    if (res.statusCode == 200) {
      final js = jsonDecode(res.body);
      return js['ok'] == true;
    } else {
      throw Exception('Erro ao deletar: ${res.statusCode}');
    }
  }
}
