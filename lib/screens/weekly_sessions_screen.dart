import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/weekly_session_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/model_provider.dart';
import '../models/weekly_session_model.dart';
import '../models/user_model.dart';
import '../models/model_model.dart';
import '../theme/app_theme.dart';
import '../widgets/submit_portrait_dialog.dart';
import '../widgets/nomination_dialog.dart';
import '../screens/profile_screen.dart';

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
    _tabController = TabController(length: 2, vsync: this);
    
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
                PhosphorIcon(PhosphorIconsDuotone.warningCircle, size: 64, color: AppColors.rustyOrange),
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
          body: SafeArea(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.rustyOrange,
                  labelColor: AppColors.forestGreen,
                  unselectedLabelColor: AppColors.forestGreen.withValues(alpha: 0.7),
                  tabs: const [
                    Tab(text: 'Submissions'),
                    Tab(text: 'Winners'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubmissionsTab(context, weeklySessionProvider, currentSession),
                      _buildWinnersTab(context, weeklySessionProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoSessionView(WeeklySessionProvider weeklySessionProvider) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(PhosphorIconsDuotone.calendarX, size: 64, color: AppColors.rustyOrange),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => weeklySessionProvider.createWeeklySession(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rustyOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Create New Session'),
              ),
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUserId = authProvider.currentUser?.uid;
        final hasRsvpd = currentUserId != null && weeklySessionProvider.hasUserRsvpd(currentUserId);
        final isAdminOrModerator = authProvider.userData?.isAdmin == true || authProvider.userData?.isModerator == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Info Card
          Card(
            color: session.isCancelled ? Colors.red.shade50 : AppColors.lightCream,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        session.isCancelled ? Icons.cancel : Icons.event,
                        color: session.isCancelled ? Colors.red : AppColors.forestGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.isCancelled ? 'Session Cancelled' : 'Monday Night Studio Session',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: session.isCancelled ? Colors.red : AppColors.forestGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (session.isCancelled)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Text(
                                  'CANCELLED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Admin/Moderator controls
                      if (isAdminOrModerator) ...[
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'cancel') {
                              _showCancelSessionDialog(context, weeklySessionProvider);
                            } else if (value == 'uncancel') {
                              _showUncancelSessionDialog(context, weeklySessionProvider);
                            } else if (value == 'notes') {
                              _showNotesDialog(context, weeklySessionProvider, session.notes ?? '');
                            }
                          },
                          itemBuilder: (context) => [
                            if (!session.isCancelled) ...[
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Cancel Session'),
                                  ],
                                ),
                              ),
                            ] else ...[
                              PopupMenuItem(
                                value: 'uncancel',
                                child: const Row(
                                  children: [
                                    Icon(Icons.refresh, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Re-activate Session'),
                                  ],
                                ),
                              ),
                            ],
                            if (session.isCancelled)
                              const PopupMenuItem(
                                value: 'notes',
                                child: Row(
                                  children: [
                                    Icon(Icons.note, color: AppColors.forestGreen),
                                    SizedBox(width: 8),
                                    Text('Edit Cancellation Notes'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${weeklySessionProvider.formatSessionDate(session.sessionDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time: 6:00 PM - 9:00 PM',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attendees: ${session.rsvpUserIds.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (session.isCancelled && session.notes != null && session.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.note, size: 16, color: Colors.red.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Cancellation Notes:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.notes!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // RSVP Button - only show if session is not cancelled
          if (currentUserId != null && !session.isCancelled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (hasRsvpd) {
                    await weeklySessionProvider.cancelRsvpForCurrentSession(currentUserId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('RSVP cancelled')),
                      );
                    }
                  } else {
                    await weeklySessionProvider.rsvpForCurrentSession(currentUserId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('RSVP confirmed!')),
                      );
                    }
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

                    // Attendees List - only show if session is not cancelled
          if (!session.isCancelled) ...[
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
                        backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        backgroundColor: AppColors.rustyOrange,
                        child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(user.name),
                      onTap: () => _navigateToUserProfile(user.id),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
      },
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

    return RefreshIndicator(
      onRefresh: () async {
        weeklySessionProvider.initialize();
        // Wait a bit for the stream to update
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.forestGreen,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submit Button - only show if session is not cancelled
          if (currentUserId != null && !hasSubmitted && !session.isCancelled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSubmitPortraitDialog(context, weeklySessionProvider, session),
                icon: PhosphorIcon(PhosphorIconsDuotone.image, size: 20),
                label: const Text('Submit Your Painting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rustyOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (currentUserId != null && hasSubmitted && !session.isCancelled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await weeklySessionProvider.removeSubmissionForCurrentSession(currentUserId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Submission removed')),
                    );
                  }
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

          // This Week's Model Section
          if (!session.isCancelled)
            Consumer<ModelProvider>(
              builder: (context, modelProvider, child) {
                return StreamBuilder<List<ModelModel>>(
                  stream: modelProvider.getModels(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final models = snapshot.data!;
                    
                    // Find the currently active model
                    // A model is active from their date at 9pm until the next model's date at 9pm
                    final now = DateTime.now();
                    final sortedModels = models.toList()
                      ..sort((a, b) => a.date.compareTo(b.date));
                    
                    ModelModel? sessionModel;
                    
                    // Start from the end and work backwards to find the most recent model
                    // whose 9pm start time has passed
                    for (int i = sortedModels.length - 1; i >= 0; i--) {
                      final modelStartTime = DateTime(
                        sortedModels[i].date.year,
                        sortedModels[i].date.month,
                        sortedModels[i].date.day,
                        21, // 9pm
                        0,
                      );
                      
                      // If we've passed this model's start time, this is the active model
                      if (now.isAfter(modelStartTime) || now.isAtSameMomentAs(modelStartTime)) {
                        sessionModel = sortedModels[i];
                        break;
                      }
                    }
                    
                    // If no model found (current time is before all models), use the first model
                    sessionModel ??= sortedModels.first;

                    if (sessionModel == null) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Week\'s Model',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.forestGreen.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Model image
                              if (sessionModel.imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: sessionModel.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppColors.forestGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: PhosphorIcon(
                                        PhosphorIconsDuotone.user,
                                        color: AppColors.forestGreen,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.forestGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: PhosphorIcon(
                                    PhosphorIconsDuotone.user,
                                    color: AppColors.forestGreen,
                                    size: 30,
                                  ),
                                ),
                              const SizedBox(width: 16),
                              // Model name
                              Expanded(
                                child: Text(
                                  sessionModel.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                );
              },
            ),

          // Submissions List - only show if session is not cancelled
          if (!session.isCancelled) ...[
            Text(
              'This Week\'s Submissions (${weeklySessionProvider.submissionsWithUsers.length})',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (weeklySessionProvider.submissionsWithUsers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsDuotone.paintBrush,
                        size: 64,
                        color: AppColors.forestGreen.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No submissions yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to submit your painting!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                              onPressed: weeklySessionProvider.isVotingClosed() 
                                  ? null 
                                  : () => _showNominationDialog(context, submission),
                              icon: Icon(
                                Icons.how_to_vote, 
                                size: 16,
                                color: weeklySessionProvider.isVotingClosed() ? Colors.grey : null,
                              ),
                              label: Text(
                                weeklySessionProvider.isVotingClosed() ? 'Voting Closed' : 'Vote',
                                style: TextStyle(
                                  color: weeklySessionProvider.isVotingClosed() ? Colors.grey : null,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: weeklySessionProvider.isVotingClosed() 
                                    ? Colors.grey.shade300 
                                    : AppColors.rustyOrange,
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
        ],
      ),
      ),
    );
  }

  Widget _buildWinnersTab(BuildContext context, WeeklySessionProvider weeklySessionProvider) {
    final winners = weeklySessionProvider.winners;
    final isVotingClosed = weeklySessionProvider.isVotingClosed();
    final shouldShowWinners = weeklySessionProvider.shouldShowWinners();
    
    // Only show winners during the designated time period
    if (!shouldShowWinners) {
      // Calculate Friday noon to show exact date/time
      String winnersAnnouncementText = 'Winners will be announced soon!';
      if (weeklySessionProvider.currentSession != null) {
        final sessionDate = weeklySessionProvider.currentSession!.sessionDate;
        final friday = sessionDate.add(const Duration(days: 4));
        final fridayNoon = DateTime(friday.year, friday.month, friday.day, 12, 0);
        
        // Format: "Friday, November 15 at 12:00 PM"
        final months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 
                        'July', 'August', 'September', 'October', 'November', 'December'];
        final monthName = months[fridayNoon.month];
        final dayOfMonth = fridayNoon.day;
        
        winnersAnnouncementText = 'Winners announced Friday, $monthName $dayOfMonth at 12:00 PM';
      }
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                PhosphorIconsDuotone.clockCountdown,
                size: 80,
                color: AppColors.rustyOrange,
              ),
              const SizedBox(height: 24),
              Text(
                'Winners Coming Soon!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                winnersAnnouncementText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.rustyOrange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Keep voting for your favorite paintings until then!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Show winners during the designated time period
    if (winners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsDuotone.trophy,
              size: 64,
              color: AppColors.rustyOrange.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No winners yet!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No votes were cast for any submissions.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        weeklySessionProvider.initialize();
        // Wait a bit for the stream to update
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.forestGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  void _showSubmitPortraitDialog(BuildContext context, WeeklySessionProvider weeklySessionProvider, WeeklySessionModel session) {
    showDialog(
      context: context,
      builder: (context) => SubmitPortraitDialog(
        sessionDate: session.sessionDate,
      ),
    );
  }

  void _showNominationDialog(BuildContext context, WeeklySubmissionModel submission) {
    showDialog(
      context: context,
      builder: (context) => NominationDialog(submission: submission),
    );
  }

  void _navigateToUserProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  void _showCancelSessionDialog(BuildContext context, WeeklySessionProvider weeklySessionProvider) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to cancel this session? This action cannot be undone.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Notes (required)',
                hintText: 'e.g., "Cancelled due to weather" or "No model available"',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide cancellation notes'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              await weeklySessionProvider.cancelWeeklySession(notesController.text.trim());
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }

  void _showUncancelSessionDialog(BuildContext context, WeeklySessionProvider weeklySessionProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-activate Session'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to re-activate this session? Users will be able to RSVP again.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await weeklySessionProvider.uncancelWeeklySession();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session re-activated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Re-activate'),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog(BuildContext context, WeeklySessionProvider weeklySessionProvider, String currentNotes) {
    final notesController = TextEditingController(text: currentNotes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Notes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit cancellation notes for this session. These will be visible to all users.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Notes',
                hintText: 'e.g., "Cancelled due to weather" or "No model available"',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await weeklySessionProvider.updateSessionNotes(notesController.text.trim());
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cancellation notes updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
            child: const Text('Save Cancellation Notes'),
          ),
        ],
      ),
    );
  }
} 