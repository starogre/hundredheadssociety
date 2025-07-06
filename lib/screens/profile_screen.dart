import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
  bool _justSubmittedUpgradeRequest = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG: ProfileScreen initState called for userId: ${widget.userId}');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('DEBUG: Loading user data for userId: ${widget.userId}');
      final userData = await _userService.getUserById(widget.userId);
      print('DEBUG: User data loaded: ${userData?.name}, role: ${userData?.userRole}, isArtAppreciator: ${userData?.isArtAppreciator}');
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _requestArtistUpgrade() async {
    print('=== PROFILE SCREEN: Upgrade button clicked ===');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Artist Upgrade'),
        content: const Text(
          'This will send a request to the community managers to upgrade your account to an Artist role. '
          'You\'ll be notified once your request is approved or denied.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('User cancelled upgrade request');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              print('User confirmed upgrade request');
              Navigator.of(context).pop();
              
              try {
                print('Getting current user from AuthProvider...');
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final currentUser = authProvider.currentUser;
                
                if (currentUser == null) {
                  print('ERROR: No current user found');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: No user logged in')),
                  );
                  return;
                }
                
                print('Current user ID: ${currentUser.uid}');
                print('Current user email: ${currentUser.email}');
                print('Current user display name: [38;5;9m${currentUser.displayName}[0m');
                print('Current user Firestore name: ${_userData?.name}');
                
                print('Calling createUpgradeRequest...');
                await _userService.createUpgradeRequest(
                  userId: currentUser.uid,
                  userEmail: currentUser.email ?? '',
                  userName: _userData?.name ?? 'Unknown User',
                );
                
                print('Upgrade request completed successfully');
                setState(() {
                  _justSubmittedUpgradeRequest = true;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade request submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('ERROR in _requestArtistUpgrade: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
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

  PreferredSizeWidget? _buildAppBar() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    // Always show app bar when viewing someone else's profile
    if (currentUser != null && currentUser.uid != widget.userId) {
      return AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        title: Text(_userData?.name ?? 'User'),
        elevation: 0,
      );
    }
    
    // Show app bar for own profile when navigated from other screens
    // Check if we can pop (meaning we navigated here from another screen)
    if (Navigator.of(context).canPop()) {
      return AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        title: const Text('My Profile'),
        elevation: 0,
      );
    }
    
    return null; // No app bar when accessed directly (e.g., from bottom nav)
  }

  @override
  Widget build(BuildContext context) {
    return _userData == null
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            backgroundColor: AppColors.cream,
            appBar: _buildAppBar(),
            body: CustomScrollView(
              slivers: [
                // Profile Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Portrait
                        Stack(
                          children: [
                            CircleAvatar(
                              key: ValueKey('profile-${_userData!.profileImageUrl ?? 'no-image'}'),
                              radius: 40,
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
                            if (_isUpdatingProfileImage)
                              Container(
                                width: 80,
                                height: 80,
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

                          ],
                        ),
                        const SizedBox(width: 20),
                        // Name and contact info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData!.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final viewer = authProvider.userData;
                                  final showBadges = viewer?.isAdmin == true || viewer?.isModerator == true;
                                  if (!showBadges) return const SizedBox.shrink();
                                  return Row(
                                    children: [
                                      if (_userData?.isAdmin == true)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6, right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.rustyOrange,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'ADMIN',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (_userData?.isModerator == true)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6, right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.purple,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'MODERATOR',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              // Instagram
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final currentUser = authProvider.currentUser;
                                  final isOwnProfile = currentUser?.uid == widget.userId;
                                  
                                  // Only show if Instagram is set OR if it's the user's own profile
                                  if (_userData!.instagram?.isNotEmpty != true && !isOwnProfile) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          final handle = _userData!.instagram;
                                          if (handle != null && handle.isNotEmpty) {
                                            final url = handle.startsWith('@')
                                                ? 'https://instagram.com/${handle.substring(1)}'
                                                : 'https://instagram.com/$handle';
                                            await launchUrl(Uri.parse(url));
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Icon(FontAwesomeIcons.instagram, color: AppColors.forestGreen, size: 20),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _userData!.instagram?.isNotEmpty == true
                                                    ? '@${_userData!.instagram!.replaceAll('@', '')}'
                                                    : 'Add Instagram',
                                                style: TextStyle(
                                                  color: AppColors.forestGreen,
                                                  fontSize: 15,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  );
                                },
                              ),
                              // Email
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final currentUser = authProvider.currentUser;
                                  final isOwnProfile = currentUser?.uid == widget.userId;
                                  
                                  // Always show email (either contact email or login email)
                                  return GestureDetector(
                                    onTap: () async {
                                      final email = _userData!.contactEmail ?? _userData!.email;
                                      final url = 'mailto:$email';
                                      await launchUrl(Uri.parse(url));
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.email, color: AppColors.forestGreen, size: 20),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _userData!.contactEmail?.isNotEmpty == true
                                                ? _userData!.contactEmail!
                                                : _userData!.email,
                                            style: TextStyle(
                                              color: AppColors.forestGreen,
                                              fontSize: 15,
                                              decoration: TextDecoration.underline,
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
                      ],
                    ),
                  ),
                ),

                // Art Appreciator Upgrade Request (only show to art appreciators viewing their own profile)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    print('DEBUG: Consumer<AuthProvider> builder called');
                    final currentUser = authProvider.currentUser;
                    print('DEBUG: currentUser: ${currentUser?.uid}');
                    print('DEBUG: _userData: ${_userData?.name}, role: ${_userData?.userRole}, isArtAppreciator: ${_userData?.isArtAppreciator}');
                    
                    if (currentUser == null) {
                      print('DEBUG: No current user found');
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    
                    // Only show to art appreciators viewing their own profile
                    final isOwnProfile = currentUser.uid == widget.userId;
                    final isArtAppreciator = _userData?.isArtAppreciator ?? false;
                    
                    print('DEBUG: Upgrade section - isOwnProfile: $isOwnProfile, isArtAppreciator: $isArtAppreciator');
                    print('DEBUG: currentUser.uid: ${currentUser.uid}, widget.userId: ${widget.userId}');
                    print('DEBUG: _userData?.userRole: ${_userData?.userRole}');
                    print('DEBUG: _userData?.isArtAppreciator: ${_userData?.isArtAppreciator}');
                    
                    if (!isOwnProfile || !isArtAppreciator) {
                      print('DEBUG: Not showing upgrade section - conditions not met');
                      print('DEBUG: !isOwnProfile: ${!isOwnProfile}, !isArtAppreciator: ${!isArtAppreciator}');
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    print('DEBUG: Showing upgrade section');
                    return FutureBuilder<bool>(
                      future: _userService.hasPendingUpgradeRequest(currentUser.uid),
                      builder: (context, snapshot) {
                        final hasPending = snapshot.data ?? false;
                        final shouldDisable = hasPending || _justSubmittedUpgradeRequest;
                        print('DEBUG: hasPending: $hasPending, _justSubmittedUpgradeRequest: $_justSubmittedUpgradeRequest, shouldDisable: $shouldDisable');
                        
                        return SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.brush,
                                      color: Colors.orange.shade700,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Want to Create Art?',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Upgrade to an Artist account to create and submit your own portraits, participate in weekly sessions, and join the full 100 Heads Society experience.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (shouldDisable)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.hourglass_top, color: Colors.orange.shade700),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'You have already submitted an upgrade request. Please wait for review.',
                                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () {
                                      print('DEBUG: Upgrade button clicked!');
                                      print('DEBUG: About to call _requestArtistUpgrade');
                                      _requestArtistUpgrade();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Request Artist Upgrade'),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Edit Profile Button (only show to profile owner or admin for test users)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final currentUser = authProvider.currentUser;
                    if (currentUser == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
                    
                    // Check if current user can edit this profile
                    final canEdit = currentUser.uid == widget.userId || 
                        (widget.userId.startsWith('test_') && authProvider.userData?.isAdmin == true);
                    
                    if (!canEdit) return const SliverToBoxAdapter(child: SizedBox.shrink());
                    
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: _showEditProfileDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Edit Profile'),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Stats Cards (only show for artists or when viewing own profile)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final currentUser = authProvider.currentUser;
                    final isOwnProfile = currentUser?.uid == widget.userId;
                    final isArtist = _userData?.isArtist ?? false;
                    
                    // Show stats for artists or when viewing own profile
                    if (isArtist || isOwnProfile) {
                      return SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Done',
                                  _userData!.portraitsCompleted.toString(),
                                  AppColors.forestGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Left',
                                  (100 - _userData!.portraitsCompleted).toString(),
                                  AppColors.rustyOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // For art appreciators viewing other profiles, show limited info
                      return SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Art Appreciator Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'This user is an art appreciator. Only basic profile information is displayed.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),

                // Portraits Grid (only show for artists or when viewing own profile)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final currentUser = authProvider.currentUser;
                    final isOwnProfile = currentUser?.uid == widget.userId;
                    final isArtist = _userData?.isArtist ?? false;
                    
                    // Only show portraits for artists or when viewing own profile
                    if (!isArtist && !isOwnProfile) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    
                    return Consumer<PortraitProvider>(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
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

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Picture Section
              const Text(
                'Profile Picture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Show current profile picture
              if (_userData!.profileImageUrl != null)
                CircleAvatar(
                  radius: 30,
                  backgroundImage: CachedNetworkImageProvider(_userData!.profileImageUrl!),
                )
              else
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    _userData!.name.isNotEmpty ? _userData!.name[0].toUpperCase() : 'A',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickAndUploadProfileImage();
                },
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Change Picture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
              const SizedBox(height: 20),
              
              // Name Section
              const Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Show current name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _userData!.name.isNotEmpty ? _userData!.name : 'No name set',
                  style: TextStyle(
                    fontSize: 16,
                    color: _userData!.name.isNotEmpty ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _editName();
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Name'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
              const SizedBox(height: 20),
              
              // Instagram Section
              const Text(
                'Instagram Handle',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Show current Instagram handle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.instagram, color: AppColors.forestGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _userData!.instagram?.isNotEmpty == true
                          ? '@${_userData!.instagram!.replaceAll('@', '')}'
                          : 'No Instagram handle set',
                      style: TextStyle(
                        fontSize: 16,
                        color: _userData!.instagram?.isNotEmpty == true ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final newHandle = await _showEditDialog(
                    context,
                    title: 'Edit Instagram',
                    initialValue: _userData!.instagram ?? '',
                    hintText: 'Enter Instagram handle',
                    prefixText: '@',
                  );
                  if (newHandle != null) {
                    await _userService.updateUserProfile(
                      userId: widget.userId,
                      instagram: newHandle,
                    );
                    await _loadUserData();
                  }
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Instagram'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
              const SizedBox(height: 20),
              
              // Email Section
              const Text(
                'Contact Email',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Show current email
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: AppColors.forestGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _userData!.contactEmail?.isNotEmpty == true
                            ? _userData!.contactEmail!
                            : _userData!.email,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final newEmail = await _showEditDialog(
                    context,
                    title: 'Edit Contact Email',
                    initialValue: _userData!.contactEmail ?? _userData!.email,
                    hintText: 'Enter contact email',
                  );
                  if (newEmail != null) {
                    await _userService.updateUserProfile(
                      userId: widget.userId,
                      contactEmail: newEmail,
                    );
                    await _loadUserData();
                  }
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showEditDialog(BuildContext context, {
    required String title,
    required String initialValue,
    required String hintText,
    String? prefixText,
  }) {
    final TextEditingController controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: hintText,
            prefixText: prefixText,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 