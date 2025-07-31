import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weekly_session_model.dart';

class AwardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all awards for a specific portrait
  Future<List<Map<String, dynamic>>> getPortraitAwards(String portraitId) async {
    try {
      // Get all weekly sessions
      final sessionsSnapshot = await _firestore
          .collection('weekly_sessions')
          .orderBy('sessionDate', descending: true)
          .get();

      List<Map<String, dynamic>> awards = [];

      for (var doc in sessionsSnapshot.docs) {
        final session = WeeklySessionModel.fromMap(doc.data(), doc.id);
        
        // Find submissions that contain this portrait
        for (var submission in session.submissions) {
          if (submission.portraitId == portraitId) {
            // Check if this submission won any awards
            final awardCategories = ['likeness', 'style', 'fun', 'topHead'];
            
            for (var category in awardCategories) {
              final votes = submission.votes[category]?.length ?? 0;
              if (votes > 0) {
                // Check if this submission has the most votes for this category
                int maxVotes = 0;
                for (var otherSubmission in session.submissions) {
                  final otherVotes = otherSubmission.votes[category]?.length ?? 0;
                  if (otherVotes > maxVotes) {
                    maxVotes = otherVotes;
                  }
                }
                
                // If this submission has the most votes, it's a winner
                if (votes == maxVotes && votes > 0) {
                  awards.add({
                    'category': category,
                    'sessionDate': session.sessionDate,
                    'votes': votes,
                    'sessionId': session.id,
                  });
                }
              }
            }
          }
        }
      }

      return awards;
    } catch (e) {
      print('Error getting portrait awards: $e');
      return [];
    }
  }

  // Get award details for display
  Map<String, Map<String, dynamic>> getAwardDetails() {
    return {
      'likeness': {
        'title': 'Best Likeness',
        'subtitle': 'Most accurate representation',
        'emoji': '🎯',
      },
      'style': {
        'title': 'Best Style',
        'subtitle': 'Most creative approach',
        'emoji': '🎨',
      },
      'fun': {
        'title': 'Most Fun',
        'subtitle': 'Most entertaining piece',
        'emoji': '😄',
      },
      'topHead': {
        'title': 'Top Head',
        'subtitle': 'Overall best of the week',
        'emoji': '👑',
      },
    };
  }
} 