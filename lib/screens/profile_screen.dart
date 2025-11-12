import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../widgets/awards_tab.dart';
import '../utils/milestone_utils.dart';

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

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  UserModel? _userData;
  final ImagePicker _picker = ImagePicker();
  int _lastPortraitCount = 0;
  bool _isUpdatingProfileImage = false;
  int _imageRefreshKey = 0;
  bool _justSubmittedUpgradeRequest = false;
  late TabController _tabController;
  
  // Lazy loading for portraits
  List<PortraitModel> _portraits = [];
  bool _isLoadingPortraits = false;
  bool _hasMorePortraits = true;
  DocumentSnapshot? _lastPortraitDocument;
  static const int _portraitsPerBatch = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
      // Load portraits when switching to portraits tab
      if (_tabController.index == 0 && _portraits.isEmpty) {
        _loadPortraits();
      }
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadPortraits() async {
    if (_isLoadingPortraits || !_hasMorePortraits) return;
    
    if (mounted) {
      setState(() {
        _isLoadingPortraits = true;
      });
    }
    
    try {
      final newPortraits = await _userService.getUserPortraitsPaginated(
        widget.userId,
        limit: _portraitsPerBatch,
        lastDocument: _lastPortraitDocument,
      );
      
      if (mounted) {
        setState(() {
          _portraits.addAll(newPortraits.portraits);
          _lastPortraitDocument = newPortraits.lastDocument;
          _hasMorePortraits = newPortraits.portraits.length == _portraitsPerBatch;
          _isLoadingPortraits = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading portraits: $e');
      if (mounted) {
        setState(() {
          _isLoadingPortraits = false;
        });
      }
    }
  }

  Future<void> _requestArtistUpgrade() async {
          debugPrint('=== PROFILE SCREEN: Upgrade button clicked ===');
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
              debugPrint('User cancelled upgrade request');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint('User confirmed upgrade request');
              Navigator.of(context).pop();
              
              try {
                debugPrint('Getting current user from AuthProvider...');
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final currentUser = authProvider.currentUser;
                
                if (currentUser == null) {
                  debugPrint('ERROR: No current user found');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: No user logged in')),
                  );
                  return;
                }
                
                debugPrint('Current user ID: ${currentUser.uid}');
                debugPrint('Current user email: ${currentUser.email}');
                print('Current user display name: [38;5;9m${currentUser.displayName}[0m');
                debugPrint('Current user Firestore name: ${_userData?.name}');
                
                debugPrint('Calling createUpgradeRequest...');
                await _userService.createUpgradeRequest(
                  userId: currentUser.uid,
                  userEmail: currentUser.email ?? '',
                  userName: _userData?.name ?? 'Unknown User',
                );
                
                debugPrint('Upgrade request completed successfully');
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
                debugPrint('ERROR in _requestArtistUpgrade: $e');
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
                                      child: PhosphorIcon(PhosphorIconsDuotone.warningCircle, color: Colors.red, size: 32),
                                    ),
                                  ),
                                ),
                              ),
                            if (_isUpdatingProfileImage)
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
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
                              Row(
                                children: [
                                  Text(
                                    _userData!.name,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppColors.forestGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Milestone badge
                                  if (MilestoneUtils.getMilestoneEmoji(_userData!.portraitsCompleted) != null) ...[
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: '${_userData!.portraitsCompleted} Portraits Milestone',
                                      child: Text(
                                        MilestoneUtils.getMilestoneEmoji(_userData!.portraitsCompleted)!,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ],
                                ],
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
                                            PhosphorIcon(PhosphorIconsDuotone.instagramLogo, color: AppColors.forestGreen, size: 20),
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
                                        PhosphorIcon(PhosphorIconsDuotone.envelope, color: AppColors.forestGreen, size: 20),
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
          final currentUser = authProvider.currentUser;
                    
                    
                    if (currentUser == null) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    
                    // Only show to art appreciators viewing their own profile
                    final isOwnProfile = currentUser.uid == widget.userId;
                    final isArtAppreciator = _userData?.isArtAppreciator ?? false;
                    
                    if (!isOwnProfile || !isArtAppreciator) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return FutureBuilder<bool>(
                      future: _userService.hasPendingUpgradeRequest(currentUser.uid),
                      builder: (context, snapshot) {
                        final hasPending = snapshot.data ?? false;
                        final shouldDisable = hasPending || _justSubmittedUpgradeRequest;
                        
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
                                    PhosphorIcon(
                                      PhosphorIconsDuotone.paintBrush,
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
                                        PhosphorIcon(PhosphorIconsDuotone.hourglass, color: Colors.orange.shade700),
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
                                  _calculatePortraitsLeft(_userData!.portraitsCompleted).toString(),
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
                                  PhosphorIcon(
                                    PhosphorIconsDuotone.info,
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

                // Milestones Section (only show for artists or when viewing own profile)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final currentUser = authProvider.currentUser;
                    final isOwnProfile = currentUser?.uid == widget.userId;
                    final isArtist = _userData?.isArtist ?? false;
                    
                    // Show milestones for artists or when viewing own profile
                    if (isArtist || isOwnProfile) {
                      List<String> achievedMilestones = MilestoneUtils.getAllMilestoneEmojis(_userData!.portraitsCompleted);
                      int? nextMilestone = MilestoneUtils.getNextMilestone(_userData!.portraitsCompleted);
                      
                      if (achievedMilestones.isNotEmpty) {
                        return SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    PhosphorIcon(
                                      PhosphorIconsDuotone.trophy,
                                      color: Colors.blue.shade700,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Portrait Milestones',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: achievedMilestones.map((emoji) {
                                    // Find the milestone count for this emoji
                                    int milestoneCount = 0;
                                    for (int milestone in MilestoneUtils.milestoneEmojis.keys) {
                                      if (MilestoneUtils.milestoneEmojis[milestone] == emoji) {
                                        milestoneCount = milestone;
                                        break;
                                      }
                                    }
                                    
                                    return Tooltip(
                                      message: MilestoneUtils.getMilestoneDescription(milestoneCount),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade300),
                                        ),
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (nextMilestone != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        PhosphorIcon(
                                          PhosphorIconsDuotone.trendUp,
                                          color: Colors.grey.shade600,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Next: ${MilestoneUtils.getMilestoneDescription(nextMilestone)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),

                // Tab Bar (only show for artists or when viewing own profile)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final currentUser = authProvider.currentUser;
                    final isOwnProfile = currentUser?.uid == widget.userId;
                    final isArtist = _userData?.isArtist ?? false;
                    
                    // Only show tabs for artists or when viewing own profile
                    if (!isArtist && !isOwnProfile) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    
                    return SliverToBoxAdapter(
                      child: Container(
                        color: AppColors.cream,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.forestGreen,
                          unselectedLabelColor: Colors.grey.shade600,
                          indicatorColor: AppColors.forestGreen,
                          indicatorWeight: 3,
                          dividerColor: AppColors.forestGreen.withValues(alpha: 0.2),
                          tabs: const [
                            Tab(
                              icon: PhosphorIcon(PhosphorIconsDuotone.images),
                              text: 'Portraits',
                            ),
                            Tab(
                              icon: PhosphorIcon(PhosphorIconsDuotone.trophy),
                              text: 'Awards',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Portraits Tab Content
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final currentUser = authProvider.currentUser;
                    final isOwnProfile = currentUser?.uid == widget.userId;
                    final isArtist = _userData?.isArtist ?? false;
                    
                    if (!isArtist && !isOwnProfile) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    
                    if (_tabController.index == 0) {
                      // Load initial portraits if needed
                      if (_portraits.isEmpty && !_isLoadingPortraits) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _loadPortraits();
                        });
                      }
                      
                      if (_portraits.isEmpty && _isLoadingPortraits) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      if (_portraits.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  PhosphorIcon(
                                    PhosphorIconsDuotone.images,
                                    size: 64,
                                    color: AppColors.forestGreen,
                                  ),
                                  SizedBox(height: 16),
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
                              // Load more portraits when reaching the end
                              if (index == _portraits.length - 3 && _hasMorePortraits && !_isLoadingPortraits) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _loadPortraits();
                                });
                              }
                              
                              // Show loading indicator at the end
                              if (index == _portraits.length) {
                                if (_hasMorePortraits) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }
                              
                              final portrait = _portraits[index];
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
                                    memCacheWidth: 400,
                                    maxWidthDiskCache: 300,
                                    maxHeightDiskCache: 300,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: PhosphorIcon(
                                        PhosphorIconsDuotone.warningCircle,
                                        color: Colors.grey,
                                        size: 24,
                                      ),
                                    ),
                                    fadeInDuration: const Duration(milliseconds: 200),
                                    fadeOutDuration: const Duration(milliseconds: 200),
                                  ),
                                ),
                              );
                            },
                            childCount: _portraits.length + (_hasMorePortraits ? 1 : 0),
                          ),
                        ),
                      );
                    } else {
                      // Awards Tab
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: AwardsTab(
                            userId: widget.userId,
                            isOwnProfile: currentUser?.uid == widget.userId,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
  }



  Widget _buildAwardsTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isOwnProfile = currentUser?.uid == widget.userId;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AwardsTab(
        userId: widget.userId,
        isOwnProfile: isOwnProfile,
      ),
    );
  }

  // Calculate portraits left to next milestone
  int _calculatePortraitsLeft(int completed) {
    // Calculate next milestone (100, 200, 300, etc.)
    final nextMilestone = ((completed ~/ 100) + 1) * 100;
    return nextMilestone - completed;
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
                color: AppColors.forestGreen.withValues(alpha: 0.7),
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
                icon: PhosphorIcon(PhosphorIconsDuotone.camera, size: 18),
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
                icon: PhosphorIcon(PhosphorIconsDuotone.pencil, size: 18),
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
                    PhosphorIcon(PhosphorIconsDuotone.instagramLogo, color: AppColors.forestGreen, size: 16),
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
                icon: PhosphorIcon(PhosphorIconsDuotone.pencil, size: 18),
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
                    PhosphorIcon(PhosphorIconsDuotone.envelope, color: AppColors.forestGreen, size: 16),
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
                icon: PhosphorIcon(PhosphorIconsDuotone.pencil, size: 18),
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