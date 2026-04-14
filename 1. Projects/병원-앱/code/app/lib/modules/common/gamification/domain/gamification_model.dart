/// 게이미피케이션 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// MissionStatus
// ──────────────────────────────────────────────────────────────────────────────

enum MissionStatus { available, inProgress, completed, expired }

extension MissionStatusX on MissionStatus {
  String get label {
    switch (this) {
      case MissionStatus.available:
        return '참여 가능';
      case MissionStatus.inProgress:
        return '진행 중';
      case MissionStatus.completed:
        return '완료';
      case MissionStatus.expired:
        return '기간 만료';
    }
  }

  static MissionStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return MissionStatus.inProgress;
      case 'completed':
        return MissionStatus.completed;
      case 'expired':
        return MissionStatus.expired;
      default:
        return MissionStatus.available;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MissionType
// ──────────────────────────────────────────────────────────────────────────────

enum MissionType { daily, weekly, special }

extension MissionTypeX on MissionType {
  String get label {
    switch (this) {
      case MissionType.daily:
        return '일일';
      case MissionType.weekly:
        return '주간';
      case MissionType.special:
        return '특별';
    }
  }

  static MissionType fromString(String? value) {
    switch (value) {
      case 'weekly':
        return MissionType.weekly;
      case 'special':
        return MissionType.special;
      default:
        return MissionType.daily;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MissionModel
// ──────────────────────────────────────────────────────────────────────────────

class MissionModel {
  const MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.rewardPoints,
    required this.targetCount,
    required this.currentCount,
    required this.status,
    this.badgeId,
    this.expiresAt,
    this.iconCode,
  });

  final String id;
  final String title;
  final String description;
  final MissionType type;
  final int rewardPoints;
  final int targetCount;
  final int currentCount;
  final MissionStatus status;
  final String? badgeId;
  final DateTime? expiresAt;
  final int? iconCode; // IconData.codePoint

  double get progress =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == MissionStatus.completed;

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: MissionTypeX.fromString(json['type'] as String?),
      rewardPoints: json['reward_points'] as int? ?? 0,
      targetCount: json['target_count'] as int? ?? 1,
      currentCount: json['current_count'] as int? ?? 0,
      status: MissionStatusX.fromString(json['status'] as String?),
      badgeId: json['badge_id'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      iconCode: json['icon_code'] as int?,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BadgeModel
// ──────────────────────────────────────────────────────────────────────────────

class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isUnlocked,
    this.iconCode,
    this.color,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final bool isUnlocked;
  final int? iconCode;
  final String? color; // hex (e.g. "#FFD700")
  final DateTime? unlockedAt;

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      iconCode: json['icon_code'] as int?,
      color: json['color'] as String?,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PointHistoryModel
// ──────────────────────────────────────────────────────────────────────────────

enum PointChangeType { earn, spend }

class PointHistoryModel {
  const PointHistoryModel({
    required this.id,
    required this.points,
    required this.changeType,
    required this.reason,
    required this.createdAt,
    this.balance,
  });

  final String id;
  final int points;
  final PointChangeType changeType;
  final String reason;
  final DateTime createdAt;
  final int? balance; // 변경 후 잔액

  bool get isEarn => changeType == PointChangeType.earn;

  factory PointHistoryModel.fromJson(Map<String, dynamic> json) {
    return PointHistoryModel(
      id: json['id'] as String,
      points: (json['points'] as num).abs().toInt(),
      changeType: (json['change_type'] as String?) == 'spend'
          ? PointChangeType.spend
          : PointChangeType.earn,
      reason: json['reason'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      balance: json['balance'] as int?,
    );
  }
}
