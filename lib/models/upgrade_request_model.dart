import 'package:cloud_firestore/cloud_firestore.dart';

class UpgradeRequestModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final DateTime requestedAt;
  final String status; // 'pending', 'approved', 'denied'
  final String? adminId; // ID of admin who processed the request
  final String? adminName; // Name of admin who processed the request
  final DateTime? processedAt;
  final String? reason; // Reason for denial (if denied)

  UpgradeRequestModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.requestedAt,
    this.status = 'pending',
    this.adminId,
    this.adminName,
    this.processedAt,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status,
      'adminId': adminId,
      'adminName': adminName,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'reason': reason,
    };
  }

  factory UpgradeRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return UpgradeRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      adminId: map['adminId'],
      adminName: map['adminName'],
      processedAt: map['processedAt'] != null 
          ? (map['processedAt'] as Timestamp).toDate() 
          : null,
      reason: map['reason'],
    );
  }

  UpgradeRequestModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    DateTime? requestedAt,
    String? status,
    String? adminId,
    String? adminName,
    DateTime? processedAt,
    String? reason,
  }) {
    return UpgradeRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      processedAt: processedAt ?? this.processedAt,
      reason: reason ?? this.reason,
    );
  }
} 