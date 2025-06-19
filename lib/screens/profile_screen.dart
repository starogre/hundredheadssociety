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
            final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${widget.userId}.jpg');
            await storageRef.putFile(imageFile);
            final imageUrl = await storageRef.getDownloadURL();
            await _userService.updateUserProfile(
              userId: widget.userId,
              profileImageUrl: imageUrl,
            );
            await _loadUserData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update profile picture: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _userData!.profileImageUrl != null
                                      ? CachedNetworkImageProvider(_userData!.profileImageUrl!)
                                      : null,
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
                            Text(
                              _userData!.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
                    color: AppColors.cream,
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_userData!.portraitsCompleted}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.rustyOrange,
                                        ),
                                      ),
                                      Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: AppColors.forestGreen.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.forestGreen.withOpacity(0.2),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${100 - _userData!.portraitsCompleted}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.rustyOrange,
                                        ),
                                      ),
                                      Text(
                                        'Remaining',
                                        style: TextStyle(
                                          color: AppColors.forestGreen.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Progress Bar
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress to 100 Heads',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _userData!.portraitsCompleted / 100,
                                  backgroundColor: AppColors.cream,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.rustyOrange),
                                  minHeight: 8,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_userData!.portraitsCompleted} of 100 portraits completed',
                                  style: TextStyle(
                                    color: AppColors.forestGreen.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Portraits Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Portraits Gallery',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Portraits Grid
                StreamBuilder<List<PortraitModel>>(
                  stream: Provider.of<PortraitProvider>(context, listen: false)
                      .getUserPortraits(widget.userId),
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

                    List<PortraitModel> portraits = snapshot.data!;

                    if (portraits.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.photo_library,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No portraits yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start your journey by adding your first portrait!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final portrait = portraits[index];
                            return GestureDetector(
                              onTap: () => _showPortraitDetails(context, portrait),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: CachedNetworkImage(
                                        imageUrl: portrait.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            portrait.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Week ${portrait.weekNumber}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: portraits.length,
                        ),
                      ),
                    );
                  },
                ),

                // Sign Out Option
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: AppColors.forestGreen.withOpacity(0.7),
                          ),
                          title: Text(
                            'Sign Out',
                            style: TextStyle(
                              color: AppColors.forestGreen.withOpacity(0.7),
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sign Out'),
                                content: const Text('Are you sure you want to sign out?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppColors.forestGreen,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Provider.of<AuthProvider>(context, listen: false).signOut();
                                    },
                                    child: Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        color: AppColors.rustyOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showPortraitDetails(BuildContext context, PortraitModel portrait) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(portrait.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    portrait.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (portrait.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      portrait.description!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Week ${portrait.weekNumber}',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ButtonBar(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 