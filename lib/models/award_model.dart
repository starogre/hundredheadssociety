import 'package:cloud_firestore/cloud_firestore.dart';

enum AwardType {
  milestone,    // 5, 10, 25, 50, 100 portraits
  weekly,       // Weekly session awards
  merch,        // Merchandise purchased
  votes,        // Votes cast milestones
  special,      // Special achievements
}

enum AwardCategory {
  portraits,    // Portrait milestones
  participation, // Session participation
  community,    // Community contributions
  achievement,  // Special achievements
}

class AwardModel {
  final String id;
  final String name;
  final String description;
  final AwardType type;
  final AwardCategory category;
  final String? iconUrl;
  final String? badgeUrl;
  final int? requirement; // e.g., 5 portraits, 10 votes, etc.
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final Map<String, dynamic>? metadata; // Additional data like session ID for weekly awards

  AwardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    this.iconUrl,
    this.badgeUrl,
    this.requirement,
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
    this.metadata,
  });

  factory AwardModel.fromMap(Map<String, dynamic> map, String id) {
    return AwardModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: AwardType.values.firstWhere(
        (e) => e.toString() == 'AwardType.${map['type']}',
        orElse: () => AwardType.special,
      ),
      category: AwardCategory.values.firstWhere(
        (e) => e.toString() == 'AwardCategory.${map['category']}',
        orElse: () => AwardCategory.achievement,
      ),
      iconUrl: map['iconUrl'],
      badgeUrl: map['badgeUrl'],
      requirement: map['requirement'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'iconUrl': iconUrl,
      'badgeUrl': badgeUrl,
      'requirement': requirement,
      'isActive': isActive,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  AwardModel copyWith({
    String? id,
    String? name,
    String? description,
    AwardType? type,
    AwardCategory? category,
    String? iconUrl,
    String? badgeUrl,
    int? requirement,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return AwardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      iconUrl: iconUrl ?? this.iconUrl,
      badgeUrl: badgeUrl ?? this.badgeUrl,
      requirement: requirement ?? this.requirement,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isMilestoneAward => type == AwardType.milestone;
  bool get isWeeklyAward => type == AwardType.weekly;
  bool get isMerchAward => type == AwardType.merch;
  bool get isVoteAward => type == AwardType.votes;
  bool get isSpecialAward => type == AwardType.special;

  // Check if user qualifies for this award
  bool userQualifies(Map<String, dynamic> userStats) {
    if (!isActive) return false;
    
    switch (type) {
      case AwardType.milestone:
        final portraitsCompleted = userStats['portraitsCompleted'] ?? 0;
        return requirement != null && portraitsCompleted >= requirement!;
      
      case AwardType.votes:
        final votesCast = userStats['totalVotesCast'] ?? 0;
        return requirement != null && votesCast >= requirement!;
      
      case AwardType.weekly:
        // Weekly awards are manually assigned
        return false;
      
      case AwardType.merch:
        // Merch awards are manually assigned
        return false;
      
      case AwardType.special:
        // Special awards have custom logic
        return false;
    }
  }

  // Get display name for type
  String get typeDisplayName {
    switch (type) {
      case AwardType.milestone:
        return 'Portrait Milestone';
      case AwardType.weekly:
        return 'Weekly Award';
      case AwardType.merch:
        return 'Merchandise';
      case AwardType.votes:
        return 'Voting Milestone';
      case AwardType.special:
        return 'Special Achievement';
    }
  }

  // Get display name for category
  String get categoryDisplayName {
    switch (category) {
      case AwardCategory.portraits:
        return 'Portraits';
      case AwardCategory.participation:
        return 'Participation';
      case AwardCategory.community:
        return 'Community';
      case AwardCategory.achievement:
        return 'Achievement';
    }
  }
}

// User Award Model - tracks when a user receives an award
class UserAwardModel {
  final String id;
  final String userId;
  final String awardId;
  final DateTime awardedAt;
  final String awardedBy; // User ID who awarded it (or 'system' for automatic)
  final Map<String, dynamic>? context; // Additional context about when/how it was awarded

  UserAwardModel({
    required this.id,
    required this.userId,
    required this.awardId,
    required this.awardedAt,
    required this.awardedBy,
    this.context,
  });

  factory UserAwardModel.fromMap(Map<String, dynamic> map, String id) {
    return UserAwardModel(
      id: id,
      userId: map['userId'] ?? '',
      awardId: map['awardId'] ?? '',
      awardedAt: (map['awardedAt'] as Timestamp).toDate(),
      awardedBy: map['awardedBy'] ?? '',
      context: map['context'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'awardId': awardId,
      'awardedAt': awardedAt,
      'awardedBy': awardedBy,
      'context': context,
    };
  }

  UserAwardModel copyWith({
    String? id,
    String? userId,
    String? awardId,
    DateTime? awardedAt,
    String? awardedBy,
    Map<String, dynamic>? context,
  }) {
    return UserAwardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      awardId: awardId ?? this.awardId,
      awardedAt: awardedAt ?? this.awardedAt,
      awardedBy: awardedBy ?? this.awardedBy,
      context: context ?? this.context,
    );
  }
} 