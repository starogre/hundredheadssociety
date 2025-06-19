import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../services/user_service.dart';
import '../services/portrait_service.dart';
import '../models/user_model.dart';
import '../models/portrait_model.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/portrait_details_dialog.dart';

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
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.forestGreen.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Gallery',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'See what other artists are creating',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.forestGreen.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.rustyOrange,
            unselectedLabelColor: AppColors.forestGreen.withValues(alpha: 0.7),
            indicatorColor: AppColors.rustyOrange,
            tabs: const [
              Tab(text: 'Artists'),
              Tab(text: 'Recent Portraits'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildArtistsTab(),
                _buildRecentPortraitsTab(),
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
              hintText: 'Search artists...',
              prefixIcon: const Icon(Icons.search),
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
                      Icon(
                        Icons.people,
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
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
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user.bio != null) ...[
                            Text(
                              user.bio!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ],
                        ],
                      ),
                      trailing: null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: user.id),
                          ),
                        );
                      },
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
    return StreamBuilder<List<PortraitModel>>(
      stream: _portraitService.getAllPortraits(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading portraits: ${snapshot.error}',
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

        final portraits = snapshot.data!;

        if (portraits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library,
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
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => PortraitDetailsDialog(portrait: portrait, user: user),
                    );
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
                              child: Icon(
                                Icons.error,
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
                              Text(
                                portrait.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.forestGreen,
                                    child: Text(
                                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user?.name ?? 'Anonymous',
                                      style: TextStyle(
                                        color: AppColors.forestGreen.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
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
  }
} 