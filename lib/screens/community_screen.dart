import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:async';
import '../services/user_service.dart';
import '../services/portrait_service.dart';
import '../services/block_service.dart';
import '../models/user_model.dart';
import '../models/portrait_model.dart';
import '../models/model_model.dart';
import '../providers/auth_provider.dart';
import '../providers/model_provider.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/portrait_details_dialog.dart';
import '../utils/milestone_utils.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final PortraitService _portraitService = PortraitService();
  final BlockService _blockService = BlockService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _modelNameFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0); // Start on Recent tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.rustyOrange,
            unselectedLabelColor: AppColors.forestGreen.withValues(alpha: 0.7),
            indicatorColor: AppColors.rustyOrange,
            indicatorWeight: 3,
            dividerColor: AppColors.forestGreen.withValues(alpha: 0.2),
            tabs: const [
              Tab(text: 'Recent Portraits'),
              Tab(text: 'Members'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
                          children: [
              _buildRecentPortraitsTab(),
              _buildArtistsTab(),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: PhosphorIcon(PhosphorIconsDuotone.magnifyingGlass),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Artists List
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _searchQuery.isEmpty
                ? _userService.getAllUsers()
                : _userService.searchUsers(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              List<UserModel> users = snapshot.data!;

              if (users.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsDuotone.users,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No artists found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: user.id),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: user.profileImageUrl != null
                                  ? CachedNetworkImageProvider(user.profileImageUrl!)
                                  : null,
                              child: user.profileImageUrl == null
                                  ? Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : 'A',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  user.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                // Milestone badge
                                                if (MilestoneUtils.getMilestoneEmoji(user.portraitsCompleted) != null) ...[
                                                  const SizedBox(width: 4),
                                                  Tooltip(
                                                    message: '${user.portraitsCompleted} Portraits Milestone',
                                                    child: Text(
                                                      MilestoneUtils.getMilestoneEmoji(user.portraitsCompleted)!,
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            // Role Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: user.isArtist 
                                                    ? Colors.blue.shade100 
                                                    : Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: user.isArtist 
                                                      ? Colors.blue.shade300 
                                                      : Colors.green.shade300,
                                                ),
                                              ),
                                              child: Text(
                                                user.isArtist ? 'Artist' : 'Appreciator',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: user.isArtist 
                                                      ? Colors.blue.shade700 
                                                      : Colors.green.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${user.portraitsCompleted}',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (user.bio != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      user.bio!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPortraitsTab() {
    return Column(
      children: [
        // Model Name Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search for artist or model',
              prefixIcon: PhosphorIcon(PhosphorIconsDuotone.magnifyingGlass),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _modelNameFilter = value.trim();
              });
            },
          ),
        ),
        Expanded(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final currentUser = authProvider.currentUser;
              
              if (currentUser == null) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // Get blocked users streams
              return StreamBuilder<List<String>>(
                stream: _blockService.getBlockedUsers(currentUser.uid),
                builder: (context, blockedSnapshot) {
                  return StreamBuilder<List<String>>(
                    stream: _blockService.getBlockedByUsers(currentUser.uid),
                    builder: (context, blockedBySnapshot) {
                      final blockedUsers = blockedSnapshot.data ?? [];
                      final blockedByUsers = blockedBySnapshot.data ?? [];
                      final allBlockedUsers = [...blockedUsers, ...blockedByUsers];
                      
                      return StreamBuilder<List<PortraitModel>>(
                        stream: _portraitService.getAllPortraits(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading portraits: \\${snapshot.error}',
                                style: TextStyle(color: AppColors.rustyOrange),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.rustyOrange),
                              ),
                            );
                          }

                          final allPortraits = snapshot.data!;
                          
                          // Filter out blocked users' portraits
                          final nonBlockedPortraits = allPortraits.where((p) => 
                            !allBlockedUsers.contains(p.userId)
                          ).toList();
                          
                          // Then filter by model name
                          final portraits = _modelNameFilter.isEmpty
                              ? nonBlockedPortraits
                              : nonBlockedPortraits.where((p) => 
                                  (p.modelName ?? '').toLowerCase().contains(_modelNameFilter.toLowerCase())
                                ).toList();

              if (portraits.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsDuotone.images,
                        size: 64,
                        color: AppColors.forestGreen.withValues(alpha: 0.5),
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
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to share a portrait!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.forestGreen.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: portraits.length,
                itemBuilder: (context, index) {
                  final portrait = portraits[index];
                  return FutureBuilder<UserModel?>(
                    future: _userService.getUserById(portrait.userId),
                    builder: (context, userSnapshot) {
                      final user = userSnapshot.data;
                      
                      // Filter by both model name and artist name
                      if (_modelNameFilter.isNotEmpty && user != null) {
                        final artistMatch = user.name.toLowerCase().contains(_modelNameFilter.toLowerCase());
                        final modelMatch = (portrait.modelName ?? '').toLowerCase().contains(_modelNameFilter.toLowerCase());
                        if (!artistMatch && !modelMatch) {
                          return const SizedBox.shrink(); // Hide this item
                        }
                      }
                      return GestureDetector(
                        onTap: () {
                          final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
                          if (currentUser != null) {
                            showDialog(
                              context: context,
                              builder: (context) => PortraitDetailsDialog(
                                portrait: portrait, 
                                user: user,
                                currentUserId: currentUser.uid,
                                onPortraitModified: () {
                                  setState(() {});
                                },
                              ),
                            );
                          }
                        },
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 4/3,
                                child: CachedNetworkImage(
                                  imageUrl: portrait.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.forestGreen.withValues(alpha: 0.1),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.rustyOrange),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppColors.forestGreen.withValues(alpha: 0.1),
                                    child: PhosphorIcon(
                                      PhosphorIconsDuotone.warningCircle,
                                      color: AppColors.rustyOrange,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: AppColors.forestGreen.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Artist section - most prominent at top
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.forestGreen,
                                          backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                                              ? NetworkImage(user.profileImageUrl!)
                                              : null,
                                          child: (user?.profileImageUrl == null || user!.profileImageUrl!.isEmpty)
                                              ? Text(
                                                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user?.name ?? 'Anonymous',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.forestGreen,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (user != null) ...[
                                                const SizedBox(height: 2),
                                                // Role Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: user.isArtist 
                                                        ? Colors.blue.shade100 
                                                        : Colors.green.shade100,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: user.isArtist 
                                                          ? Colors.blue.shade300 
                                                          : Colors.green.shade300,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    user.isArtist ? 'Artist' : 'Appreciator',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: user.isArtist 
                                                          ? Colors.blue.shade700 
                                                          : Colors.green.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Model section - below artist
                                    if (portrait.modelName != null && portrait.modelName!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Consumer<ModelProvider>(
                                        builder: (context, modelProvider, child) {
                                          return StreamBuilder<List<ModelModel>>(
                                            stream: modelProvider.getModels(),
                                            builder: (context, snapshot) {
                                              ModelModel? model;
                                              if (snapshot.hasData) {
                                                model = snapshot.data!.firstWhere(
                                                  (m) => m.name.toLowerCase() == portrait.modelName!.toLowerCase(),
                                                  orElse: () => ModelModel(
                                                    id: '',
                                                    name: portrait.modelName!,
                                                    date: DateTime.now(),
                                                    isActive: true,
                                                    createdAt: DateTime.now(),
                                                    updatedAt: DateTime.now(),
                                                  ),
                                                );
                                              }
                                              
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      // Model image
                                                      Container(
                                                        width: 28,
                                                        height: 28,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(14),
                                                          border: Border.all(color: AppColors.forestGreen, width: 1.5),
                                                        ),
                                                        child: model?.imageUrl != null
                                                            ? ClipRRect(
                                                                borderRadius: BorderRadius.circular(12.5),
                                                                child: Image.network(
                                                                  model!.imageUrl!,
                                                                  width: 28,
                                                                  height: 28,
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return Container(
                                                                      decoration: BoxDecoration(
                                                                        color: AppColors.forestGreen,
                                                                        borderRadius: BorderRadius.circular(12.5),
                                                                      ),
                                                                      child: PhosphorIcon(
                                                                        PhosphorIconsDuotone.user,
                                                                        color: Colors.white,
                                                                        size: 14,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              )
                                                            : Container(
                                                                decoration: BoxDecoration(
                                                                  color: AppColors.forestGreen,
                                                                  borderRadius: BorderRadius.circular(12.5),
                                                                ),
                                                                child: const Icon(
                                                                  Icons.person,
                                                                  color: Colors.white,
                                                                  size: 14,
                                                                ),
                                                              ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      // Model name
                                                      Expanded(
                                                        child: Text(
                                                          portrait.modelName!,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: AppColors.forestGreen,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  // Model date - smaller and below
                                                  if (model != null) ...[
                                                    const SizedBox(height: 4),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 36),
                                                      child: Text(
                                                        'Modeled ${_formatDate(model.date)}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors.forestGreen.withValues(alpha: 0.6),
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
} 