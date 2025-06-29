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
    );
  }
} 