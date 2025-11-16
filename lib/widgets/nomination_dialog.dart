import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/weekly_session_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/weekly_session_provider.dart';
import '../theme/app_theme.dart';

class NominationDialog extends StatelessWidget {
  final WeeklySubmissionModel submission;

  const NominationDialog({super.key, required this.submission});

  // Helper to find which submission user voted for in a category
  Map<String, dynamic>? _findVotedSubmission(
    WeeklySessionProvider provider,
    String categoryId,
    String userId,
  ) {
    for (var submissionData in provider.submissionsWithUsers) {
      final sub = submissionData['submission'] as WeeklySubmissionModel;
      final votes = sub.votes[categoryId] ?? [];
      if (votes.contains(userId)) {
        return submissionData;
      }
    }
    return null;
  }

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
            
            // Get the submission user already voted for in this category (if any)
            final votedSubmissionData = _findVotedSubmission(weeklySessionProvider, categoryId, currentUserId);
            final votedSubmission = votedSubmissionData?['submission'] as WeeklySubmissionModel?;
            final votedUser = votedSubmissionData?['user'] as UserModel?;
            final isVotedOnDifferentSubmission = votedSubmission != null && votedSubmission.id != submission.id;

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
                          try {
                            if (hasVoted) {
                              // Unvote - no confirmation needed
                              await weeklySessionProvider.removeVoteForSubmission(
                                submission.id,
                                categoryId,
                                currentUserId,
                              );
                            } else if (isVotedOnDifferentSubmission && votedUser != null) {
                              // Switching vote - show confirmation
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Switch ${details['title']} Vote?'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('You already voted for this award on:'),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: CachedNetworkImage(
                                                imageUrl: votedSubmission!.portraitImageUrl,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: Colors.grey[300],
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image, size: 24),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                votedUser.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('Do you want to switch your vote to this submission instead?'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.forestGreen,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Switch Vote'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                // Remove old vote and add new one
                                await weeklySessionProvider.removeVoteForSubmission(
                                  votedSubmission.id,
                                  categoryId,
                                  currentUserId,
                                );
                                await weeklySessionProvider.voteForSubmission(
                                  submission.id,
                                  categoryId,
                                  currentUserId,
                                );
                              }
                            } else {
                              // New vote - no confirmation needed
                              await weeklySessionProvider.voteForSubmission(
                                submission.id,
                                categoryId,
                                currentUserId,
                              );
                            }
                          } catch (e) {
                            // Show error message to user
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
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
                              // Show current vote if voted on different submission
                              if (isVotedOnDifferentSubmission && votedUser != null && votedSubmission != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Portrait thumbnail
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: CachedNetworkImage(
                                          imageUrl: votedSubmission.portraitImageUrl,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            width: 32,
                                            height: 32,
                                            color: Colors.grey[300],
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            width: 32,
                                            height: 32,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image, size: 16),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Voted for:',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              votedUser.name,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade800,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (!hasVoted)
                                Text(
                                  details['subtitle'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
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