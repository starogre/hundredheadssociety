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

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
    required this.portraitIds,
    required this.portraitsCompleted,
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
    );
  }
} 