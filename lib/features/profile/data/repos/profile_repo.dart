import 'dart:io';
import 'package:book_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      // Try to get existing profile
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // If profile doesn't exist, create it
      if (response == null) {
        await _createProfileForUser(user);
        // Now get the newly created profile
        final newResponse = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        return newResponse;
      }

      return response;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

// In your ProfileRepository class
  Future<List<String>> getAvailableAvatars() async {
    try {
      print('Loading avatars from Supabase storage...');

      final List<String> avatarUrls = [];

      // List all files in the avatars bucket
      final files = await _client.storage
          .from('avatars')
          .list();

      print('Found ${files.length} files in avatars bucket');

      // Generate public URLs for each file
      for (final file in files) {
        final url = _client.storage
            .from('avatars')
            .getPublicUrl(file.name);
        avatarUrls.add(url);
      }

      print('Total avatar URLs: ${avatarUrls.length}');

      return avatarUrls;
    } catch (e) {
      print('Error fetching avatars: $e');
      return [];
    }
  }

  Future<void> selectAvatar(String avatarUrl) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('Setting avatar URL in database: $avatarUrl');

      // Update the profile with the selected avatar URL
      await updateProfile({'avatar_url': avatarUrl});

      print('Avatar URL successfully saved to database');
    } catch (e) {
      print('Error selecting avatar: $e');
      throw Exception('Failed to select avatar: $e');
    }
  }

  Future<void> _createProfileForUser(User user) async {
    try {
      final username = user.email?.split('@').first ?? 'user';

      await _client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'username': username,
        'full_name': username,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating profile: $e');
      throw Exception('Failed to create profile');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client
          .from('profiles')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create user-specific folder path
      final fileExt = imageFile.path.split('.').last;
      final filePath = '${user.id}/avatar.$fileExt'; // User folder + filename

      // Upload the image
      await _client.storage
          .from('avatars')
          .upload(filePath, imageFile, fileOptions: FileOptions(upsert: true));

      // Get the public URL
      final imageUrl = _client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      print('Avatar uploaded to: $imageUrl');

      // Update profile with new avatar URL
      await updateProfile({'avatar_url': imageUrl});

      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Error logging out: $e');
      throw Exception('Failed to logout');
    }
  }

  Future<Map<String, dynamic>> getReadingStats() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Use the manual counting method
      return await _getReadingStatsManual();
    } catch (e) {
      print('Error getting reading stats: $e');
      return {'total_books': 0, 'books_read': 0, 'currently_reading': 0, 'to_read': 0};
    }
  }

  // Manual counting method (most reliable)
  Future<Map<String, dynamic>> _getReadingStatsManual() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get all user books
      final response = await _client
          .from('user_books')
          .select('status')
          .eq('user_id', user.id);

      if (response.isEmpty) {
        return {'total_books': 0, 'books_read': 0, 'currently_reading': 0, 'to_read': 0};
      }

      // Manually group and count
      int booksRead = 0;
      int currentlyReading = 0;
      int toRead = 0;

      for (final item in response) {
        final status = item['status'] as String?;
        switch (status) {
          case 'finished':
            booksRead++;
            break;
          case 'reading':
            currentlyReading++;
            break;
          case 'to_read':
            toRead++;
            break;
        }
      }

      final totalBooks = booksRead + currentlyReading + toRead;

      return {
        'total_books': totalBooks,
        'books_read': booksRead,
        'currently_reading': currentlyReading,
        'to_read': toRead,
      };
    } catch (e) {
      print('Error in manual reading stats: $e');
      return {'total_books': 0, 'books_read': 0, 'currently_reading': 0, 'to_read': 0};
    }
  }

  // Alternative method using count queries (if you want to try it)
  Future<Map<String, dynamic>> getReadingStatsWithCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get counts using separate queries
      final totalBooks = await _getBookCount(user.id);
      final booksRead = await _getBookCountByStatus(user.id, 'finished');
      final currentlyReading = await _getBookCountByStatus(user.id, 'reading');
      final toRead = await _getBookCountByStatus(user.id, 'to_read');

      return {
        'total_books': totalBooks,
        'books_read': booksRead,
        'currently_reading': currentlyReading,
        'to_read': toRead,
      };
    } catch (e) {
      print('Error getting reading stats with count: $e');
      return {'total_books': 0, 'books_read': 0, 'currently_reading': 0, 'to_read': 0};
    }
  }

  Future<int> _getBookCount(String userId) async {
    try {
      final response = await _client
          .from('user_books')
          .select()
          .eq('user_id', userId);

      return response.length;
    } catch (e) {
      print('Error counting total books: $e');
      return 0;
    }
  }

  Future<int> _getBookCountByStatus(String userId, String status) async {
    try {
      final response = await _client
          .from('user_books')
          .select()
          .eq('user_id', userId)
          .eq('status', status);

      return response.length;
    } catch (e) {
      print('Error counting books for status $status: $e');
      return 0;
    }
  }

  Future<void> debugStorage() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      print('=== STORAGE DEBUG INFO ===');
      print('User ID: ${user.id}');

      // Check if bucket exists
      final buckets = await _client.storage.listBuckets();
      print('Available buckets: ${buckets.map((b) => b.name).toList()}');

      // Check if user folder exists
      try {
        final files = await _client.storage
            .from('avatars')
            .list(path: user.id);
        print('Files in user folder: $files');
      } catch (e) {
        print('No files in user folder yet: $e');
      }
    } catch (e) {
      print('Storage debug error: $e');
    }
  }
}