import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';

class PortraitAwardsListScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const PortraitAwardsListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName\'s Portrait Awards'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
              child: Text('Error loading awards: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                  Text(
                    'No awards yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Collect all awards for this user
          // Awards are determined by who won each category (most votes)
          final List<Map<String, dynamic>> awards = [];
          final awardCategories = ['likeness', 'style', 'fun', 'topHead'];
          final categoryNames = {
            'likeness': 'Best Likeness',
            'style': 'Best Style',
            'fun': 'Most Fun',
            'topHead': 'Top Head',
          };

          for (final sessionDoc in snapshot.data!.docs) {
            final sessionData = sessionDoc.data() as Map<String, dynamic>;
            final submissions = sessionData['submissions'] as List<dynamic>? ?? [];
            final sessionDate = (sessionData['sessionDate'] as Timestamp).toDate();
            final modelName = sessionData['modelName'] as String? ?? 'Unknown Model';

            // For each category, find the winner (submission with most votes)
            for (final category in awardCategories) {
              String? winnerUserId;
              int maxVotes = 0;
              Map<String, dynamic>? winnerSubmission;

              // Find the submission with the most votes in this category
              for (final submission in submissions) {
                final votes = submission['votes'] as Map<String, dynamic>?;
                if (votes != null) {
                  final categoryVotes = votes[category] as List<dynamic>?;
                  if (categoryVotes != null && categoryVotes.length > maxVotes) {
                    maxVotes = categoryVotes.length;
                    winnerUserId = submission['userId'] as String?;
                    winnerSubmission = submission;
                  }
                }
              }

              // If this user won this category, add it to awards
              if (winnerUserId == userId && winnerSubmission != null && maxVotes > 0) {
                awards.add({
                  'imageUrl': winnerSubmission['portraitImageUrl'] as String?,
                  'sessionDate': sessionDate,
                  'modelName': modelName,
                  'category': category,
                  'categoryName': categoryNames[category] ?? category,
                  'votes': maxVotes,
                  'awards1st': 1, // Won this category
                  'awards2nd': 0,
                  'awards3rd': 0,
                  'totalAwards': 1,
                });
              }
            }
          }

          if (awards.isEmpty) {
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
                  Text(
                    'No awards yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submit portraits to weekly awards\nto start earning trophies!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: awards.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final award = awards[index];
              return _buildAwardCard(award);
            },
          );
        },
      ),
    );
  }

  Widget _buildAwardCard(Map<String, dynamic> award) {
    final imageUrl = award['imageUrl'] as String?;
    final sessionDate = award['sessionDate'] as DateTime;
    final modelName = award['modelName'] as String;
    final categoryName = award['categoryName'] as String? ?? 'Award';
    final votes = award['votes'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Small portrait thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            // Award details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modelName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(sessionDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsDuotone.trophy,
                        size: 16,
                        color: const Color(0xFFFFD700), // Gold
                      ),
                      const SizedBox(width: 4),
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($votes votes)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

