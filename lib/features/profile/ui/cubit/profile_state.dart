// profile_state.dart
part of 'profile_cubit.dart';

abstract class ProfileState {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? stats;
  final List<String>? avatarUrls;

  const ProfileState({this.profile, this.stats, this.avatarUrls});
}

class ProfileInitial extends ProfileState {}
class ProfileNoData extends ProfileState {} // Add this


class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded({super.profile, super.stats, super.avatarUrls});
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);
}

class ProfileLoggedOut extends ProfileState {}

class ProfileAvatarsLoaded extends ProfileLoaded {
  const ProfileAvatarsLoaded({super.profile, super.stats, required super.avatarUrls});
}

// Add this state
class ProfileAvatarsLoading extends ProfileState {
  const ProfileAvatarsLoading({super.profile, super.stats});
}