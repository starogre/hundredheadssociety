import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/portrait_provider.dart';
import '../models/portrait_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../widgets/profile_image_picker_dialog.dart';
import '../theme/app_theme.dart';
import '../widgets/portrait_details_dialog.dart';
import '../screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserModel? _userData;
  final ImagePicker _picker = ImagePicker();
  int _lastPortraitCount = 0;
  bool _isUpdatingProfileImage = false;
  int _imageRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _userService.getUserById(widget.userId);
    if (mounted) {
      setState(() {
        _userData = userData;
      });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    showDialog(
      context: context,
      builder: (context) => ProfileImagePickerDialog(
        onImageSelected: (File imageFile) async {
          try {
            setState(() {
              _isUpdatingProfileImage = true;
            });
            
            // Check authentication
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final currentUser = authProvider.currentUser;
            if (currentUser == null) {
              throw Exception('User not authenticated');
            }
            
            // Check file size (max 5MB)
            final fileSize = await imageFile.length();
            if (fileSize > 5 * 1024 * 1024) {
              throw Exception('Image file is too large. Please select a smaller image (max 5MB).');
            }
            
            final oldUrl = _userData?.profileImageUrl;
            
            // Delete the old file if it exists
            if (oldUrl != null) {
              try {
                final oldRef = FirebaseStorage.instance.refFromURL(oldUrl);
                await oldRef.delete();
              } catch (e) {
                // Ignore if file doesn't exist
              }
            }
            
            final fileExtension = imageFile.path.split('.').last.toLowerCase();
            final fileName = '${currentUser.uid}.$fileExtension';
            final storageRef = FirebaseStorage.instance.ref().child('profile-images/$fileName');
            
            // Upload the new image
            final uploadTask = storageRef.putFile(
              imageFile,
              SettableMetadata(
                contentType: 'image/$fileExtension',
                customMetadata: {
                  'uploadedBy': currentUser.uid,
                  'uploadedAt': DateTime.now().toIso8601String(),
                },
              ),
            );
            
            await uploadTask;
            final imageUrl = await storageRef.getDownloadURL();
            
            // Evict the old image from cache
            if (oldUrl != null) {
              CachedNetworkImage.evictFromCache(oldUrl);
            }
            
            // Update user profile in database
            await _userService.updateUserProfile(
              userId: widget.userId,
              profileImageUrl: imageUrl,
            );
            
            // Reload user data
            await _loadUserData();
            
            if (mounted) {
              setState(() {
                _isUpdatingProfileImage = false;
                _imageRefreshKey++; // Force image refresh
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isUpdatingProfileImage = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  int _getCurrentWeek() {
    final now = DateTime.now();
    final startDate = DateTime(2024, 1, 1); // Assuming the challenge started on January 1st, 2024
    final difference = now.difference(startDate).inDays;
    return (difference ~/ 7) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return _userData == null
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            backgroundColor: AppColors.cream,
            body: CustomScrollView(
              slivers: [
                // Profile Header
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.forestGreen,
                            AppColors.forestGreen.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      key: ValueKey('profile-${_userData!.profileImageUrl ?? 'no-image'}'),
                                      radius: 50,
                                      backgroundColor: Colors.white,
                                      backgroundImage: null,
                                      child: _userData!.profileImageUrl == null
                                          ? Text(
                                              _userData!.name.isNotEmpty
                                                  ? _userData!.name[0].toUpperCase()
                                                  : 'A',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (_userData!.profileImageUrl != null)
                                      Positioned.fill(
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            key: ValueKey(_imageRefreshKey),
                                            imageUrl: _userData!.profileImageUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            errorWidget: (context, url, error) => Center(
                                              child: Icon(Icons.error, color: Colors.red, size: 32),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (_isUpdatingProfileImage)
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadProfileImage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _userData!.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _editName,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_userData!.bio != null) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  _userData!.bio!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Stats Cards
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Done',
                                _userData!.portraitsCompleted.toString(),
                                AppColors.forestGreen,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Left',
                                (100 - _userData!.portraitsCompleted).toString(),
                                AppColors.rustyOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Portraits Grid
                Consumer<PortraitProvider>(
                  builder: (context, portraitProvider, child) {
                    return StreamBuilder<List<PortraitModel>>(
                      stream: portraitProvider.getUserPortraitsReversed(widget.userId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: Text('Error: ${snapshot.error}'),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const SliverToBoxAdapter(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final portraits = snapshot.data!;
                        _lastPortraitCount = portraits.length;

                        if (portraits.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_library,
                                    size: 64,
                                    color: AppColors.forestGreen.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No portraits yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppColors.forestGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final portrait = portraits[index];
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => PortraitDetailsDialog(
                                        portrait: portrait,
                                        user: _userData,
                                        currentUserId: widget.userId,
                                        onPortraitModified: () {
                                          setState(() {});
                                        },
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: portrait.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: portraits.length,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.forestGreen.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editName() {
    final TextEditingController nameController = TextEditingController(text: _userData?.name ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await _userService.updateUserProfile(
                    userId: widget.userId,
                    name: newName,
                  );
                  await _loadUserData();
                  // Also reload user data in the auth provider to notify other screens
                  await Provider.of<AuthProvider>(context, listen: false).reloadUserData();
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update name: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String? _getProfileImageUrl(String? originalUrl) {
    if (originalUrl == null) return null;
    print('=== PROFILE IMAGE URL DEBUG ===');
    print('Original URL: $originalUrl');
    // If it's already using the new folder structure, return as is
    if (originalUrl.contains('profile-images/')) {
      print('Using new URL (profile-images): $originalUrl');
      return originalUrl;
    }
    // If it's using the old flat structure, convert to new nested structure
    if (originalUrl.contains('profile_pictures/')) {
      final fileName = originalUrl.split('/').last;
      final newUrl = originalUrl.replaceAll('profile_pictures/', 'profile-images/${widget.userId}/');
      print('Converting old URL to new structure:');
      print('  Old: $originalUrl');
      print('  New: $newUrl');
      print('  User ID: ${widget.userId}');
      return newUrl;
    }
    print('Using original URL (no conversion): $originalUrl');
    return originalUrl;
  }
} 