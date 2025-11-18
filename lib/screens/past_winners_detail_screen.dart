import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/weekly_session_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../providers/weekly_session_provider.dart';

class PastWinnersDetailScreen extends StatelessWidget {
  final String sessionId;
  final String modelName;
  final String? modelImageUrl;
  final DateTime sessionDate;

  const PastWinnersDetailScreen({
    super.key,
    required this.sessionId,
    required this.modelName,
    this.modelImageUrl,
    required this.sessionDate,
  });

  String _formatSessionDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<Map<String, List<Map<String, dynamic>>>> _calculateWinners(
    List<WeeklySubmissionModel> submissions,
  ) async {
    final Map<String, List<Map<String, dynamic>>> categoryWinners = {};
    final userService = UserService();
    final awardCategories = ['likeness', 'style', 'fun', 'topHead'];

    for (var category in awardCategories) {
      List<Map<String, dynamic>> winners = [];
      int maxVotes = 0;

      // First pass: find the maximum number of votes
      for (var submission in submissions) {
        final votes = submission.votes[category]?.length ?? 0;
        if (votes > maxVotes) {
          maxVotes = votes;
        }
      }

      // Second pass: collect all submissions with the maximum votes (handles ties)
      if (maxVotes > 0) {
        for (var submission in submissions) {
          final votes = submission.votes[category]?.length ?? 0;
          if (votes == maxVotes) {
            // Load user data
            try {
              final user = await userService.getUserById(submission.userId);
              if (user != null) {
                winners.add({
                  'submission': submission,
                  'user': user,
                });
              }
            } catch (e) {
              debugPrint('Error loading user ${submission.userId}: $e');
            }
          }
        }
      }

      if (winners.isNotEmpty) {
        categoryWinners[category] = winners;
      }
    }

    return categoryWinners;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              modelName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _formatSessionDate(sessionDate),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('weekly_sessions')
            .doc(sessionId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
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
                  const Text('Error loading session data'),
                ],
              ),
            );
          }

          final sessionData = snapshot.data!.data() as Map<String, dynamic>;
          final session = WeeklySessionModel.fromMap(sessionData, sessionId);

          if (session.submissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(
                    PhosphorIconsDuotone.trophy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No submissions for this session',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _calculateWinners(session.submissions),
            builder: (context, winnersSnapshot) {
              if (winnersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (winnersSnapshot.hasError) {
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
                      Text('Error: ${winnersSnapshot.error}'),
                    ],
                  ),
                );
              }

              final winners = winnersSnapshot.data ?? {};

              if (winners.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsDuotone.trophy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No winners for this session',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No votes were cast',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: awardDetails.entries.expand((entry) {
                  final categoryKey = entry.key;
                  final categoryDetails = entry.value;
                  final categoryId = categoryKey.toString().split('.').last;
                  final winnersData = winners[categoryId];

                  if (winnersData == null || winnersData.isEmpty) {
                    return [const SizedBox.shrink()];
                  }

                  final isTie = winnersData.length > 1;

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
                              style: const TextStyle(
                                color: AppColors.rustyOrange,
                                fontStyle: FontStyle.italic,
                              ),
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
                                  AspectRatio(
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
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'with ${submission.votes.values.fold(0, (sum, list) => sum + list.length)} votes',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
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
              );
            },
          );
        },
      ),
    );
  }
}

