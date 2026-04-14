/// 정신건강 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// MoodLevel — 기분 수준 (이모지 기반)
// ──────────────────────────────────────────────────────────────────────────────

enum MoodLevel {
  veryBad,    // 매우 나쁨
  bad,        // 나쁨
  neutral,    // 보통
  good,       // 좋음
  veryGood,   // 매우 좋음
}

extension MoodLevelX on MoodLevel {
  String get emoji {
    switch (this) {
      case MoodLevel.veryBad:
        return '😢';
      case MoodLevel.bad:
        return '😟';
      case MoodLevel.neutral:
        return '😐';
      case MoodLevel.good:
        return '🙂';
      case MoodLevel.veryGood:
        return '😄';
    }
  }

  String get label {
    switch (this) {
      case MoodLevel.veryBad:
        return '매우 나쁨';
      case MoodLevel.bad:
        return '나쁨';
      case MoodLevel.neutral:
        return '보통';
      case MoodLevel.good:
        return '좋음';
      case MoodLevel.veryGood:
        return '매우 좋음';
    }
  }

  int get score => index + 1; // 1~5

  static MoodLevel fromScore(int score) {
    return MoodLevel.values[(score - 1).clamp(0, 4)];
  }

  static MoodLevel fromString(String? v) {
    switch (v) {
      case 'very_bad':
        return MoodLevel.veryBad;
      case 'bad':
        return MoodLevel.bad;
      case 'good':
        return MoodLevel.good;
      case 'very_good':
        return MoodLevel.veryGood;
      default:
        return MoodLevel.neutral;
    }
  }

  String get apiKey {
    switch (this) {
      case MoodLevel.veryBad:
        return 'very_bad';
      case MoodLevel.bad:
        return 'bad';
      case MoodLevel.neutral:
        return 'neutral';
      case MoodLevel.good:
        return 'good';
      case MoodLevel.veryGood:
        return 'very_good';
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MoodLogModel — 기분 기록
// ──────────────────────────────────────────────────────────────────────────────

class MoodLogModel {
  const MoodLogModel({
    required this.id,
    required this.recordedAt,
    required this.mood,
    this.memo,
    this.tags,
  });

  final String id;
  final DateTime recordedAt;
  final MoodLevel mood;
  final String? memo;
  final List<String>? tags; // 감정 태그 (예: ['불안', '피곤'])

  factory MoodLogModel.fromJson(Map<String, dynamic> json) => MoodLogModel(
        id: json['id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        mood: MoodLevelX.fromString(json['mood'] as String?),
        memo: json['memo'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'mood': mood.apiKey,
        if (memo != null) 'memo': memo,
        if (tags != null) 'tags': tags,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// SleepLogModel — 수면 일지
// ──────────────────────────────────────────────────────────────────────────────

class SleepLogModel {
  const SleepLogModel({
    required this.id,
    required this.bedtime,
    required this.wakeTime,
    this.sleepQuality,  // 1~5
    this.notes,
  });

  final String id;
  final DateTime bedtime;
  final DateTime wakeTime;
  final int? sleepQuality;
  final String? notes;

  double get durationHours =>
      wakeTime.difference(bedtime).inMinutes / 60.0;

  String get durationLabel {
    final h = durationHours.floor();
    final m = ((durationHours - h) * 60).round();
    return m == 0 ? '$h시간' : '$h시간 $m분';
  }

  factory SleepLogModel.fromJson(Map<String, dynamic> json) => SleepLogModel(
        id: json['id'] as String,
        bedtime: DateTime.parse(json['bedtime'] as String),
        wakeTime: DateTime.parse(json['wake_time'] as String),
        sleepQuality: json['sleep_quality'] as int?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bedtime': bedtime.toIso8601String(),
        'wake_time': wakeTime.toIso8601String(),
        if (sleepQuality != null) 'sleep_quality': sleepQuality,
        if (notes != null) 'notes': notes,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// MedReactionModel — 약물 반응 기록
// ──────────────────────────────────────────────────────────────────────────────

class MedReactionModel {
  const MedReactionModel({
    required this.id,
    required this.medicationName,
    required this.recordedAt,
    required this.reactionDescription,
    this.severity,   // 1~5
    this.sideEffects,
  });

  final String id;
  final String medicationName;
  final DateTime recordedAt;
  final String reactionDescription;
  final int? severity;
  final List<String>? sideEffects;

  factory MedReactionModel.fromJson(Map<String, dynamic> json) =>
      MedReactionModel(
        id: json['id'] as String,
        medicationName: json['medication_name'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        reactionDescription: json['reaction_description'] as String,
        severity: json['severity'] as int?,
        sideEffects:
            (json['side_effects'] as List<dynamic>?)?.cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'medication_name': medicationName,
        'recorded_at': recordedAt.toIso8601String(),
        'reaction_description': reactionDescription,
        if (severity != null) 'severity': severity,
        if (sideEffects != null) 'side_effects': sideEffects,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// CounselingNoteModel — 상담 노트
// ──────────────────────────────────────────────────────────────────────────────

class CounselingNoteModel {
  const CounselingNoteModel({
    required this.id,
    required this.sessionDate,
    required this.summary,
    this.therapistName,
    this.homework,
    this.nextSessionDate,
  });

  final String id;
  final DateTime sessionDate;
  final String summary;
  final String? therapistName;
  final String? homework;
  final DateTime? nextSessionDate;

  factory CounselingNoteModel.fromJson(Map<String, dynamic> json) =>
      CounselingNoteModel(
        id: json['id'] as String,
        sessionDate: DateTime.parse(json['session_date'] as String),
        summary: json['summary'] as String,
        therapistName: json['therapist_name'] as String?,
        homework: json['homework'] as String?,
        nextSessionDate: json['next_session_date'] != null
            ? DateTime.parse(json['next_session_date'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_date': sessionDate.toIso8601String().substring(0, 10),
        'summary': summary,
        if (therapistName != null) 'therapist_name': therapistName,
        if (homework != null) 'homework': homework,
        if (nextSessionDate != null)
          'next_session_date':
              nextSessionDate!.toIso8601String().substring(0, 10),
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// CrisisResource — 위기 상담 리소스
// ──────────────────────────────────────────────────────────────────────────────

class CrisisResource {
  const CrisisResource({
    required this.name,
    required this.phoneNumber,
    required this.description,
    this.available24h = true,
  });

  final String name;
  final String phoneNumber;
  final String description;
  final bool available24h;
}

// 기본 위기 상담 리소스 (하드코딩 — 공식 번호)
const kDefaultCrisisResources = [
  CrisisResource(
    name: '정신건강 위기상담 전화',
    phoneNumber: '1577-0199',
    description: '24시간 자살예방 및 정신건강 위기상담',
    available24h: true,
  ),
  CrisisResource(
    name: '자살예방상담전화',
    phoneNumber: '1393',
    description: '자살 위기 상담 및 사후관리',
    available24h: true,
  ),
  CrisisResource(
    name: '생명의전화',
    phoneNumber: '1588-9191',
    description: '자살예방 및 위기상담',
    available24h: true,
  ),
  CrisisResource(
    name: '청소년 전화',
    phoneNumber: '1388',
    description: '청소년 위기상담',
    available24h: true,
  ),
];

// ──────────────────────────────────────────────────────────────────────────────
// AddMoodLogDto
// ──────────────────────────────────────────────────────────────────────────────

class AddMoodLogDto {
  const AddMoodLogDto({required this.mood, this.memo, this.tags});
  final MoodLevel mood;
  final String? memo;
  final List<String>? tags;

  Map<String, dynamic> toJson() => {
        'mood': mood.apiKey,
        'recorded_at': DateTime.now().toIso8601String(),
        if (memo != null) 'memo': memo,
        if (tags != null) 'tags': tags,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// AddSleepLogDto
// ──────────────────────────────────────────────────────────────────────────────

class AddSleepLogDto {
  const AddSleepLogDto({
    required this.bedtime,
    required this.wakeTime,
    this.sleepQuality,
  });
  final DateTime bedtime;
  final DateTime wakeTime;
  final int? sleepQuality;

  Map<String, dynamic> toJson() => {
        'bedtime': bedtime.toIso8601String(),
        'wake_time': wakeTime.toIso8601String(),
        if (sleepQuality != null) 'sleep_quality': sleepQuality,
      };
}
