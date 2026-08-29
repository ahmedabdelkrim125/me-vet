import 'dart:convert';

import 'notification_type.dart';

class AppNotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
  });

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'relatedId': relatedId,
    };
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => NotificationType.dailyReportReminder,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      relatedId: json['relatedId'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AppNotificationModel.fromJsonString(String raw) {
    return AppNotificationModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  /// يبني الموديل من صف جدول `notifications` في Supabase.
  factory AppNotificationModel.fromSupabaseRow(Map<String, dynamic> row) {
    return AppNotificationModel(
      id: row['id'] as String,
      type: notificationTypeFromDb(row['type'] as String?),
      title: row['title'] as String,
      message: row['message'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      isRead: row['is_read'] as bool? ?? false,
      relatedId: row['related_id'] as String?,
    );
  }
}
