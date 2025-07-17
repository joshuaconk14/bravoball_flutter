class MentalTrainingQuote {
  final String id;
  final String text;
  final String? author;
  final String? category;
  final String? source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MentalTrainingQuote({
    required this.id,
    required this.text,
    this.author,
    this.category,
    this.source,
    this.createdAt,
    this.updatedAt,
  });

  factory MentalTrainingQuote.fromJson(Map<String, dynamic> json) {
    return MentalTrainingQuote(
      id: json['id']?.toString() ?? '',
      text: json['text'] ?? json['quote'] ?? '',
      author: json['author'],
      category: json['category'] ?? json['quote_type'],
      source: json['source'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category': category,
      'source': source,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MentalTrainingQuote(id: $id, text: $text, author: $author, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MentalTrainingQuote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 