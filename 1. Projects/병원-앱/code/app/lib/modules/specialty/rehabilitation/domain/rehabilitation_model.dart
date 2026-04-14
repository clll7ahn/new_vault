/// 재활의학과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// EvalScoreModel — 평가 점수 (ROM/근력/ADL)
// ──────────────────────────────────────────────────────────────────────────────

enum EvalCategory { rom, strength, adl }

extension EvalCategoryX on EvalCategory {
  String get label {
    switch (this) {
      case EvalCategory.rom:      return 'ROM (관절가동범위)';
      case EvalCategory.strength: return '근력';
      case EvalCategory.adl:      return 'ADL (일상생활동작)';
    }
  }

  String get shortLabel {
    switch (this) {
      case EvalCategory.rom:      return 'ROM';
      case EvalCategory.strength: return '근력';
      case EvalCategory.adl:      return 'ADL';
    }
  }

  String get apiKey => name;
}

class EvalScoreModel {
  const EvalScoreModel({
    required this.id,
    required this.category,
    required this.assessedAt,
    required this.score,
    required this.maxScore,
    this.bodyPart,
    this.note,
  });

  final String id;
  final EvalCategory category;
  final DateTime assessedAt;
  final double score;
  final double maxScore;
  final String? bodyPart;
  final String? note;

  double get ratio => (score / maxScore).clamp(0.0, 1.0);

  factory EvalScoreModel.fromJson(Map<String, dynamic> json) => EvalScoreModel(
        id: json['id'] as String,
        category: EvalCategory.values.firstWhere(
          (c) => c.apiKey == json['category'],
          orElse: () => EvalCategory.adl,
        ),
        assessedAt: DateTime.parse(json['assessed_at'] as String),
        score: (json['score'] as num).toDouble(),
        maxScore: (json['max_score'] as num).toDouble(),
        bodyPart: json['body_part'] as String?,
        note: json['note'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// RehabExerciseModel — 재활 운동 체크리스트 아이템
// ──────────────────────────────────────────────────────────────────────────────

class RehabExerciseModel {
  const RehabExerciseModel({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    this.description,
    this.targetBodyPart,
  });

  final String id;
  final String name;
  final int sets;
  final int reps;
  final String? description;
  final String? targetBodyPart;

  factory RehabExerciseModel.fromJson(Map<String, dynamic> json) =>
      RehabExerciseModel(
        id: json['id'] as String,
        name: json['name'] as String,
        sets: (json['sets'] as num).toInt(),
        reps: (json['reps'] as num).toInt(),
        description: json['description'] as String?,
        targetBodyPart: json['target_body_part'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// SessionPainLogModel — 세션별 통증 변화
// ──────────────────────────────────────────────────────────────────────────────

class SessionPainLogModel {
  const SessionPainLogModel({
    required this.id,
    required this.sessionDate,
    required this.painBefore,  // VAS 0~10
    required this.painAfter,
    this.note,
  });

  final String id;
  final DateTime sessionDate;
  final int painBefore;
  final int painAfter;
  final String? note;

  int get painDelta => painAfter - painBefore; // 음수 = 호전

  factory SessionPainLogModel.fromJson(Map<String, dynamic> json) =>
      SessionPainLogModel(
        id: json['id'] as String,
        sessionDate: DateTime.parse(json['session_date'] as String),
        painBefore: (json['pain_before'] as num).toInt(),
        painAfter: (json['pain_after'] as num).toInt(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_date': sessionDate.toIso8601String().substring(0, 10),
        'pain_before': painBefore,
        'pain_after': painAfter,
        if (note != null) 'note': note,
      };
}

// ── DTO ──────────────────────────────────────────────────────────────────────

class AddSessionPainLogDto {
  const AddSessionPainLogDto({
    required this.painBefore,
    required this.painAfter,
    this.note,
  });

  final int painBefore;
  final int painAfter;
  final String? note;

  Map<String, dynamic> toJson() => {
        'session_date': DateTime.now().toIso8601String().substring(0, 10),
        'pain_before': painBefore,
        'pain_after': painAfter,
        if (note != null) 'note': note,
      };
}
