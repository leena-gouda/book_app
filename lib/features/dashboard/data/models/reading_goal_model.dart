class ReadingGoal {
  final String userId;
  final int year;
  final int goal;

  ReadingGoal({
    required this.userId,
    required this.year,
    required this.goal,
  });

  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      userId: json['user_id'],
      year: json['year'],
      goal: (json['reading_goal'] as int?) ?? 12, // 👈 fallback here
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'year': year,
      'reading_goal': goal,
      'created_at': DateTime.now().toIso8601String(),

    };
  }
}
