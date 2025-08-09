import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/portrait_provider.dart';
import '../providers/notification_provider.dart';
import '../models/portrait_model.dart';
import '../models/user_model.dart';
import '../widgets/portrait_slot.dart';
import '../widgets/add_portrait_dialog.dart';
import '../widgets/portrait_details_dialog.dart';
import '../widgets/notification_badge.dart';
import '../services/user_service.dart';
import '../services/portrait_service.dart';
import '../services/push_notification_service.dart';
import '../widgets/notification_permission_dialog.dart';
import 'profile_screen.dart';
import 'community_screen.dart';
import '../theme/app_theme.dart';
import 'add_portrait_screen.dart';
import 'weekly_sessions_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final PortraitService _portraitService = PortraitService();

  @override
  void initState() {
    super.initState();
    // Fix week gaps when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fixWeekGaps();
      _initializeNotifications();
    });
  }

  void _initializeNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Get the notification provider from the local context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        notificationProvider.initializeNotifications(authProvider.currentUser!.uid);
        
        // Request notification permissions
        _requestNotificationPermissions();
      }
    });
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      // Check if we've already asked for permission
      final prefs = await SharedPreferences.getInstance();
      final hasAskedForPermission = prefs.getBool('has_asked_notification_permission') ?? false;
      
      if (hasAskedForPermission) {
        // We've already asked, just initialize the service
        final pushNotificationService = PushNotificationService();
        await pushNotificationService.initialize();
        return;
      }
      
      // Show custom permission dialog first
      if (mounted) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const NotificationPermissionDialog(),
        );
        
        // Mark that we've asked for permission
        await prefs.setBool('has_asked_notification_permission', true);
        
        if (shouldRequest == true) {
          // User clicked "Allow Notifications"
          final pushNotificationService = PushNotificationService();
          await pushNotificationService.initialize();
        }
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> _fixWeekGaps() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        await _portraitService.fixWeekGaps(authProvider.currentUser!.uid);
      }
    } catch (e) {
      debugPrint('Error fixing week gaps: $e');
    }
  }

  Future<void> _renumberPortraits() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        await _portraitService.renumberPortraitsSequentially(authProvider.currentUser!.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portraits renumbered successfully!'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error renumbering portraits: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Get user data and determine available tabs based on role
        final userData = authProvider.userData;
        final isArtAppreciator = userData?.isArtAppreciator ?? true;
        
        // Determine available tabs based on user role
        List<Widget> availableTabs = [];
        List<BottomNavigationBarItem> navigationItems = [];
        
        if (isArtAppreciator) {
          // Art appreciators only see Community and Profile
          availableTabs = [
            const CommunityScreen(),
            ProfileScreen(userId: authProvider.currentUser!.uid),
          ];
          navigationItems = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Community',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];
        } else {
          // Artists see all tabs
          availableTabs = [
            _buildDashboardTab(authProvider),
            const CommunityScreen(),
            ProfileScreen(userId: authProvider.currentUser!.uid),
            const WeeklySessionsScreen(),
          ];
          navigationItems = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'My Heads',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Community',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.event),
              label: 'Weekly Sessions',
            ),
          ];
        }

        // Determine AppBar title and actions based on selected tab
        String appBarTitle = '';
        List<Widget> appBarActions = [];
        
        // Add notification badge to all tabs
        appBarActions.add(
          NotificationBadge(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        );
        
        if (isArtAppreciator) {
          if (_selectedIndex == 0) {
            appBarTitle = 'Community';
          } else if (_selectedIndex == 1) {
            appBarTitle = userData?.name ?? 'Profile';
            appBarActions.add(
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            );
          }
        } else {
          if (_selectedIndex == 0) {
            appBarTitle = '100 Heads Society';
          } else if (_selectedIndex == 1) {
            appBarTitle = 'Community';
          } else if (_selectedIndex == 2) {
            appBarTitle = userData?.name ?? 'Profile';
            appBarActions.add(
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            );
          } else if (_selectedIndex == 3) {
            appBarTitle = 'Weekly Sessions';
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            actions: appBarActions,
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: availableTabs,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedItemColor: AppColors.rustyOrange,
            unselectedItemColor: AppColors.forestGreen,
            items: navigationItems,
          ),
          floatingActionButton: isArtAppreciator 
              ? null // No FAB for art appreciators
              : _selectedIndex == 0
                  ? FloatingActionButton(
                      onPressed: () => _showAddPortraitDialog(context, authProvider, (authProvider.userData?.portraitsCompleted ?? 0) + 1),
                      backgroundColor: AppColors.rustyOrange,
                      child: const Icon(Icons.add_a_photo),
                    )
                  : null,
        );
      },
    );
  }

  Widget _buildDashboardTab(AuthProvider authProvider) {
    return Consumer<PortraitProvider>(
      builder: (context, portraitProvider, child) => Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.forestGreen.withValues(alpha: 0.1),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.rustyOrange,
                      child: Text(
                        '${authProvider.userData?.portraitsCompleted ?? 0}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${authProvider.userData?.name ?? 'Artist'}!',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${authProvider.userData?.portraitsCompleted ?? 0} of 100 portraits completed',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (authProvider.userData?.portraitsCompleted ?? 0) / 100,
                            backgroundColor: AppColors.cream,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.rustyOrange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Grid of 100 slots
          Expanded(
            child: StreamBuilder<List<PortraitModel>>(
              stream: portraitProvider.getUserPortraits(authProvider.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48, color: AppColors.rustyOrange),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading portraits',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.rustyOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Trigger a refresh
                            portraitProvider.refreshPortraits();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                List<PortraitModel> portraits = snapshot.data!;
                int completedCount = portraits.length;

                // Create a map for O(1) lookup instead of O(n) search for each item
                Map<int, PortraitModel> portraitMap = {};
                try {
                  portraitMap = {
                    for (var portrait in portraits) portrait.weekNumber: portrait
                  };
                } catch (e) {
                  debugPrint('Error creating portrait map: $e');
                  // Return error state if there's an issue with the data
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48, color: AppColors.rustyOrange),
                        const SizedBox(height: 16),
                        const Text(
                          'Error processing portraits',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Extra bottom padding for FAB
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: (authProvider.userData?.portraitsCompleted ?? 0) >= 100 ? 200 : 100,
                  itemBuilder: (context, index) {
                    int weekNumber = index + 1;
                    PortraitModel? portrait = portraitMap[weekNumber];
                    
                    // Calculate the next available week (first week without a portrait)
                    int nextAvailableWeek = 1;
                    int maxSlots = (authProvider.userData?.portraitsCompleted ?? 0) >= 100 ? 200 : 100;
                    try {
                      for (int i = 1; i <= maxSlots; i++) {
                        if (!portraitMap.containsKey(i)) {
                          nextAvailableWeek = i;
                          break;
                        }
                      }
                    } catch (e) {
                      debugPrint('Error calculating next available week: $e');
                      nextAvailableWeek = 1;
                    }
                    
                    // Only allow tapping if this is the next available week and it's empty
                    bool isUnlocked = weekNumber == nextAvailableWeek && portrait == null;

                    return PortraitSlot(
                      weekNumber: weekNumber,
                      portrait: portrait,
                      isCompleted: portrait != null,
                      onTap: portrait != null
                          ? () => _showPortraitDetails(context, portrait)
                          : isUnlocked 
                              ? () => _showAddPortraitDialog(context, authProvider, weekNumber)
                              : null, // Disable tapping for locked weeks
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPortraitDialog(BuildContext context, AuthProvider authProvider, int weekNumber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPortraitScreen(
          userId: authProvider.currentUser!.uid,
          nextWeekNumber: weekNumber,
        ),
      ),
    );
  }

  void _showPortraitDetails(BuildContext context, PortraitModel portrait) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userService = UserService();
    
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<UserModel?>(
        future: userService.getUserById(portrait.userId),
        builder: (context, userSnapshot) {
          return PortraitDetailsDialog(
            portrait: portrait,
            user: userSnapshot.data,
            currentUserId: authProvider.currentUser!.uid,
            onPortraitModified: () {
              // The streams will automatically update when Firestore data changes
              // No need to manually refresh
            },
          );
        },
      ),
    );
  }
} 