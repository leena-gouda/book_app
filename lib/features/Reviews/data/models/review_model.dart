class Review {
  final String userId;
  final String userName;
  final String comment;
  final double rating;
  final DateTime Timestamp;
  final String bookId;

  Review({
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.Timestamp,
    required this.bookId,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      userId: data['userId'],
      userName: data['userName'],
      comment: data['comment'],
      rating: data['rating'].toDouble(),
      Timestamp: (data['Timestamp']).toDate(),
      bookId: data['bookId'],
    );
  }
}
