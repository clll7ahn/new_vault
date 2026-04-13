/// 알림 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// NotificationType
// ──────────────────────────────────────────────────────────────────────────────

enum NotificationType {
  appointment, // 예약 알림
  queue,       // 대기 알림
  message,     // 메시지 알림
  system,      // 시스템 알림
}

extension NotificationTypeX on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.appointment:
        return '예약';
      case NotificationType.queue:
        return '대기';
      case NotificationType.message:
        return '메시지';
      case NotificationType.system:
        return '시스템';
    }
  }

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'appointment':
        return NotificationType.appointment;
      case 'queue':
        return NotificationType.queue;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.system;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// NotificationModel
// ──────────────────────────────────────────────────────────────────────────────

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationTypeX.fromString(json['type'] as String?),
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        if (data != null) 'data': data,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// NotificationPage — 페이지네이션 결과
// ──────────────────────────────────────────────────────────────────────────────

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.total,
  });

  final List<NotificationModel> items;
  final int total;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    return NotificationPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}
