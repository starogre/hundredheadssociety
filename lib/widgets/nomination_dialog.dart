import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasVoted 
                      ? AppColors.forestGreen
                      : hasVotedForCategory && !hasVoted
                          ? Colors.grey.shade300
                          : AppColors.rustyOrange.withValues(alpha: 0.3),
                  width: hasVoted ? 2 : 1,
                ),
                gradient: hasVoted
                    ? LinearGradient(
                        colors: [
                          AppColors.forestGreen.withValues(alpha: 0.15),
                          AppColors.forestGreen.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasVoted 
                    ? null
                    : hasVotedForCategory && !hasVoted
                        ? Colors.grey.shade50
                        : Colors.white,
                boxShadow: hasVoted
                    ? [
                        BoxShadow(
                          color: AppColors.forestGreen.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: hasVotedForCategory && !hasVoted
                      ? null
                      : () async {
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
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Emoji icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasVoted
                                ? AppColors.forestGreen.withValues(alpha: 0.2)
                                : hasVotedForCategory && !hasVoted
                                    ? Colors.grey.shade200
                                    : AppColors.rustyOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            details['emoji'],
                            style: TextStyle(
                              fontSize: 28,
                              color: hasVotedForCategory && !hasVoted
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title and subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                details['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: hasVoted
                                      ? AppColors.forestGreen
                                      : hasVotedForCategory && !hasVoted
                                          ? Colors.grey
                                          : AppColors.forestGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasVotedForCategory && !hasVoted 
                                    ? 'Already voted for this award' 
                                    : details['subtitle'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasVotedForCategory && !hasVoted
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vote indicator
                        if (hasVoted)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen,
                              shape: BoxShape.circle,
                            ),
                            child: PhosphorIcon(
                              PhosphorIconsDuotone.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        else if (hasVotedForCategory)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: PhosphorIcon(
                              PhosphorIconsDuotone.prohibit,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.rustyOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PhosphorIcon(
                                  PhosphorIconsDuotone.star,
                                  color: AppColors.rustyOrange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${votes.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.rustyOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
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