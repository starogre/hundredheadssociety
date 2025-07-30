import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weekly_session_model.dart';
import '../providers/auth_provider.dart';
import '../providers/weekly_session_provider.dart';
import '../theme/app_theme.dart';

class NominationDialog extends StatelessWidget {
  final WeeklySubmissionModel submission;

  const NominationDialog({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklySessionProvider>(
      builder: (context, weeklySessionProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.currentUser!.uid;

    return AlertDialog(
      title: const Text('Nominate Submission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: awardDetails.entries.map((entry) {
            final category = entry.key;
            final details = entry.value;
            final categoryId = category.toString().split('.').last;

            // Get the current submission data from the provider
            final currentSubmissionData = weeklySessionProvider.submissionsWithUsers
                .where((data) => (data['submission'] as WeeklySubmissionModel).id == submission.id)
                .firstOrNull;
            
            final currentSubmission = currentSubmissionData != null 
                ? currentSubmissionData['submission'] as WeeklySubmissionModel 
                : submission;
            
            final votes = currentSubmission.votes[categoryId] ?? [];
            final hasVoted = votes.contains(currentUserId);
            final hasVotedForCategory = weeklySessionProvider.hasUserVotedForCategory(currentUserId, categoryId);

            return Card(
              color: hasVoted 
                  ? AppColors.forestGreen.withOpacity(0.2) 
                  : hasVotedForCategory && !hasVoted 
                      ? Colors.grey.withOpacity(0.2) 
                      : null,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Text(details['emoji'], style: const TextStyle(fontSize: 24)),
                title: Text(
                  details['title'],
                  style: TextStyle(
                    color: hasVotedForCategory && !hasVoted ? Colors.grey : null,
                  ),
                ),
                subtitle: Text(
                  hasVotedForCategory && !hasVoted 
                      ? 'You already voted for this award on another painting' 
                      : details['subtitle'],
                  style: TextStyle(
                    color: hasVotedForCategory && !hasVoted ? Colors.grey : null,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${votes.length}'),
                  ],
                ),
                onTap: () async {
                  if (hasVoted) {
                    await weeklySessionProvider.removeVoteForSubmission(
                      submission.id,
                      categoryId,
                      currentUserId,
                    );
                  } else if (!hasVotedForCategory) {
                    await weeklySessionProvider.voteForSubmission(
                      submission.id,
                      categoryId,
                      currentUserId,
                    );
                  }
                  // No need to pop here, the stream will rebuild the UI
                },
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
      },
    );
  }
} 