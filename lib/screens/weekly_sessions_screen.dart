import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weekly_session_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/portrait_provider.dart';
import '../models/weekly_session_model.dart';
import '../models/portrait_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/submit_portrait_dialog.dart';
import '../widgets/nomination_dialog.dart';

class WeeklySessionsScreen extends StatefulWidget {
  const WeeklySessionsScreen({super.key});

  @override
  State<WeeklySessionsScreen> createState() => _WeeklySessionsScreenState();
}

class _WeeklySessionsScreenState extends State<WeeklySessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize the weekly session provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weeklySessionProvider = Provider.of<WeeklySessionProvider>(context, listen: false);
      weeklySessionProvider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklySessionProvider>(
      builder: (context, weeklySessionProvider, child) {
        if (weeklySessionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (weeklySessionProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: AppColors.rustyOrange),
                const SizedBox(height: 16),
                Text(
                  'Error: ${weeklySessionProvider.error}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => weeklySessionProvider.initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final currentSession = weeklySessionProvider.currentSession;
        if (currentSession == null) {
          return _buildNoSessionView(weeklySessionProvider);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Weekly Sessions'),
            backgroundColor: AppColors.forestGreen,
            foregroundColor: AppColors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.rustyOrange,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.cream,
              tabs: const [
                Tab(text: 'RSVP & Attendees'),
                Tab(text: 'Submissions'),
                Tab(text: 'Winners'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRsvpTab(context, weeklySessionProvider, currentSession),
              _buildSubmissionsTab(context, weeklySessionProvider, currentSession),
              _buildWinnersTab(context, weeklySessionProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoSessionView(WeeklySessionProvider weeklySessionProvider) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Sessions'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.rustyOrange),
            const SizedBox(height: 16),
            const Text(
              'No Active Session',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Next session: ${weeklySessionProvider.formatSessionDate(weeklySessionProvider.getNextMonday())}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => weeklySessionProvider.createWeeklySession(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rustyOrange,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Create New Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRsvpTab(
    BuildContext context,
    WeeklySessionProvider weeklySessionProvider,
    WeeklySessionModel session,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    final hasRsvpd = currentUserId != null && weeklySessionProvider.hasUserRsvpd(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Info Card
          Card(
            color: AppColors.forestGreen.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, color: AppColors.forestGreen, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Monday Night Studio Session',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${weeklySessionProvider.formatSessionDate(session.sessionDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time: 7:00 PM - 9:00 PM',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attendees: ${session.rsvpUserIds.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // RSVP Button
          if (currentUserId != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (hasRsvpd) {
                    await weeklySessionProvider.cancelRsvpForCurrentSession(currentUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('RSVP cancelled')),
                    );
                  } else {
                    await weeklySessionProvider.rsvpForCurrentSession(currentUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('RSVP confirmed!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasRsvpd ? AppColors.rustyOrange : AppColors.forestGreen,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  hasRsvpd ? 'Cancel RSVP' : 'RSVP for Session',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Attendees List
          Text(
            'Attendees (${weeklySessionProvider.rsvpUsers.length})',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (weeklySessionProvider.rsvpUsers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No attendees yet. Be the first to RSVP!',
                  style: TextStyle(color: AppColors.forestGreen),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weeklySessionProvider.rsvpUsers.length,
              itemBuilder: (context, index) {
                final user = weeklySessionProvider.rsvpUsers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.rustyOrange,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.portraitsCompleted} portraits completed'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab(
    BuildContext context,
    WeeklySessionProvider weeklySessionProvider,
    WeeklySessionModel session,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    final hasSubmitted = currentUserId != null && weeklySessionProvider.hasUserSubmitted(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submit Button
          if (currentUserId != null && !hasSubmitted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSubmitPortraitDialog(context, weeklySessionProvider),
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Submit Your Painting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rustyOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (currentUserId != null && hasSubmitted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await weeklySessionProvider.removeSubmissionForCurrentSession(currentUserId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submission removed')),
                  );
                },
                icon: const Icon(Icons.remove_circle),
                label: const Text('Remove Submission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Submissions List
          Text(
            'This Week\'s Submissions (${weeklySessionProvider.submissionsWithUsers.length})',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (weeklySessionProvider.submissionsWithUsers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No submissions yet. Be the first to submit your painting!',
                  style: TextStyle(color: AppColors.forestGreen),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weeklySessionProvider.submissionsWithUsers.length,
              itemBuilder: (context, index) {
                final submissionData = weeklySessionProvider.submissionsWithUsers[index];
                final submission = submissionData['submission'] as WeeklySubmissionModel;
                final user = submissionData['user'] as UserModel;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.profileImageUrl ?? ''),
                          backgroundColor: AppColors.cream,
                          child: user.profileImageUrl == null
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                        ),
                        title: Text(user.name),
                        subtitle: Text(submission.portraitTitle),
                      ),
                      if (submission.portraitImageUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showNominationDialog(context, submission),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                submission.portraitImageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      if (submission.artistNotes?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(submission.artistNotes!),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Votes: ${submission.votes.values.fold(0, (sum, list) => sum + list.length)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showNominationDialog(context, submission),
                              icon: const Icon(Icons.how_to_vote, size: 16),
                              label: const Text('Vote'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.rustyOrange,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWinnersTab(BuildContext context, WeeklySessionProvider weeklySessionProvider) {
    final winners = weeklySessionProvider.winners;
    
    if (winners.isEmpty) {
      return const Center(
        child: Text('No winners yet. Cast your votes!'),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: awardDetails.entries.map((entry) {
        final categoryKey = entry.key;
        final categoryDetails = entry.value;
        final categoryId = categoryKey.toString().split('.').last;
        final winnerData = winners[categoryId];

        if (winnerData == null) {
          return const SizedBox.shrink(); // Don't show a card if no winner for this category
        }

        final submission = winnerData['submission'] as WeeklySubmissionModel;
        final user = winnerData['user'] as UserModel;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  '${categoryDetails['emoji']} ${categoryDetails['title']} ${categoryDetails['emoji']}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  categoryDetails['subtitle'],
                  style: TextStyle(color: AppColors.rustyOrange, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(user.profileImageUrl ?? ''),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(submission.portraitTitle),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      submission.portraitImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'with ${submission.votes[categoryId]?.length ?? 0} votes',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showSubmitPortraitDialog(BuildContext context, WeeklySessionProvider weeklySessionProvider) {
    showDialog(
      context: context,
      builder: (context) => const SubmitPortraitDialog(),
    );
  }

  void _showNominationDialog(BuildContext context, WeeklySubmissionModel submission) {
    showDialog(
      context: context,
      builder: (context) => NominationDialog(submission: submission),
    );
  }
} 