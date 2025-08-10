import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppUpdatesScreen extends StatelessWidget {
  const AppUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('App Updates'),
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.white,
          bottom: TabBar(
            indicatorColor: AppColors.rustyOrange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Changes'),
              Tab(text: 'Coming Soon'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Changes Tab
            _ChangesTab(),
            // Coming Soon Tab
            _RoadmapTab(),
          ],
        ),
      ),
    );
  }
}

class _ChangesTab extends StatelessWidget {
  const _ChangesTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Recent Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.forestGreen)),
        SizedBox(height: 12),
        // Recent security and user management improvements
        ListTile(
          leading: Icon(Icons.security, color: AppColors.forestGreen),
          title: Text('Enhanced Security & Authentication'),
          subtitle: Text('Added email verification for all users, admin verification on every login, and forgot password functionality.'),
        ),
        ListTile(
          leading: Icon(Icons.swap_horiz, color: AppColors.forestGreen),
          title: Text('Switch Artist to Appreciator'),
          subtitle: Text('Admins can now switch artists back to art appreciators with confirmation dialog.'),
        ),
        ListTile(
          leading: Icon(Icons.history, color: AppColors.forestGreen),
          title: Text('Activity Log System'),
          subtitle: Text('Comprehensive logging of admin and moderator actions including user approvals, role changes, and deletions.'),
        ),
        ListTile(
          leading: Icon(Icons.manage_accounts, color: AppColors.forestGreen),
          title: Text('Improved User Management'),
          subtitle: Text('Compact expandable user cards, better organization of admin actions, and enhanced user role management.'),
        ),
        ListTile(
          leading: Icon(Icons.policy, color: AppColors.forestGreen),
          title: Text('Legal Pages & Website Integration'),
          subtitle: Text('Added Privacy Policy, Terms of Service, Code of Conduct, and links to 100headsociety.com website.'),
        ),
        ListTile(
          leading: Icon(Icons.check_circle, color: AppColors.forestGreen),
          title: Text('User Role Refinements'),
          subtitle: Text('Art appreciators are now auto-approved, only artists require admin approval. Updated approval workflows.'),
        ),
        ListTile(
          leading: Icon(Icons.model_training, color: AppColors.forestGreen),
          title: Text('Model Management System'),
          subtitle: Text('Admins can now add, edit, and delete models with images and dates. Users select models from dropdown instead of typing names.'),
        ),
        ListTile(
          leading: Icon(Icons.design_services, color: AppColors.forestGreen),
          title: Text('Portrait Layout Redesign'),
          subtitle: Text('Deprecated portrait titles, redesigned cards to show artist prominently, then model with formatted dates. Enhanced portrait preview with full-size image viewing and profile navigation.'),
        ),
        ListTile(
          leading: Icon(Icons.search, color: AppColors.forestGreen),
          title: Text('Enhanced Community Features'),
          subtitle: Text('Improved search functionality to filter by model name or artist name. Better tab organization with Recent Portraits as default view.'),
        ),
        ListTile(
          leading: Icon(Icons.emoji_events, color: AppColors.forestGreen),
          title: Text('Awards Tab & Profile System'),
          subtitle: Text('Added awards tab to artist profiles showing portrait trophies, community experience, and merch items. Unified profile scrolling for better UX.'),
        ),
        ListTile(
          leading: Icon(Icons.emoji_events, color: AppColors.forestGreen),
          title: Text('Portrait Milestone Badges'),
          subtitle: Text('Added milestone badges (🌟⭐💎👑🐉) for 5, 10, 25, 50, and 100 portraits. Badges appear in profiles and community lists with tooltips.'),
        ),
        ListTile(
          leading: Icon(Icons.share, color: AppColors.forestGreen),
          title: Text('Instagram Sharing Integration'),
          subtitle: Text('Share any portrait to Instagram with custom story templates featuring app branding, artist info, awards, and hashtags. Includes 100 Heads logo and award emojis.'),
        ),
      ],
    );
  }
}

class _RoadmapTab extends StatelessWidget {
  const _RoadmapTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('🗺️ 100 Heads Society App – Roadmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        _PhaseHeader('Phase 1: Visual Design Refresh'),
        _RoadmapItem('Refresh UI:'),
        _RoadmapBullet('Icons'),
        _RoadmapBullet('Spacing'),
        _RoadmapBullet('Illustrations'),
        _RoadmapBullet('Logo'),
        _RoadmapBullet('Animations'),
        SizedBox(height: 16),
        _PhaseHeader('Phase 2: iOS Compatibility'),
        _RoadmapItem('Build and test iOS version:'),
        _RoadmapBullet('Ensure camera and file permissions work properly in Flutter'),
      ],
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  final String text;
  const _PhaseHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.rustyOrange));
  }
}

class _RoadmapItem extends StatelessWidget {
  final String text;
  const _RoadmapItem(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 2),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _RoadmapBullet extends StatelessWidget {
  final String text;
  const _RoadmapBullet(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
} 