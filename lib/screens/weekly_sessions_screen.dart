import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../screens/past_winners_detail_screen.dart';
import '../services/user_service.dart';
import '../services/block_service.dart';

class WeeklySessionsScreen extends StatefulWidget {
  const WeeklySessionsScreen({super.key});

  @override
  State<WeeklySessionsScreen> createState() => _WeeklySessionsScreenState();
}

class _WeeklySessionsScreenState extends State<WeeklySessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BlockService _blockService = BlockService();

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
                  indicatorWeight: 3,
                  labelColor: AppColors.forestGreen,
                  unselectedLabelColor: AppColors.forestGreen.withValues(alpha: 0.7),
                  dividerColor: AppColors.forestGreen.withValues(alpha: 0.2),
                  tabs: const [
                    Tab(text: 'Submissions'),
                    Tab(text: 'Awards'),
                    Tab(text: 'Past Awards'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubmissionsTab(context, weeklySessionProvider, currentSession),
                      _buildWinnersTab(context, weeklySessionProvider),
                      _buildPastWinnersTab(context),
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
    final isArtist = authProvider.userData?.isArtist ?? false;
    final isAdmin = authProvider.userData?.isAdmin ?? false;

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
          // Submit Button - only show for artists if session is not cancelled
          if (isArtist && currentUserId != null && !hasSubmitted && !session.isCancelled)
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
          // Show "Voting is closed" message when winners are revealed
          if (weeklySessionProvider.isVotingClosed() && weeklySessionProvider.shouldShowWinners())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.rustyOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.rustyOrange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsDuotone.clockCountdown,
                    color: AppColors.rustyOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Voting is closed this week! Come back again to vote next week!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.rustyOrange,
                      ),
                    ),
                  ),
                ],
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
                    // A model is active from their date at 6pm until the next model's date at 6pm
                    final now = DateTime.now();
                    final sortedModels = models.toList()
                      ..sort((a, b) => a.date.compareTo(b.date));
                    
                    ModelModel? sessionModel;
                    
                    // Start from the end and work backwards to find the most recent model
                    // whose 6pm start time has passed
                    for (int i = sortedModels.length - 1; i >= 0; i--) {
                      final modelStartTime = DateTime(
                        sortedModels[i].date.year,
                        sortedModels[i].date.month,
                        sortedModels[i].date.day,
                        18, // 6pm
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
              StreamBuilder<List<String>>(
                stream: _blockService.getBlockedUsers(currentUserId!),
                builder: (context, blockedSnapshot) {
                  return StreamBuilder<List<String>>(
                    stream: _blockService.getBlockedByUsers(currentUserId),
                    builder: (context, blockedBySnapshot) {
                      final blockedUsers = blockedSnapshot.data ?? [];
                      final blockedByUsers = blockedBySnapshot.data ?? [];
                      final allBlockedUsers = [...blockedUsers, ...blockedByUsers];
                      
                      // Filter out blocked users' submissions
                      final filteredSubmissions = _filterBlockedSubmissions(
                        weeklySessionProvider.submissionsWithUsers,
                        allBlockedUsers,
                      );
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredSubmissions.length,
                        itemBuilder: (context, index) {
                          final submissionData = filteredSubmissions[index];
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(submission.portraitTitle),
                            const SizedBox(height: 4),
                            Text(
                              _formatSubmissionTime(submission.submittedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (submission.portraitImageUrl.isNotEmpty)
                        Stack(
                          children: [
                        GestureDetector(
                              onTap: () => _showImagePreview(context, submission.portraitImageUrl),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                                  child: CachedNetworkImage(
                                    imageUrl: submission.portraitImageUrl,
                                fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                              ),
                            ),
                          ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error, color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Delete button - only show for user's own submission
                            if (isArtist && currentUserId != null && submission.userId == currentUserId && !session.isCancelled)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                    onPressed: () async {
                                      // Show confirmation dialog
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Submission'),
                                          content: const Text(
                                            'Are you sure you want to delete this submission? All votes on it will be gone. This can\'t be undone.',
                                          ),
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
                                        await weeklySessionProvider.removeSubmissionForCurrentSession(currentUserId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Submission deleted'),
                                              backgroundColor: AppColors.forestGreen,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ),
                          ],
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
                            // Only show vote count if admin (during voting) or if voting is closed
                            if (isAdmin || weeklySessionProvider.isVotingClosed())
                              GestureDetector(
                                onTap: isAdmin && !weeklySessionProvider.isVotingClosed()
                                    ? () => _showVotersDialog(context, submission, weeklySessionProvider)
                                    : null,
                                child: Text(
                              'Votes: ${submission.votes.values.fold(0, (sum, list) => sum + list.length)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.forestGreen,
                                    decoration: isAdmin && !weeklySessionProvider.isVotingClosed()
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                                ),
                            ),
                            // Only show vote button if it's not the user's own submission
                            if (submission.userId != currentUserId)
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
            );
                    },
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.userData?.isAdmin ?? false;
    final winners = weeklySessionProvider.winners;
    final isVotingClosed = weeklySessionProvider.isVotingClosed();
    final shouldShowWinners = weeklySessionProvider.shouldShowWinners();
    
    // Only show winners during the designated time period
    if (!shouldShowWinners) {
      // Calculate Friday noon to show exact date/time
      // Use mostRecentCompletedSession if available (the session being voted on), otherwise currentSession
      String winnersAnnouncementText = 'Awards will be announced soon!';
      final sessionForWinners = weeklySessionProvider.mostRecentCompletedSession ?? weeklySessionProvider.currentSession;
      
      if (sessionForWinners != null) {
        final sessionDate = sessionForWinners.sessionDate;
        final friday = sessionDate.add(const Duration(days: 4));
        final fridayNoon = DateTime(friday.year, friday.month, friday.day, 12, 0);
        
        // Format: "Friday, November 15 at 12:00 PM"
        final months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 
                        'July', 'August', 'September', 'October', 'November', 'December'];
        final monthName = months[fridayNoon.month];
        final dayOfMonth = fridayNoon.day;
        
        winnersAnnouncementText = 'Awards announced Friday, $monthName $dayOfMonth at 12:00 PM';
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
                'Awards Coming Soon!',
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
              'No awards yet!',
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
    
    final currentUserId = authProvider.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return StreamBuilder<List<String>>(
      stream: _blockService.getBlockedUsers(currentUserId),
      builder: (context, blockedSnapshot) {
        return StreamBuilder<List<String>>(
          stream: _blockService.getBlockedByUsers(currentUserId),
          builder: (context, blockedBySnapshot) {
            final blockedUsers = blockedSnapshot.data ?? [];
            final blockedByUsers = blockedBySnapshot.data ?? [];
            final allBlockedUsers = [...blockedUsers, ...blockedByUsers];
            
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
                children: awardDetails.entries.expand((entry) {
                final categoryKey = entry.key;
                final categoryDetails = entry.value;
                final categoryId = categoryKey.toString().split('.').last;
                final winnersDataRaw = winners[categoryId];

                if (winnersDataRaw == null || winnersDataRaw.isEmpty) {
                  return [const SizedBox.shrink()]; // Don't show a card if no winners for this category
                }

                // Filter out blocked users from winners
                final winnersData = winnersDataRaw.where((winner) {
                  final userId = winner['userId'] as String;
                  return !allBlockedUsers.contains(userId);
                }).toList();

                if (winnersData.isEmpty) {
                  return [const SizedBox.shrink()]; // Don't show a card if all winners are blocked
                }

                final isTie = winnersData.length > 1;

        // Create a card for this category with all winners
        return [
          Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                  // Category header
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
                  // Show tie badge if multiple winners
                  if (isTie) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.rustyOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.rustyOrange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(
                            PhosphorIconsDuotone.trophy,
                            size: 16,
                            color: AppColors.rustyOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${winnersData.length} Co-Winners!',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.rustyOrange,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                const SizedBox(height: 12),
                  // Show all winners
                  ...winnersData.map((winnerData) {
                    final submission = winnerData['submission'] as WeeklySubmissionModel;
                    final user = winnerData['user'] as UserModel;
                    
                    return Column(
                      children: [
                        if (winnersData.indexOf(winnerData) > 0) 
                          const Divider(height: 24, thickness: 1),
                ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                            backgroundImage: user.profileImageUrl != null 
                                ? NetworkImage(user.profileImageUrl!)
                                : null,
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
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(submission.portraitTitle),
                ),
                        GestureDetector(
                          onTap: () => _showImagePreview(context, submission.portraitImageUrl),
                          child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: submission.portraitImageUrl,
                      fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error, color: Colors.red),
                                ),
                              ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                          child: GestureDetector(
                            onTap: isAdmin
                                ? () => _showVotersDialog(context, submission, weeklySessionProvider)
                                : null,
                  child: Text(
                              'with ${submission.votes.values.fold(0, (sum, list) => sum + list.length)} votes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isAdmin ? TextDecoration.underline : null,
                              ),
                  ),
                          ),
            ),
                      ],
        );
      }).toList(),
                ],
              ),
            ),
          ),
        ];
      }).toList(),
      ),
            );
          },
        );
      },
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

  String _formatSubmissionTime(DateTime submittedAt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = submittedAt.hour == 0 ? 12 : (submittedAt.hour > 12 ? submittedAt.hour - 12 : submittedAt.hour);
    final minute = submittedAt.minute.toString().padLeft(2, '0');
    final period = submittedAt.hour >= 12 ? 'PM' : 'AM';
    
    return 'Submitted ${months[submittedAt.month - 1]} ${submittedAt.day}, ${submittedAt.year} at $hour:$minute $period';
  }

  Future<void> _showVotersDialog(
    BuildContext context,
    WeeklySubmissionModel submission,
    WeeklySessionProvider weeklySessionProvider,
  ) async {
    final userService = UserService();
    final categoryNames = {
      'likeness': 'Best Likeness',
      'style': 'Best Style',
      'fun': 'Most Fun',
      'topHead': 'Top Head',
    };

    // Collect all voters with their categories
    final List<Map<String, dynamic>> votersData = [];
    for (final entry in submission.votes.entries) {
      final categoryId = entry.key;
      final voterIds = entry.value as List<dynamic>;
      for (final voterId in voterIds) {
        try {
          final user = await userService.getUserById(voterId.toString());
          if (user != null) {
            votersData.add({
              'user': user,
              'category': categoryNames[categoryId] ?? categoryId,
            });
          }
        } catch (e) {
          debugPrint('Error loading user $voterId: $e');
        }
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voters'),
        content: SizedBox(
          width: double.maxFinite,
          child: votersData.isEmpty
              ? const Text('No votes yet')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: votersData.length,
                  itemBuilder: (context, index) {
                    final data = votersData[index];
                    final user = data['user'] as UserModel;
                    final category = data['category'] as String;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
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
                      subtitle: Text(category),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isArtist
                              ? AppColors.rustyOrange.withValues(alpha: 0.2)
                              : AppColors.forestGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.isArtist ? 'Artist' : 'Appreciator',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: user.isArtist
                                ? AppColors.rustyOrange
                                : AppColors.forestGreen,
                          ),
                        ),
                      ),
                    );
                  },
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

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastWinnersTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('weekly_sessions')
          .orderBy('sessionDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  PhosphorIconsDuotone.warningCircle,
                  size: 64,
                  color: AppColors.rustyOrange,
                ),
                const SizedBox(height: 16),
                Text('Error loading past winners: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  PhosphorIconsDuotone.clockCounterClockwise,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No past sessions yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        // Filter sessions that have winners (at least one submission with votes)
        final sessionsWithWinners = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final submissions = data['submissions'] as List<dynamic>? ?? [];
          
          // Check if any submission has votes
          for (var submission in submissions) {
            final votes = submission['votes'] as Map<String, dynamic>? ?? {};
            final totalVotes = votes.values.fold(0, (sum, list) => sum + (list as List).length);
            if (totalVotes > 0) {
              return true;
            }
          }
          return false;
        }).toList();

        if (sessionsWithWinners.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  PhosphorIconsDuotone.clockCounterClockwise,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No past awards yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Awards will appear here after voting closes',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessionsWithWinners.length,
          itemBuilder: (context, index) {
            final sessionDoc = sessionsWithWinners[index];
            final sessionData = sessionDoc.data() as Map<String, dynamic>;
            final sessionDate = (sessionData['sessionDate'] as Timestamp).toDate();
            
            // Try to get model name from session, or use formatted date as fallback
            String? modelNameNullable = sessionData['modelName'] as String?;
            final modelImageUrl = sessionData['modelImageUrl'] as String?;
            
            // If no model name, format the session date as fallback
            String modelName;
            if (modelNameNullable == null || modelNameNullable.isEmpty) {
              final months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 
                              'July', 'August', 'September', 'October', 'November', 'December'];
              modelName = '${months[sessionDate.month]} ${sessionDate.day} Session';
            } else {
              modelName = modelNameNullable;
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 32,
                  backgroundImage: modelImageUrl != null 
                      ? NetworkImage(modelImageUrl)
                      : null,
                  backgroundColor: AppColors.cream,
                  child: modelImageUrl == null
                      ? PhosphorIcon(
                          PhosphorIconsDuotone.user,
                          size: 32,
                          color: AppColors.forestGreen,
                        )
                      : null,
                ),
                title: Text(
                  modelName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _formatSessionDate(sessionDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIconsDuotone.trophy,
                          size: 14,
                          color: AppColors.rustyOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View Awards',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.rustyOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PhosphorIcon(
                  PhosphorIconsDuotone.caretRight,
                  size: 24,
                  color: AppColors.forestGreen,
                ),
                onTap: () {
                  // Navigate to detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PastWinnersDetailScreen(
                          sessionId: sessionDoc.id,
                          modelName: modelName,
                          modelImageUrl: modelImageUrl,
                          sessionDate: sessionDate,
                        ),
                      ),
                    );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatSessionDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Helper to filter out blocked users from submissions
  List<Map<String, dynamic>> _filterBlockedSubmissions(
    List<Map<String, dynamic>> submissions,
    List<String> blockedUsers,
  ) {
    return submissions.where((submissionData) {
      final user = submissionData['user'] as UserModel;
      return !blockedUsers.contains(user.id);
    }).toList();
  }
} 