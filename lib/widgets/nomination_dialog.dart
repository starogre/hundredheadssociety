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
    final weeklySessionProvider = Provider.of<WeeklySessionProvider>(context, listen: false);
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

            final votes = submission.votes[categoryId] ?? [];
            final hasVoted = votes.contains(currentUserId);

            return Card(
              color: hasVoted ? AppColors.forestGreen.withOpacity(0.2) : null,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Text(details['emoji'], style: const TextStyle(fontSize: 24)),
                title: Text(details['title']),
                subtitle: Text(details['subtitle']),
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
                  } else {
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
  }
} 