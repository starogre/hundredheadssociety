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
        // Add recent changes here
        ListTile(
          leading: Icon(Icons.check_circle, color: AppColors.forestGreen),
          title: Text('User management and moderation improvements'),
          subtitle: Text('Admins and moderators can now approve signups and upgrades, assign moderator roles, and see badges for pending requests.'),
        ),
        ListTile(
          leading: Icon(Icons.check_circle, color: AppColors.forestGreen),
          title: Text('Profile badges for admins/moderators'),
          subtitle: Text('Admins and moderators now see role badges on user profiles.'),
        ),
        ListTile(
          leading: Icon(Icons.check_circle, color: AppColors.forestGreen),
          title: Text('Improved navigation and vetting'),
          subtitle: Text('Tap users in management screens to view their profile before approving or promoting.'),
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
        _PhaseHeader('Phase 1: Authentication'),
        _RoadmapItem('Improve account authentication:'),
        _RoadmapBullet('OAuth'),
        _RoadmapBullet('SSO'),
        _RoadmapBullet('Email confirmation'),
        _RoadmapBullet('Forgot password flow'),
        SizedBox(height: 16),
        _PhaseHeader('Phase 2: Weekly Session System'),
        _RoadmapItem('Fix and verify weekly functions on Google Cloud'),
        _RoadmapItem('Add searchable model selector tied to weekly events'),
        _RoadmapItem('Implement push notifications:'),
        _RoadmapBullet('User reminders to RSVP, upload portraits'),
        _RoadmapBullet('Admin reminders to approve users, start sessions'),
        _RoadmapBullet('Manual cancellation alerts'),
        SizedBox(height: 16),
        _PhaseHeader('Phase 3: Permissions & Policy'),
        _RoadmapItem('Add privacy policy, terms of service, and community guidelines'),
        _RoadmapItem('Link out to the 100 Heads website for merch, email list, and more'),
        SizedBox(height: 16),
        _PhaseHeader('Phase 4: Awards & Social Features'),
        _RoadmapItem('Add "Awards" tab to user profiles:'),
        _RoadmapBullet('Weekly awards'),
        _RoadmapBullet('Portrait milestones (5, 10, 25, 50, 100)'),
        _RoadmapItem('Add gamified profile badges:'),
        _RoadmapBullet('Merch purchases'),
        _RoadmapBullet('Votes cast'),
        _RoadmapBullet('Participation milestones'),
        _RoadmapItem('Add share-to-Instagram feature:'),
        _RoadmapBullet('On award winner pages'),
        _RoadmapBullet("On user's own portrait posts"),
        SizedBox(height: 16),
        _PhaseHeader('Phase 5: Visual Design Refresh'),
        _RoadmapItem('Refresh UI:'),
        _RoadmapBullet('Icons'),
        _RoadmapBullet('Spacing'),
        _RoadmapBullet('Illustrations'),
        _RoadmapBullet('Logo'),
        _RoadmapBullet('Animations'),
        SizedBox(height: 16),
        _PhaseHeader('Phase 6: iOS Compatibility'),
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