import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      read: map['read'] ?? false,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'createdAt': createdAt,
      'read': read,
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? read,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      data: data ?? this.data,
    );
  }

  // Helper methods for different notification types
  bool get isSessionCreated => type == 'session_created';
  bool get isSessionReminder => type == 'session_reminder';
  bool get isRSVPConfirmation => type == 'rsvp_confirmation';
  bool get isNewSubmission => type == 'new_submission';
  bool get isSessionCompleted => type == 'session_completed';
  bool get isUpgradeRequest => type == 'upgrade_request';
  bool get isNewArtistSignup => type == 'new_artist_signup';

  // Get session date from data if available
  DateTime? get sessionDate {
    if (data != null && data!['sessionDate'] != null) {
      final timestamp = data!['sessionDate'] as Timestamp;
      return timestamp.toDate();
    }
    return null;
  }

  // Get submission info from data if available
  String? get submissionId => data?['submissionId'];
  String? get portraitTitle => data?['portraitTitle'];
  String? get sessionId => data?['sessionId'];
  int? get totalSubmissions => data?['totalSubmissions'];

  // Get upgrade request info from data if available
  String? get requestingUserId => data?['requestingUserId'];
  String? get requestingUserName => data?['requestingUserName'];
  String? get action => data?['action'];

  // Get new artist signup info from data if available
  String? get newUserId => data?['newUserId'];
  String? get newUserName => data?['newUserName'];
} 