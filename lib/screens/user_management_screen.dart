import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../services/portrait_service.dart';
import '../models/user_model.dart';
import '../models/portrait_model.dart';
import '../models/upgrade_request_model.dart';
import '../theme/app_theme.dart';
import 'dart:io';

class UserManagementScreen extends StatefulWidget {
  final int initialTab;
  const UserManagementScreen({super.key, this.initialTab = 0});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final PortraitService _portraitService = PortraitService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _portraitsCompletedController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _portraitsCompletedController.dispose();
    super.dispose();
  }

  Future<void> _createTestUser() async {
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty ||
        _portraitsCompletedController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final portraitsCompleted = int.tryParse(_portraitsCompletedController.text);
    if (portraitsCompleted == null || portraitsCompleted < 0 || portraitsCompleted > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Portraits completed must be a number between 0 and 100'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a test user with a unique ID
      final testUserId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      
      final testUser = UserModel(
        id: testUserId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        userRole: 'artist', // Default test users to artist role
        portraitsCompleted: portraitsCompleted,
        createdAt: DateTime.now(),
        portraitIds: [], // Empty list for new test users
      );

      await _userService.createUser(testUser);

      // Clear the form
      _nameController.clear();
      _emailController.clear();
      _portraitsCompletedController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test user "${testUser.name}" created successfully!'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating test user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAllTestUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Test Users'),
        content: const Text('Are you sure you want to delete all test users? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get all users and delete test users
      final allUsers = await _userService.getAllUsers().first;
      final testUsers = allUsers.where((user) => user.id.startsWith('test_')).toList();
      
      for (final testUser in testUsers) {
        await _userService.deleteUser(testUser.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${testUsers.length} test users'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting test users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addSamplePortraitsForTestUser(UserModel testUser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sample Portraits'),
        content: Text('Add sample portraits for "${testUser.name}"? This will create ${testUser.portraitsCompleted} sample portraits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.forestGreen),
            child: const Text('Add Portraits'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create sample portraits for the test user
      for (int week = 1; week <= testUser.portraitsCompleted; week++) {
        await _portraitService.addPortrait(
          userId: testUser.id,
          imageUrl: 'https://via.placeholder.com/400x400/forestgreen/white?text=Sample+$week',
          title: 'Sample Portrait Week $week',
          description: 'This is a sample portrait created for testing purposes.',
          weekNumber: week,
          modelName: 'Sample Model',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${testUser.portraitsCompleted} sample portraits for "${testUser.name}"'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding sample portraits: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.userData;
    final isAdmin = currentUser?.isAdmin ?? false;
    final isModerator = currentUser?.isModerator ?? false;

    // Determine tabs and tab views based on role
    final tabs = <Tab>[];
    final tabViews = <Widget>[];

    // Users tab (no badge)
    tabs.add(
      const Tab(
        child: Text('Users', style: TextStyle(fontSize: 11)),
      ),
    );
    tabViews.add(_buildUsersTab());

    // Test Users tab (no badge, only for admin)
    if (isAdmin) {
      tabs.add(
        const Tab(
          child: Text('Test Users', style: TextStyle(fontSize: 11)),
        ),
      );
      tabViews.add(_buildTestUsersTab());
    }

    // Approvals tab (badge with count)
    tabs.add(
      Tab(
        child: StreamBuilder<List<UserModel>>(
          stream: _userService.getAllUsers(),
          builder: (context, snapshot) {
            final allUsers = snapshot.data ?? [];
            final pendingUsers = allUsers.where((user) => user.status == 'pending' && !user.id.startsWith('test_')).toList();
            final count = pendingUsers.length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Approvals', style: TextStyle(fontSize: 11)),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
    tabViews.add(_buildApprovalsTab());

    // Upgrades tab (badge with count)
    tabs.add(
      Tab(
        child: StreamBuilder<List<UpgradeRequestModel>>(
          stream: _userService.getPendingUpgradeRequests(),
          builder: (context, snapshot) {
            final pendingRequests = snapshot.data ?? [];
            final count = pendingRequests.length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Upgrades', style: TextStyle(fontSize: 11)),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
    tabViews.add(_buildUpgradeRequestsTab());

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          bottom: TabBar(
            tabs: tabs,
            indicatorColor: AppColors.rustyOrange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        backgroundColor: AppColors.cream,
        body: Container(
          color: AppColors.cream,
          child: TabBarView(
            children: tabViews,
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            color: AppColors.lightCream,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: AppColors.forestGreen, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Real Users',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage registered users and their admin status',
                    style: TextStyle(color: AppColors.forestGreen.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Real Users List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registered Users',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<UserModel>>(
                    stream: _userService.getAllUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allUsers = snapshot.data!;
                      final realUsers = allUsers.where((user) => !user.id.startsWith('test_')).toList();

                      if (realUsers.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No real users found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: realUsers.length,
                        itemBuilder: (context, index) {
                          final user = realUsers[index];
                          final currentUser = Provider.of<AuthProvider>(context, listen: false).userData;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).pushNamed('/profile', arguments: user.id);
                              },
                              leading: CircleAvatar(
                                backgroundColor: user.isAdmin ? AppColors.rustyOrange : AppColors.forestGreen,
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(user.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.email),
                                  Row(
                                    children: [
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
                                      if (user.isModerator) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.purple.shade300),
                                          ),
                                          child: const Text(
                                            'MODERATOR',
                                            style: TextStyle(
                                              color: Colors.purple,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (user.isAdmin) ...[
                                        const SizedBox(width: 6),
                                        Container(
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
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Moderator toggle (only for admins, not for self or other admins)
                                  if (currentUser != null && currentUser.isAdmin && !user.isAdmin && user.id != currentUser.id)
                                    Switch(
                                      value: user.isModerator,
                                      activeColor: Colors.purple,
                                      onChanged: (value) async {
                                        try {
                                          await _userService.updateUser(user.id, {'isModerator': value});
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(value ? 'Granted moderator to "${user.name}"' : 'Removed moderator from "${user.name}"'),
                                                backgroundColor: AppColors.forestGreen,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error updating moderator status: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  // Delete button (only for non-admin users)
                                  if (!user.isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete User'),
                                            content: Text('Are you sure you want to delete "${user.name}"? This action cannot be undone.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          try {
                                            await _userService.deleteUser(user.id);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Deleted user "${user.name}"'),
                                                  backgroundColor: AppColors.forestGreen,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error deleting user: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildTestUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            color: AppColors.lightCream,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: AppColors.forestGreen, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Test Users',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create and manage test users for development',
                    style: TextStyle(color: AppColors.forestGreen.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Create Test User Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Test User',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portraitsCompletedController,
                    decoration: const InputDecoration(
                      labelText: 'Portraits Completed (0-100) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createTestUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create Test User'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Test Users List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Test Users',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isLoading ? null : _deleteAllTestUsers,
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text('Delete All', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<UserModel>>(
                    stream: _userService.getAllUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allUsers = snapshot.data!;
                      final testUsers = allUsers.where((user) => user.id.startsWith('test_')).toList();

                      if (testUsers.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No test users found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: testUsers.length,
                        itemBuilder: (context, index) {
                          final user = testUsers[index];
                          final currentUser = Provider.of<AuthProvider>(context, listen: false).userData;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.rustyOrange,
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(user.name),
                              subtitle: Text('${user.portraitsCompleted} portraits completed'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Add Portraits button
                                  IconButton(
                                    icon: const Icon(Icons.add_a_photo, color: AppColors.forestGreen),
                                    onPressed: _isLoading ? null : () => _addSamplePortraitsForTestUser(user),
                                    tooltip: 'Add Sample Portraits',
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete User'),
                                          content: Text('Are you sure you want to delete "${user.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        try {
                                          await _userService.deleteUser(user.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Deleted user "${user.name}"'),
                                                backgroundColor: AppColors.forestGreen,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error deleting user: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildApprovalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            color: AppColors.lightCream,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pending_actions, color: AppColors.forestGreen, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Pending Approvals',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review and approve new user registrations',
                    style: TextStyle(color: AppColors.forestGreen.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pending Users List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Users Awaiting Approval',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<UserModel>>(
                    stream: _userService.getAllUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allUsers = snapshot.data!;
                      final pendingUsers = allUsers.where((user) => 
                        user.status == 'pending' && !user.id.startsWith('test_')
                      ).toList();

                      if (pendingUsers.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No pending approvals',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'All users have been reviewed',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingUsers.length,
                        itemBuilder: (context, index) {
                          final user = pendingUsers[index];
                          final currentUser = Provider.of<AuthProvider>(context, listen: false).userData;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(user.name),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Email: ${user.email}'),
                                        const SizedBox(height: 8),
                                        Text('Status: ${user.status}'),
                                        if (user.status == 'approved')
                                          TextButton.icon(
                                            icon: const Icon(Icons.person),
                                            label: const Text('View Profile'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pushNamed('/profile', arguments: user.id);
                                            },
                                          ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: AppColors.forestGreen,
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(user.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.email),
                                  Text('Registered: ${_formatDate(user.createdAt)}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Approve button
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: _isLoading ? null : () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Approve User'),
                                          content: Text('Are you sure you want to approve "${user.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.green),
                                              child: const Text('Approve'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        try {
                                          await _userService.approveUser(user.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Approved "${user.name}"'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error approving user: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    tooltip: 'Approve User',
                                  ),
                                  // Deny button
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: _isLoading ? null : () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Deny User'),
                                          content: Text('Are you sure you want to deny "${user.name}"? This action cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('Deny'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        try {
                                          await _userService.denyUser(user.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Denied "${user.name}"'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error denying user: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    tooltip: 'Deny User',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildUpgradeRequestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            color: AppColors.lightCream,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.upgrade, color: AppColors.forestGreen, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Artist Upgrade Requests',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review requests from art appreciators to become artists',
                    style: TextStyle(color: AppColors.forestGreen.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Upgrade Requests List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Upgrade Requests',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<UpgradeRequestModel>>(
                    stream: _userService.getPendingUpgradeRequests(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final pendingRequests = snapshot.data!;

                      if (pendingRequests.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No pending upgrade requests',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'All upgrade requests have been reviewed',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingRequests.length,
                        itemBuilder: (context, index) {
                          final request = pendingRequests[index];
                          final currentUser = Provider.of<AuthProvider>(context, listen: false).userData;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(request.userName),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Email: ${request.userEmail}'),
                                        const SizedBox(height: 8),
                                        Text('Requested: ${_formatDate(request.requestedAt)}'),
                                        TextButton.icon(
                                          icon: const Icon(Icons.person),
                                          label: const Text('View Profile'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pushNamed('/profile', arguments: request.userId);
                                          },
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(
                                  Icons.upgrade,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(request.userName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(request.userEmail),
                                  Text('Requested: ${_formatDate(request.requestedAt)}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Approve button
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: _isLoading ? null : () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Approve Upgrade'),
                                          content: Text('Are you sure you want to approve "${request.userName}" to become an artist?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.green),
                                              child: const Text('Approve'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        try {
                                          await _userService.approveUpgradeRequest(
                                            requestId: request.id,
                                            adminId: currentUser?.id ?? '',
                                            adminName: currentUser?.name ?? 'Admin',
                                          );
                                          
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Approved "${request.userName}" as artist'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error approving upgrade: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    tooltip: 'Approve Upgrade',
                                  ),
                                  // Deny button
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: _isLoading ? null : () async {
                                      final reasonController = TextEditingController();
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Deny Upgrade'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('Are you sure you want to deny "${request.userName}"?'),
                                              const SizedBox(height: 16),
                                              TextField(
                                                controller: reasonController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Reason for denial (optional)',
                                                  border: OutlineInputBorder(),
                                                ),
                                                maxLines: 2,
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('Deny'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        try {
                                          await _userService.denyUpgradeRequest(
                                            requestId: request.id,
                                            adminId: currentUser?.id ?? '',
                                            adminName: currentUser?.name ?? 'Admin',
                                            reason: reasonController.text.trim(),
                                          );
                                          
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Denied "${request.userName}" upgrade'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error denying upgrade: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    tooltip: 'Deny Upgrade',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
} 