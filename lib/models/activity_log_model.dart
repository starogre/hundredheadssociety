import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String action; // e.g., 'user_approved', 'user_signup', 'user_deleted', 'user_edited', 'role_changed'
  final String performedBy; // User ID who performed the action
  final String performedByName; // Name of user who performed the action
  final String? targetUserId; // User ID affected by the action (if applicable)
  final String? targetUserName; // Name of user affected by the action (if applicable)
  final Map<String, dynamic>? details; // Additional details about the action
  final DateTime timestamp;

  ActivityLogModel({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.performedByName,
    this.targetUserId,
    this.targetUserName,
    this.details,
    required this.timestamp,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLogModel(
      id: id,
      action: map['action'] ?? '',
      performedBy: map['performedBy'] ?? '',
      performedByName: map['performedByName'] ?? '',
      targetUserId: map['targetUserId'],
      targetUserName: map['targetUserName'],
      details: map['details'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'details': details,
      'timestamp': timestamp,
    };
  }

  // Helper method to get a human-readable description
  String get description {
    switch (action) {
      case 'user_approved':
        return '$performedByName approved $targetUserName as an Artist';
      case 'user_signup':
        return '$targetUserName signed up and verified their email';
      case 'user_deleted':
        return '$performedByName deleted user $targetUserName';
      case 'user_edited':
        return '$performedByName edited user $targetUserName';
      case 'role_changed':
        final newRole = details?['newRole'] ?? 'unknown';
        final oldRole = details?['oldRole'] ?? 'unknown';
        return '$performedByName changed $targetUserName from $oldRole to $newRole';
      case 'moderator_granted':
        return '$performedByName granted moderator status to $targetUserName';
      case 'moderator_removed':
        return '$performedByName removed moderator status from $targetUserName';
      default:
        return '$performedByName performed action: $action';
    }
  }
} 