import 'package:cloud_firestore/cloud_firestore.dart';

class PortraitModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String title;
  final String? description;
  final DateTime createdAt;
  final int weekNumber;

  PortraitModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.title,
    this.description,
    required this.createdAt,
    required this.weekNumber,
  });

  factory PortraitModel.fromMap(Map<String, dynamic> map, String id) {
    return PortraitModel(
      id: id,
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      weekNumber: map['weekNumber'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'createdAt': createdAt,
      'weekNumber': weekNumber,
    };
  }

  PortraitModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? title,
    String? description,
    DateTime? createdAt,
    int? weekNumber,
  }) {
    return PortraitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }
} 