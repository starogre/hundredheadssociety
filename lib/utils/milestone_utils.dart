class MilestoneUtils {
  static const Map<int, String> milestoneEmojis = {
    5: '🌟',    // Star for 5 portraits
    10: '⭐',   // Star for 10 portraits
    25: '💎',   // Diamond for 25 portraits
    50: '👑',   // Crown for 50 portraits
    100: '🐉',  // Dragon for 100 portraits
    200: '🔥',  // Fire for 200 portraits
    300: '🚀',  // Rocket for 300 portraits
    400: '⚡',  // Lightning for 400 portraits
    500: '🏆',  // Trophy for 500 portraits
  };

  /// Returns the highest milestone emoji for a given portrait count
  static String? getMilestoneEmoji(int portraitCount) {
    // Find the highest milestone that the user has achieved
    for (int milestone in milestoneEmojis.keys.toList().reversed) {
      if (portraitCount >= milestone) {
        return milestoneEmojis[milestone];
      }
    }
    return null;
  }

  /// Returns all milestone emojis that a user has achieved
  static List<String> getAllMilestoneEmojis(int portraitCount) {
    List<String> achievedMilestones = [];
    for (int milestone in milestoneEmojis.keys) {
      if (portraitCount >= milestone) {
        achievedMilestones.add(milestoneEmojis[milestone]!);
      }
    }
    return achievedMilestones;
  }

  /// Returns the next milestone count for a user
  static int? getNextMilestone(int portraitCount) {
    for (int milestone in milestoneEmojis.keys) {
      if (portraitCount < milestone) {
        return milestone;
      }
    }
    return null; // User has achieved all milestones
  }

  /// Returns the milestone description for a given count
  static String getMilestoneDescription(int milestone) {
    switch (milestone) {
      case 5:
        return '5 Portraits';
      case 10:
        return '10 Portraits';
      case 25:
        return '25 Portraits';
      case 50:
        return '50 Portraits';
      case 100:
        return '100 Portraits';
      default:
        return '$milestone Portraits';
    }
  }
}
