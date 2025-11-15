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
          final List<Map<String, dynamic>> awards = [];

          for (final sessionDoc in snapshot.data!.docs) {
            final sessionData = sessionDoc.data() as Map<String, dynamic>;
            final submissions = sessionData['submissions'] as List<dynamic>? ?? [];
            final sessionDate = (sessionData['sessionDate'] as Timestamp).toDate();
            final modelName = sessionData['modelName'] as String? ?? 'Unknown Model';

            for (final submission in submissions) {
              final submissionUserId = submission['userId'] as String?;
              
              // Check if this submission belongs to our user AND has awards
              if (submissionUserId == userId) {
                final awards1st = submission['awards1st'] as int? ?? 0;
                final awards2nd = submission['awards2nd'] as int? ?? 0;
                final awards3rd = submission['awards3rd'] as int? ?? 0;
                final totalAwards = awards1st + awards2nd + awards3rd;

                if (totalAwards > 0) {
                  awards.add({
                    'imageUrl': submission['imageUrl'] as String?,
                    'sessionDate': sessionDate,
                    'modelName': modelName,
                    'awards1st': awards1st,
                    'awards2nd': awards2nd,
                    'awards3rd': awards3rd,
                    'totalAwards': totalAwards,
                  });
                }
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
    final awards1st = award['awards1st'] as int;
    final awards2nd = award['awards2nd'] as int;
    final awards3rd = award['awards3rd'] as int;
    final totalAwards = award['totalAwards'] as int;

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
                      if (awards1st > 0) ...[
                        PhosphorIcon(
                          PhosphorIconsDuotone.trophy,
                          size: 16,
                          color: const Color(0xFFFFD700), // Gold
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$awards1st',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (awards2nd > 0) ...[
                        PhosphorIcon(
                          PhosphorIconsDuotone.trophy,
                          size: 16,
                          color: const Color(0xFFC0C0C0), // Silver
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$awards2nd',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (awards3rd > 0) ...[
                        PhosphorIcon(
                          PhosphorIconsDuotone.trophy,
                          size: 16,
                          color: const Color(0xFFCD7F32), // Bronze
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$awards3rd',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Total awards badge
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
                    PhosphorIconsDuotone.trophy,
                    size: 16,
                    color: AppColors.rustyOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalAwards',
                    style: const TextStyle(
                      fontSize: 14,
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

