import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repos/profile_repo.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit(this.repository) : super(ProfileInitial());

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    try {
      final profile = await repository.getProfile();
      final stats = await repository.getReadingStats();
      emit(ProfileLoaded(profile: profile, stats: stats));
    } catch (e) {
      emit(ProfileError('Failed to load profile: $e'));
    }
  }

  // In your ProfileCubit class
// In your ProfileCubit class
  Future<void> loadAvailableAvatars() async {
    try {
      final avatarUrls = await repository.getAvailableAvatars();

      // Create a new state that will trigger a rebuild
      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        emit(ProfileAvatarsLoading()); // Intermediate state to trigger rebuild
        await Future.delayed(const Duration(milliseconds: 50)); // Small delay
        emit(ProfileAvatarsLoaded(
          profile: currentState.profile,
          stats: currentState.stats,
          avatarUrls: avatarUrls,
        ));
      } else {
        // If we don't have a loaded state, load profile first
        await loadProfile();
        if (state is ProfileLoaded) {
          final currentState = state as ProfileLoaded;
          emit(ProfileAvatarsLoading()); // Intermediate state
          await Future.delayed(const Duration(milliseconds: 50));
          emit(ProfileAvatarsLoaded(
            profile: currentState.profile,
            stats: currentState.stats,
            avatarUrls: avatarUrls,
          ));
        }
      }
    } catch (e) {
      print('Error loading avatars: $e');
      emit(ProfileError('Failed to load avatars: $e'));
    }
  }
  Future<void> selectAvatarFromUrl(String avatarUrl) async {
    try {
      emit(ProfileLoading());
      await repository.selectAvatar(avatarUrl);

      // Reload profile to get the updated avatar URL
      await loadProfile();

    } catch (e) {
      emit(ProfileError('Failed to select avatar: $e'));

    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      emit(ProfileLoading());
      await repository.updateProfile(updates);
      await loadProfile(); // Reload profile after update
    } catch (e) {
      emit(ProfileError('Failed to update profile: $e'));
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      emit(ProfileLoading());
      await repository.uploadProfileImage(imageFile);
      await loadProfile(); // Reload profile after upload
    } catch (e) {
      emit(ProfileError('Failed to upload image: $e'));
    }
  }

  Future<void> logout() async {
    try {
      emit(ProfileLoading());
      await repository.logout();
      emit(ProfileLoggedOut());
    } catch (e) {
      emit(ProfileError('Failed to logout: $e'));
    }
  }
}