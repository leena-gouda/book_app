class CustomList {
  final int id;
  final String name;
  final String userId;
  final DateTime createdAt;
  final int bookCount;

  CustomList({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
    required this.bookCount,
  });

  factory CustomList.fromJson(Map<String, dynamic> json) {
    return CustomList(
      id: _parseId(json['id']), // Use helper function for safe parsing
      name: json['name'] ?? 'Unnamed List',
      userId: json['user_id'] ?? '', // Handle missing user_id
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      bookCount: _parseBookCount(json['book_count']), // Handle book_count safely
    );
  }

  // Helper function to safely parse ID
  static int _parseId(dynamic idValue) {
    if (idValue is int) return idValue;
    if (idValue is String) return int.tryParse(idValue) ?? 0;
    return 0;
  }

  // Helper function to safely parse book count
  static int _parseBookCount(dynamic bookCountValue) {
    if (bookCountValue is int) return bookCountValue;
    if (bookCountValue is String) return int.tryParse(bookCountValue) ?? 0;
    if (bookCountValue is double) return bookCountValue.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'book_count': bookCount,
    };
  }
}