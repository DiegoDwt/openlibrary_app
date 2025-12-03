// lib/models/book.dart

class Book {
  final int? id;
  final String title;
  final List<String> authors;
  final int? coverId;
  final String? coverUrlBackend; // <--- NOVO: cover_url direto do backend
  final String? key;
  final int? firstPublishYear;
  final List<String>? isbns;
  final bool hasFulltext;
  final int ebookCount;
  final List<String>? editionKeys;

  final String? description;
  final String? sourceUrl;

  Book({
    this.id,
    required this.title,
    required this.authors,
    this.coverId,
    this.coverUrlBackend,
    this.key,
    this.firstPublishYear,
    this.isbns,
    this.hasFulltext = false,
    this.ebookCount = 0,
    this.editionKeys,
    this.description,
    this.sourceUrl,
  });

  // -----------------------------
  // 1) Parse da OpenLibrary (/search.json)
  // -----------------------------
  factory Book.fromSearchDoc(Map<String, dynamic> doc) {
    return Book(
      id: null,
      title: doc['title'] ?? 'Sem título',
      authors: (doc['author_name'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      coverId: doc['cover_i'] is int
          ? doc['cover_i']
          : (doc['cover_i'] != null
              ? int.tryParse(doc['cover_i'].toString())
              : null),
      coverUrlBackend: null, // nada vem do backend aqui
      key: doc['key'] as String?,
      firstPublishYear: doc['first_publish_year'] is int
          ? doc['first_publish_year']
          : null,
      isbns: (doc['isbn'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      hasFulltext: doc['has_fulltext'] == true,
      ebookCount: (doc['ebook_count_i'] is int)
          ? doc['ebook_count_i']
          : 0,
      editionKeys: (doc['edition_key'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      description: null,
      sourceUrl: null,
    );
  }

  // -----------------------------
  // 2) Parse do backend (list.php)
  // -----------------------------
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null
              ? int.tryParse(json['id'].toString())
              : null),

      title: json['title']?.toString() ?? 'Sem título',

      authors: (json['authors'] is List)
          ? (json['authors'] as List).map((e) => e.toString()).toList()
          : (json['authors'] is String)
              ? json['authors']
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList()
              : <String>[],

      coverId: json['cover_id'] is int
          ? json['cover_id']
          : (json['cover_id'] != null
              ? int.tryParse(json['cover_id'].toString())
              : null),

      coverUrlBackend: json['cover_url']?.toString(), // <--- PRIORIDADE

      key: json['key']?.toString(),

      firstPublishYear: json['first_publish_year'] is int
          ? json['first_publish_year']
          : (json['first_publish_year'] != null
              ? int.tryParse(json['first_publish_year'].toString())
              : null),

      isbns: (json['isbns'] is List)
          ? (json['isbns'] as List).map((e) => e.toString()).toList()
          : (json['isbn'] != null)
              ? [json['isbn'].toString()]
              : null,

      hasFulltext: json['has_fulltext'] == true,

      ebookCount: json['ebook_count'] is int
          ? json['ebook_count']
          : (json['ebook_count_i'] is int
              ? json['ebook_count_i']
              : 0),

      editionKeys: (json['edition_keys'] is List)
          ? (json['edition_keys'] as List)
              .map((e) => e.toString())
              .toList()
          : null,

      description: json['description'] is String
          ? json['description']
          : (json['description'] is Map
              ? (json['description']['value'] ??
                  json['description'].toString())
              : null),

      sourceUrl: json['source_url']?.toString() ??
          json['sourceUrl']?.toString(),
    );
  }

  // -----------------------------
  // 3) Salvar no backend
  // -----------------------------
  Map<String, dynamic> toJsonForSave() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'authors': authors,
      'cover_id': coverId,
      'cover_url': coverUrlOrNull, // <--- envia URL correta
      'key': key,
      'first_publish_year': firstPublishYear,
      'isbns': isbns,
      'description': description,
      'source_url': sourceUrl ?? openLibraryUrl,
    };
  }

  Map<String, dynamic> toJson() => toJsonForSave();

  // -----------------------------
  // 4) Funções Auxiliares
  // -----------------------------

  String? get isbn =>
      (isbns != null && isbns!.isNotEmpty) ? isbns!.first : null;

  /// PRIORIDADE:
  /// 1) cover_url do backend
  /// 2) URL com coverId
  /// 3) null
  String? get coverUrlOrNull {
    if (coverUrlBackend != null && coverUrlBackend!.isNotEmpty) {
      return coverUrlBackend;
    }
    if (coverId != null) {
      return 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
    }
    return null;
  }

  /// Compatibilidade — evita que a UI quebre
  String get coverUrl => coverUrlOrNull ?? '';

  /// Ex: https://openlibrary.org/works/OL1970691W
  String? get openLibraryUrl {
    if (key != null) return 'https://openlibrary.org$key';
    return null;
    }
}
