import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklySessionModel {
  final String id;
  final DateTime sessionDate;
  final List<String> rsvpUserIds;
  final List<WeeklySubmissionModel> submissions;
  final DateTime createdAt;
  final bool isActive;

  WeeklySessionModel({
    required this.id,
    required this.sessionDate,
    required this.rsvpUserIds,
    required this.submissions,
    required this.createdAt,
    required this.isActive,
  });

  factory WeeklySessionModel.fromMap(Map<String, dynamic> map, String id) {
    return WeeklySessionModel(
      id: id,
      sessionDate: (map['sessionDate'] as Timestamp).toDate(),
      rsvpUserIds: List<String>.from(map['rsvpUserIds'] ?? []),
      submissions: (map['submissions'] as List<dynamic>? ?? [])
          .map((submission) => WeeklySubmissionModel.fromMap(submission))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionDate': sessionDate,
      'rsvpUserIds': rsvpUserIds,
      'submissions': submissions.map((submission) => submission.toMap()).toList(),
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  WeeklySessionModel copyWith({
    String? id,
    DateTime? sessionDate,
    List<String>? rsvpUserIds,
    List<WeeklySubmissionModel>? submissions,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return WeeklySessionModel(
      id: id ?? this.id,
      sessionDate: sessionDate ?? this.sessionDate,
      rsvpUserIds: rsvpUserIds ?? this.rsvpUserIds,
      submissions: submissions ?? this.submissions,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class WeeklySubmissionModel {
  final String id;
  final String userId;
  final String portraitId;
  final String portraitTitle;
  final String portraitImageUrl;
  final DateTime submittedAt;
  final String? artistNotes;
  final Map<String, List<String>> votes;

  WeeklySubmissionModel({
    required this.id,
    required this.userId,
    required this.portraitId,
    required this.portraitTitle,
    required this.portraitImageUrl,
    required this.submittedAt,
    this.artistNotes,
    this.votes = const {},
  });

  factory WeeklySubmissionModel.fromMap(Map<String, dynamic> map) {
    return WeeklySubmissionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      portraitId: map['portraitId'] ?? '',
      portraitTitle: map['portraitTitle'] ?? '',
      portraitImageUrl: map['portraitImageUrl'] ?? '',
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      artistNotes: map['artistNotes'],
      votes: (map['votes'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, List<String>.from(value))) ??
          {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'portraitId': portraitId,
      'portraitTitle': portraitTitle,
      'portraitImageUrl': portraitImageUrl,
      'submittedAt': submittedAt,
      'artistNotes': artistNotes,
      'votes': votes,
    };
  }

  WeeklySubmissionModel copyWith({
    String? id,
    String? userId,
    String? portraitId,
    String? portraitTitle,
    String? portraitImageUrl,
    DateTime? submittedAt,
    String? artistNotes,
    Map<String, List<String>>? votes,
  }) {
    return WeeklySubmissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      portraitId: portraitId ?? this.portraitId,
      portraitTitle: portraitTitle ?? this.portraitTitle,
      portraitImageUrl: portraitImageUrl ?? this.portraitImageUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      artistNotes: artistNotes ?? this.artistNotes,
      votes: votes ?? this.votes,
    );
  }
} 