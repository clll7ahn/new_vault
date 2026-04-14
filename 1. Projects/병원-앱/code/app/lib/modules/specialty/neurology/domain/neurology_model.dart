/// 신경과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// HeadacheType — 두통 유형
// ──────────────────────────────────────────────────────────────────────────────

enum HeadacheType { migraine, tension, cluster, other }

extension HeadacheTypeX on HeadacheType {
  String get label {
    switch (this) {
      case HeadacheType.migraine: return '편두통';
      case HeadacheType.tension:  return '긴장형';
      case HeadacheType.cluster:  return '군발성';
      case HeadacheType.other:    return '기타';
    }
  }

  String get apiKey => name;
}

// ──────────────────────────────────────────────────────────────────────────────
// HeadacheLocation — 두통 부위
// ──────────────────────────────────────────────────────────────────────────────

enum HeadacheLocation { frontLeft, frontRight, occipital, temporal, whole }

extension HeadacheLocationX on HeadacheLocation {
  String get label {
    switch (this) {
      case HeadacheLocation.frontLeft:  return '왼쪽 앞';
      case HeadacheLocation.frontRight: return '오른쪽 앞';
      case HeadacheLocation.occipital:  return '후두부';
      case HeadacheLocation.temporal:   return '측두부';
      case HeadacheLocation.whole:      return '전체';
    }
  }

  String get apiKey => name;
}

// ──────────────────────────────────────────────────────────────────────────────
// HeadacheTrigger — 두통 트리거
// ──────────────────────────────────────────────────────────────────────────────

enum HeadacheTrigger { stress, sleep, food, light, noise, weather, hormone, unknown }

extension HeadacheTriggerX on HeadacheTrigger {
  String get label {
    switch (this) {
      case HeadacheTrigger.stress:  return '스트레스';
      case HeadacheTrigger.sleep:   return '수면 부족';
      case HeadacheTrigger.food:    return '음식/음료';
      case HeadacheTrigger.light:   return '빛 자극';
      case HeadacheTrigger.noise:   return '소음';
      case HeadacheTrigger.weather: return '날씨 변화';
      case HeadacheTrigger.hormone: return '호르몬';
      case HeadacheTrigger.unknown: return '불명';
    }
  }

  String get apiKey => name;
}

// ──────────────────────────────────────────────────────────────────────────────
// HeadacheLogModel
// ──────────────────────────────────────────────────────────────────────────────

class HeadacheLogModel {
  const HeadacheLogModel({
    required this.id,
    required this.recordedAt,
    required this.type,
    required this.location,
    required this.intensity, // 1~10
    this.triggers,
    this.durationMinutes,
    this.note,
  });

  final String id;
  final DateTime recordedAt;
  final HeadacheType type;
  final HeadacheLocation location;
  final int intensity;
  final List<HeadacheTrigger>? triggers;
  final int? durationMinutes;
  final String? note;

  factory HeadacheLogModel.fromJson(Map<String, dynamic> json) {
    final rawTriggers = (json['triggers'] as List<dynamic>?) ?? [];
    return HeadacheLogModel(
      id: json['id'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      type: HeadacheType.values.firstWhere(
        (t) => t.apiKey == json['type'],
        orElse: () => HeadacheType.other,
      ),
      location: HeadacheLocation.values.firstWhere(
        (l) => l.apiKey == json['location'],
        orElse: () => HeadacheLocation.whole,
      ),
      intensity: (json['intensity'] as num).toInt(),
      triggers: rawTriggers
          .map((r) => HeadacheTrigger.values.firstWhere(
                (t) => t.apiKey == r,
                orElse: () => HeadacheTrigger.unknown,
              ))
          .toList(),
      durationMinutes: json['duration_minutes'] as int?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'type': type.apiKey,
        'location': location.apiKey,
        'intensity': intensity,
        if (triggers != null) 'triggers': triggers!.map((t) => t.apiKey).toList(),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (note != null) 'note': note,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// CognitivScoreModel — 인지기능 점수
// ──────────────────────────────────────────────────────────────────────────────

class CognitivScoreModel {
  const CognitivScoreModel({
    required this.id,
    required this.assessedAt,
    required this.score,       // 0~30 (MMSE 기준)
    required this.maxScore,
    required this.testName,
    this.interpretation,
  });

  final String id;
  final DateTime assessedAt;
  final int score;
  final int maxScore;
  final String testName;
  final String? interpretation;

  double get ratio => score / maxScore;

  factory CognitivScoreModel.fromJson(Map<String, dynamic> json) =>
      CognitivScoreModel(
        id: json['id'] as String,
        assessedAt: DateTime.parse(json['assessed_at'] as String),
        score: (json['score'] as num).toInt(),
        maxScore: (json['max_score'] as num).toInt(),
        testName: json['test_name'] as String,
        interpretation: json['interpretation'] as String?,
      );
}

// ── DTO ──────────────────────────────────────────────────────────────────────

class AddHeadacheLogDto {
  const AddHeadacheLogDto({
    required this.type,
    required this.location,
    required this.intensity,
    this.triggers,
    this.durationMinutes,
    this.note,
  });

  final HeadacheType type;
  final HeadacheLocation location;
  final int intensity;
  final List<HeadacheTrigger>? triggers;
  final int? durationMinutes;
  final String? note;

  Map<String, dynamic> toJson() => {
        'recorded_at': DateTime.now().toIso8601String(),
        'type': type.apiKey,
        'location': location.apiKey,
        'intensity': intensity,
        if (triggers != null) 'triggers': triggers!.map((t) => t.apiKey).toList(),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (note != null) 'note': note,
      };
}
