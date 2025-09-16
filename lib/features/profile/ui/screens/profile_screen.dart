import 'dart:io';
import 'package:book_app/features/profile/ui/screens/widgets/avatar_selection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routing/routes.dart';
import '../../data/repos/profile_repo.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/theme_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String isArabic(String ar, String en) {
      if (context.locale.languageCode == 'ar') {
        return ar;
      } else {
        return en;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'.tr()),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              if (value == 'language') {
                _showLanguageDialog(context);
              }
              else if (value == 'dark_mode') {
                context.read<ThemeCubit>().toggleTheme();
              }},
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'language',
                  child: ListTile(
                    leading: Icon(Icons.language),
                    title: Text('Change Language'.tr()),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'dark_mode',
                  child: Row(
                    children: [
                      Text('Dark Mode'.tr()),
                      BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, themeMode) {
                          return Switch(
                            value: themeMode == ThemeMode.dark,
                            onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                          );
                        },
                      ),
                    ],
                  )
                ),
              ];
            },
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoggedOut) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title:  Text('Logged Out'.tr()),
                  content:  Text('Do you want to login again or create a new account?'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.loginScreen,
                              (route) => false,
                        );
                      },
                      child: Text('Login'.tr()),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.signupsScreen,
                              (route) => false,
                        );
                      },
                      child: Text('Sign Up'.tr()),
                    ),
                  ],
                );
              },
            );
          }


          if (state is ProfileAvatarsLoaded) {
            showDialog(
              context: context,
              builder: (context) => AvatarSelectionDialog(
                avatarUrls: state.avatarUrls!,
                cubit: context.read<ProfileCubit>(),
              ),
            ).then((_) {
              // After dialog closes, reset state to ProfileLoaded
              if (state.profile != null && state.stats != null) {
                context.read<ProfileCubit>().emit(ProfileLoaded(
                  profile: state.profile,
                  stats: state.stats,
                ));
              }
            });
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileAvatarsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileError) {
            return Center(child: Text(state.message.tr()));
          }

          if (state is ProfileLoaded) {
            _debugTranslations(context);
          return _buildProfileContent(context, state);
          }

          if (state is ProfileAvatarsLoaded) {
            _debugTranslations(context);
          // Just show profile content normally, dialog is already handled in listener
            return _buildProfileContent(
              context,
              ProfileLoaded(profile: state.profile, stats: state.stats),
            );
          }

          return Center(child: Text('No profile data'.tr()));
        },
      ),

    );
  }
  void _changeLanguage(BuildContext context) async {
    final currentLocale = context.locale;
    final newLocale = currentLocale.languageCode == 'en' ? Locale('ar') : Locale('en');

    await context.setLocale(newLocale);

    // Force a complete rebuild by navigating to a new instance
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(key: UniqueKey()),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('select_language'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('english'.tr()),
                onTap: () {
                  if (context.locale.languageCode != 'en') {
                    _changeLanguage(context);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('arabic'.tr()),
                onTap: () {
                  if (context.locale.languageCode != 'ar') {
                    _changeLanguage(context);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildProfileContent(BuildContext context, ProfileLoaded state) {
    final profile = state.profile;
    final stats = state.stats;
    final cubit = context.read<ProfileCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(context, profile, cubit),

          const SizedBox(height: 24),

          // Reading Stats
          _buildReadingStats(stats!),

          const SizedBox(height: 24),

          // Profile Actions
          _buildProfileActions(context, cubit),

        ],
      ),
    );
  }

  void _debugTranslations(BuildContext context) {
    print('Current locale: ${context.locale}');
    print('Supported locales: ${context.supportedLocales}');
    print('Profile translation: ${'profile'.tr()}');
    print('Change language translation: ${'change_language'.tr()}');
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic>? profile, ProfileCubit cubit) {
    final email = profile?['email'] ?? 'No email';
    final username = profile?['username'] ?? 'User';
    final fullName = profile?['full_name'] ?? '';
    final avatarUrl = profile?['avatar_url'];
    final bio = profile?['bio'] ?? 'No bio yet';

    print('Avatar URL from profile: $avatarUrl');

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:  _getAvatarImageProvider(avatarUrl),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 18,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  onPressed: () => _pickImage(context, cubit),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          fullName.isNotEmpty ? fullName : username,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        // Text(
        //   email,
        //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        // ),
        const SizedBox(height: 8),
        Text(
          bio,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _editProfile(context, profile, cubit),
          child: Text('Edit Profile'.tr()),
        ),
      ],
    );
  }

  // Update your _getAvatarImageProvider method
  ImageProvider _getAvatarImageProvider(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Add cache buster to avoid caching issues
      final cacheBusterUrl = '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      return CachedNetworkImageProvider(cacheBusterUrl);
    }

    // Return a default avatar - you can use a local asset or a default URL
    return const AssetImage('assets/avatar/default_avatar.png');

    // OR use a default avatar from your Supabase storage
    // return CachedNetworkImageProvider('https://your-supabase-url/storage/v1/object/public/avatars/default_avatar.png');
  }
  Widget _buildReadingStats(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Reading Stats'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', stats['total_books']?.toString() ?? '0'),
                _buildStatItem('Read', stats['books_read']?.toString() ?? '0'),
                _buildStatItem('Reading', stats['currently_reading']?.toString() ?? '0'),
                _buildStatItem('To Read', stats['to_read']?.toString() ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileActions(BuildContext context, ProfileCubit cubit) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.library_books),
          title: Text('My Library'.tr()),
          onTap: () {
            Navigator.pushNamed(context, Routes.myLibraryScreen);
          },
        ),
        ListTile(
          leading: const Icon(Icons.star),
          title: Text('My Reviews'.tr()),
          onTap: () {
            Navigator.pushNamed(context, Routes.userReviewScreen);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title:  Text('Logout'.tr(), style: TextStyle(color: Colors.red)),
          onTap: () => _showLogoutDialog(context, cubit),
        ),
      ],
    );
  }

  // Replace your existing _pickImage method with this one
  Future<void> _pickImage(BuildContext context, ProfileCubit cubit) async {
    // Show options: Camera, Gallery, or Select from Avatars
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _takePhoto(context, cubit);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _chooseFromGallery(context, cubit);
            },
          ),
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('Choose from Avatars'),
            onTap: () {
              Navigator.pop(context);
              // Load and show available avatars
              cubit.loadAvailableAvatars();
            },
          ),
        ],
      ),
    );
  }

// Add these helper methods
  Future<void> _takePhoto(BuildContext context, ProfileCubit cubit) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      try {
        await cubit.uploadProfileImage(File(pickedFile.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e')),
        );
      }
    }
  }

  Future<void> _chooseFromGallery(BuildContext context, ProfileCubit cubit) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      try {
        await cubit.uploadProfileImage(File(pickedFile.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e')),
        );
      }
    }
  }

  void _editProfile(BuildContext context, Map<String, dynamic>? profile, ProfileCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text('Edit Profile'.tr()),
        content: EditProfileForm(profile: profile, cubit: cubit),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, ProfileCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text('Logout'.tr()),
        content:  Text('Are you sure you want to logout?'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cubit.logout();
            },
            child: Text('Logout'.tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Edit Profile Form
class EditProfileForm extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final ProfileCubit cubit;

  const EditProfileForm({super.key, required this.profile, required this.cubit});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.profile?['username'] ?? '';
    _fullNameController.text = widget.profile?['full_name'] ?? '';
    _bioController.text = widget.profile?['bio'] ?? '';
    _websiteController.text = widget.profile?['website'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'Bio'),
            maxLines: 3,
          ),
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(labelText: 'Website'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveProfile,
            child: Text('Save Changes'.tr()),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      widget.cubit.updateProfile({
        'username': _usernameController.text,
        'full_name': _fullNameController.text,
        'bio': _bioController.text,
        'website': _websiteController.text,
      });
      Navigator.pop(context);
    }
  }


  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}