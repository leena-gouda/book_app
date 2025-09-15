import '../../../home/data/models/book_model.dart';

class UserBook {
  final int id;
  final String bookId;
  final String status;
  final int? rating;
  final String? notes;
  final DateTime? updatedDate;
  final DateTime? finishedDate;
  final DateTime createdAt;
  final Items bookDetails;
  final double? progress;

  UserBook({
    required this.id,
    required this.bookId,
    required this.status,
    this.rating,
    this.notes,
    this.updatedDate,
    this.finishedDate,
    required this.createdAt,
    required this.bookDetails,
    this.progress,
  });


  factory UserBook.fromJson(Map<String, dynamic> json) {
    print("Raw Supabase JSON: $json");
    print("Supabase books object: ${json['books']}");
    final book = json['books'] != null
        ? Items.fromSupabaseJson(json['books'])
        : Items(
      id: '',
      etag: '',
      selfLink: '',
      volumeInfo: VolumeInfo(
        title: 'Unknown Title',
        authors: ['Unknown Author'],
        publisher: 'Unknown Publisher',
        publishedDate: 'Unknown Date',
        description: 'No description available.',
        pageCount: 0,
        categories: ['Uncategorized'],
        averageRating: 0.0,
        ratingsCount: 0,
        imageLinks: ImageLinks(
          smallThumbnail: '',
          thumbnail: '',
        ),
      ),
    );

    print("Parsed book title: ${book.volumeInfo?.title}");

    return UserBook(
      id: json['id'],
      bookId: json['book_id'],
      status: json['status'],
      rating: json['rating'],
      notes: json['notes'] ?? '',
      updatedDate: json['updated_date'] != null
          ? DateTime.parse(json['updated_date'])
          : null,

      finishedDate: json['finished_date'] != null
          ? DateTime.parse(json['finished_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      bookDetails: book,
      progress: json['progress'] != null ? (json['progress'] as num).toDouble() : null,
    );
  }

  UserBook copyWith({double? progress, required String status,}) {
    return UserBook(
      id: id,
      bookId: bookId,
      status: status,
      rating: rating,
      notes: notes,
      updatedDate: updatedDate,
      finishedDate: finishedDate,
      createdAt: createdAt,
      bookDetails: bookDetails,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'status': status,
      'rating': rating,
      'notes': notes,
      'updatedDate': updatedDate?.toIso8601String(),
      'finished_date': finishedDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'books': bookDetails.toJson(),
      'progress': progress,
    };
  }
}