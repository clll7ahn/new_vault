/// 정형외과 전문 모듈 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// BodyPart — 통증 발생 신체 부위
// ──────────────────────────────────────────────────────────────────────────────

enum BodyPart {
  neck,        // 목
  shoulder,    // 어깨
  upperBack,   // 상부 등
  lowerBack,   // 하부 등
  hip,         // 고관절
  knee,        // 무릎
  ankle,       // 발목
  wrist,       // 손목
  elbow,       // 팔꿈치
  other,       // 기타
}

extension BodyPartX on BodyPart {
  String get label {
    switch (this) {
      case BodyPart.neck:
        return '목';
      case BodyPart.shoulder:
        return '어깨';
      case BodyPart.upperBack:
        return '상부 등';
      case BodyPart.lowerBack:
        return '하부 등/허리';
      case BodyPart.hip:
        return '고관절';
      case BodyPart.knee:
        return '무릎';
      case BodyPart.ankle:
        return '발목';
      case BodyPart.wrist:
        return '손목';
      case BodyPart.elbow:
        return '팔꿈치';
      case BodyPart.other:
        return '기타';
    }
  }

  static BodyPart fromString(String? v) {
    return BodyPart.values.firstWhere(
      (e) => e.name == v,
      orElse: () => BodyPart.other,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PainType — 통증 종류
// ──────────────────────────────────────────────────────────────────────────────

enum PainType { sharp, dull, throbbing, burning, aching }

extension PainTypeX on PainType {
  String get label {
    switch (this) {
      case PainType.sharp:
        return '찌르는 듯한';
      case PainType.dull:
        return '둔한';
      case PainType.throbbing:
        return '욱신욱신';
      case PainType.burning:
        return '타는 듯한';
      case PainType.aching:
        return '쑤시는';
    }
  }

  static PainType fromString(String? v) {
    return PainType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => PainType.dull,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PainLogModel — 통증 일지 기록
// ──────────────────────────────────────────────────────────────────────────────

class PainLogModel {
  const PainLogModel({
    required this.id,
    required this.bodyPart,
    required this.intensity,   // 1 ~ 10
    required this.recordedAt,
    this.painType,
    this.notes,
    this.triggers,             // 유발 요인: ['운동', '장시간 앉기']
  });

  final String id;
  final BodyPart bodyPart;
  final int intensity;
  final DateTime recordedAt;
  final PainType? painType;
  final String? notes;
  final List<String>? triggers;

  Color get intensityColor {
    if (intensity <= 3) return const Color(0xFF16A34A);
    if (intensity <= 6) return const Color(0xFFF97316);
    return const Color(0xFFDC2626);
  }

  factory PainLogModel.fromJson(Map<String, dynamic> json) => PainLogModel(
        id: json['id'] as String,
        bodyPart: BodyPartX.fromString(json['body_part'] as String?),
        intensity: json['intensity'] as int,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        painType: json['pain_type'] != null
            ? PainTypeX.fromString(json['pain_type'] as String?)
            : null,
        notes: json['notes'] as String?,
        triggers: (json['triggers'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'body_part': bodyPart.name,
        'intensity': intensity,
        'recorded_at': recordedAt.toIso8601String(),
        if (painType != null) 'pain_type': painType!.name,
        if (notes != null) 'notes': notes,
        if (triggers != null) 'triggers': triggers,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// PainTrendPoint — 통증 트렌드 차트용
// ──────────────────────────────────────────────────────────────────────────────

class PainTrendPoint {
  const PainTrendPoint({
    required this.date,
    required this.avgIntensity,
    required this.count,
  });

  final DateTime date;
  final double avgIntensity;
  final int count;

  factory PainTrendPoint.fromJson(Map<String, dynamic> json) => PainTrendPoint(
        date: DateTime.parse(json['date'] as String),
        avgIntensity: (json['avg_intensity'] as num).toDouble(),
        count: json['count'] as int? ?? 0,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// ExerciseModel — 재활 운동 단위
// ──────────────────────────────────────────────────────────────────────────────

class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    this.durationSeconds,
    this.description,
    this.videoUrl,
  });

  final String id;
  final String name;
  final int sets;
  final int? reps;
  final int? durationSeconds;  // reps 대신 시간 기반 운동
  final String? description;
  final String? videoUrl;

  String get specLabel {
    if (reps != null) return '$sets세트 × $reps회';
    if (durationSeconds != null) {
      return '$sets세트 × ${durationSeconds!}초';
    }
    return '$sets세트';
  }

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        id: json['id'] as String,
        name: json['name'] as String,
        sets: json['sets'] as int,
        reps: json['reps'] as int?,
        durationSeconds: json['duration_seconds'] as int?,
        description: json['description'] as String?,
        videoUrl: json['video_url'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// RehabProgramModel — 재활 프로그램
// ──────────────────────────────────────────────────────────────────────────────

class RehabProgramModel {
  const RehabProgramModel({
    required this.id,
    required this.name,
    required this.targetPart,
    required this.exercises,
    required this.startDate,
    this.endDate,
    this.description,
    this.frequencyPerWeek,
  });

  final String id;
  final String name;
  final BodyPart targetPart;
  final List<ExerciseModel> exercises;
  final DateTime startDate;
  final DateTime? endDate;
  final String? description;
  final int? frequencyPerWeek;

  bool get isActive {
    if (endDate == null) return true;
    return endDate!.isAfter(DateTime.now());
  }

  factory RehabProgramModel.fromJson(Map<String, dynamic> json) =>
      RehabProgramModel(
        id: json['id'] as String,
        name: json['name'] as String,
        targetPart: BodyPartX.fromString(json['target_part'] as String?),
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        description: json['description'] as String?,
        frequencyPerWeek: json['frequency_per_week'] as int?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// ExerciseLogModel — 운동 수행 기록
// ──────────────────────────────────────────────────────────────────────────────

class ExerciseLogModel {
  const ExerciseLogModel({
    required this.id,
    required this.programId,
    required this.exerciseId,
    required this.exerciseName,
    required this.completedSets,
    required this.loggedAt,
    this.notes,
  });

  final String id;
  final String programId;
  final String exerciseId;
  final String exerciseName;
  final int completedSets;
  final DateTime loggedAt;
  final String? notes;

  factory ExerciseLogModel.fromJson(Map<String, dynamic> json) =>
      ExerciseLogModel(
        id: json['id'] as String,
        programId: json['program_id'] as String,
        exerciseId: json['exercise_id'] as String,
        exerciseName: json['exercise_name'] as String,
        completedSets: json['completed_sets'] as int,
        loggedAt: DateTime.parse(json['logged_at'] as String),
        notes: json['notes'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// RehabAdherence — 재활 수행률
// ──────────────────────────────────────────────────────────────────────────────

class RehabAdherence {
  const RehabAdherence({
    required this.programId,
    required this.period,
    required this.scheduledSessions,
    required this.completedSessions,
  });

  final String programId;
  final String period;
  final int scheduledSessions;
  final int completedSessions;

  double get percent => scheduledSessions == 0
      ? 0
      : (completedSessions / scheduledSessions).clamp(0.0, 1.0);

  factory RehabAdherence.fromJson(Map<String, dynamic> json) => RehabAdherence(
        programId: json['program_id'] as String,
        period: json['period'] as String? ?? '30일',
        scheduledSessions: json['scheduled_sessions'] as int? ?? 0,
        completedSessions: json['completed_sessions'] as int? ?? 0,
      );
}
