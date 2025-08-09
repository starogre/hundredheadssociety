import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final DateTime createdAt;
  final List<String> portraitIds;
  final int portraitsCompleted;
  final bool isAdmin;
  final String status; // 'pending', 'approved', 'denied'
  final String? instagram;
  final String? contactEmail;
  // User roles and permissions
  final String userRole; // 'art_appreciator', 'artist' - chosen during signup
  final bool isModerator; // assigned by admin only
  final List<String> awards; // List of award IDs
  final int totalVotesCast;
  final int portraitAwardCount; // Total number of portrait awards won
  final DateTime? lastActiveAt;
  final bool emailVerified; // Track email verification status
  final DateTime? lastVerificationTimestamp; // Track when user last verified email
  // Notification preferences
  final Map<String, bool> notificationPreferences; // Key: notification type, Value: enabled/disabled

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
    this.portraitIds = const <String>[],
    this.portraitsCompleted = 0,
    this.isAdmin = false,
    this.status = 'pending',
    this.instagram,
    this.contactEmail,
    this.userRole = 'artist',
    this.isModerator = false,
    this.awards = const <String>[],
    this.totalVotesCast = 0,
    this.portraitAwardCount = 0,
    this.lastActiveAt,
    this.emailVerified = false, // Initialize emailVerified
    this.lastVerificationTimestamp, // Initialize lastVerificationTimestamp
    this.notificationPreferences = const {}, // Initialize notification preferences
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      bio: map['bio'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      portraitIds: List<String>.from(map['portraitIds'] ?? []),
      portraitsCompleted: map['portraitsCompleted'] ?? 0,
      isAdmin: map['isAdmin'] ?? false,
      status: map['status'] ?? 'pending',
      instagram: map['instagram'],
      contactEmail: map['contactEmail'],
      userRole: map['userRole'] ?? 'artist', // Default existing users to artist
      isModerator: map['isModerator'] ?? false,
      awards: List<String>.from(map['awards'] ?? []),
      totalVotesCast: map['totalVotesCast'] ?? 0,
      portraitAwardCount: map['portraitAwardCount'] ?? 0,
      lastActiveAt: map['lastActiveAt'] != null 
          ? (map['lastActiveAt'] as Timestamp).toDate() 
          : null,
      emailVerified: map['emailVerified'] ?? false, // Parse emailVerified
      lastVerificationTimestamp: map['lastVerificationTimestamp'] != null
          ? (map['lastVerificationTimestamp'] as Timestamp).toDate()
          : null, // Parse lastVerificationTimestamp
      notificationPreferences: Map<String, bool>.from(map['notificationPreferences'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'portraitIds': portraitIds,
      'portraitsCompleted': portraitsCompleted,
      'isAdmin': isAdmin,
      'status': status,
      'instagram': instagram,
      'contactEmail': contactEmail,
      'userRole': userRole,
      'isModerator': isModerator,
      'awards': awards,
      'totalVotesCast': totalVotesCast,
      'portraitAwardCount': portraitAwardCount,
      'lastActiveAt': lastActiveAt,
      'emailVerified': emailVerified, // Include emailVerified in toMap
      'lastVerificationTimestamp': lastVerificationTimestamp, // Include lastVerificationTimestamp in toMap
      'notificationPreferences': notificationPreferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? profileImageUrl,
    DateTime? createdAt,
    List<String>? portraitIds,
    int? portraitsCompleted,
    bool? isAdmin,
    String? status,
    String? instagram,
    String? contactEmail,
    String? userRole,
    bool? isModerator,
    List<String>? awards,
    int? totalVotesCast,
    DateTime? lastActiveAt,
    bool? emailVerified, // Add emailVerified to copyWith
    DateTime? lastVerificationTimestamp, // Add lastVerificationTimestamp to copyWith
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      portraitIds: portraitIds ?? this.portraitIds,
      portraitsCompleted: portraitsCompleted ?? this.portraitsCompleted,
      isAdmin: isAdmin ?? this.isAdmin,
      status: status ?? this.status,
      instagram: instagram ?? this.instagram,
      contactEmail: contactEmail ?? this.contactEmail,
      userRole: userRole ?? this.userRole,
      isModerator: isModerator ?? this.isModerator,
      awards: awards ?? this.awards,
      totalVotesCast: totalVotesCast ?? this.totalVotesCast,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      emailVerified: emailVerified ?? this.emailVerified, // Copy emailVerified
      lastVerificationTimestamp: lastVerificationTimestamp ?? this.lastVerificationTimestamp, // Copy lastVerificationTimestamp
    );
  }

  // Helper methods for role-based access control
  bool get isArtist => userRole == 'artist';
  bool get isArtAppreciator => userRole == 'art_appreciator';
  bool get hasModeratorAccess => isModerator || isAdmin;
  bool get hasAdminAccess => isAdmin;
  
  // Check if user can access specific features
  bool canCreatePortraits() => isArtist || hasModeratorAccess;
  bool canVote() => true; // Both roles can vote
  bool canModerate() => hasModeratorAccess;
  bool canManageUsers() => hasAdminAccess;
  bool canManageSessions() => hasModeratorAccess;
} 