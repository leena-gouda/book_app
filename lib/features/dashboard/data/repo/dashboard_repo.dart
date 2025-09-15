import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../myLibrary/data/models/user_book_model.dart';
import '../models/reading_goal_model.dart';

class DashboardRepo {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<UserBook>> getUserBooks(String userId) async {
    final response = await _client
        .from('user_books')
        .select('*, books(*)')
        .eq('user_id', userId);

    final data = response as List<dynamic>;
    return data.map((json) => UserBook.fromJson(json)).toList();
  }

  Future<ReadingGoal?> getReadingGoal(String userId, int year) async {
    final response = await _client
        .from('reading_goals')
        .select()
        .eq('user_id', userId) // Use user_id instead of id
        .eq('year', year)
        .maybeSingle();

    if (response == null) return ReadingGoal(userId: userId, year: year, goal: 12);
    return ReadingGoal.fromJson(response);
  }

  Future<void> setReadingGoal(String userId, int year, int goal) async {
    await _client.from('reading_goals').upsert({
      'user_id': userId, // Use user_id instead of id
      'year': year,
      'reading_goal': goal, // Use the correct column name
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,year'); // Use user_id in the conflict target
  }

  Future<void> updateReadingGoal(int goal) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if a goal already exists for this year
      final existingGoal = await _client
          .from('reading_goals')
          .select()
          .eq('user_id', user.id) // Use user_id
          .eq('year', DateTime.now().year)
          .maybeSingle();

      if (existingGoal != null) {
        // Update existing goal - use the correct column name 'reading_goal'
        await _client
            .from('reading_goals')
            .update({
          'reading_goal': goal, // Use the correct column name
          'created_at': DateTime.now().toIso8601String(), // Use created_at since updated_at doesn't exist
        })
            .eq('user_id', user.id) // Use user_id
            .eq('year', DateTime.now().year);
      } else {
        // Insert new goal - use the correct column names
        await _client
            .from('reading_goals')
            .insert({
          'user_id': user.id, // Use user_id
          'reading_goal': goal, // Use the correct column name
          'year': DateTime.now().year,
          'created_at': DateTime.now().toIso8601String(),
          // Don't include updated_at since it doesn't exist in your table
        });
      }

    } catch (e) {
      print('Error updating reading goal: $e');
      throw Exception('Failed to update reading goal: $e');
    }
  }

  // Simplified version using upsert
  Future<void> setReadingGoalSimplified(int goal) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client.from('reading_goals').upsert({
        'user_id': user.id,
        'year': DateTime.now().year,
        'reading_goal': goal,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,year');

    } catch (e) {
      print('Error setting reading goal: $e');
      throw Exception('Failed to set reading goal: $e');
    }
  }
}