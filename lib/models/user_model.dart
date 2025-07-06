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
  final DateTime? lastActiveAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
    required this.portraitIds,
    required this.portraitsCompleted,
    this.isAdmin = false,
    this.status = 'pending', // Default to pending for new users
    this.instagram,
    this.contactEmail,
    required this.userRole, // Required - user must choose during signup
    this.isModerator = false, // Admin-assigned moderator status only
    this.awards = const [],
    this.totalVotesCast = 0,
    this.lastActiveAt,
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
      lastActiveAt: map['lastActiveAt'] != null 
          ? (map['lastActiveAt'] as Timestamp).toDate() 
          : null,
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
      'lastActiveAt': lastActiveAt,
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