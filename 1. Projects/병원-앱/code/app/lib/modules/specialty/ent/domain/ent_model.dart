/// 이비인후과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// EntSymptom — 이비인후과 7종 증상
// ──────────────────────────────────────────────────────────────────────────────

enum EntSymptom {
  soreThoat,    // 인후통
  nasalCongestion, // 비충혈
  runnyNose,    // 콧물
  earPain,      // 귀통증
  hearingLoss,  // 청력저하
  tinnitus,     // 이명
  dizziness,    // 어지럼증
}

extension EntSymptomX on EntSymptom {
  String get label {
    switch (this) {
      case EntSymptom.soreThoat:     return '인후통';
      case EntSymptom.nasalCongestion: return '비충혈';
      case EntSymptom.runnyNose:     return '콧물';
      case EntSymptom.earPain:       return '귀통증';
      case EntSymptom.hearingLoss:   return '청력저하';
      case EntSymptom.tinnitus:      return '이명';
      case EntSymptom.dizziness:     return '어지럼증';
    }
  }

  String get apiKey => name;
}

// ──────────────────────────────────────────────────────────────────────────────
// SymptomLogModel — 증상 일지 기록
// ──────────────────────────────────────────────────────────────────────────────

class SymptomLogModel {
  const SymptomLogModel({
    required this.id,
    required this.recordedAt,
    required this.symptoms,
    required this.intensities, // symptom apiKey → 1~10
    this.memo,
  });

  final String id;
  final DateTime recordedAt;
  final List<EntSymptom> symptoms;
  final Map<String, int> intensities;
  final String? memo;

  int intensityOf(EntSymptom s) => intensities[s.apiKey] ?? 1;

  factory SymptomLogModel.fromJson(Map<String, dynamic> json) {
    final rawSymptoms = (json['symptoms'] as List<dynamic>?) ?? [];
    final rawIntensities =
        (json['intensities'] as Map<String, dynamic>?) ?? {};
    return SymptomLogModel(
      id: json['id'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      symptoms: rawSymptoms
          .map((s) => EntSymptom.values.firstWhere(
                (e) => e.apiKey == s,
                orElse: () => EntSymptom.soreThoat,
              ))
          .toList(),
      intensities: rawIntensities.map((k, v) => MapEntry(k, (v as num).toInt())),
      memo: json['memo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'symptoms': symptoms.map((s) => s.apiKey).toList(),
        'intensities': intensities,
        if (memo != null) 'memo': memo,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// AllergyModel — 알레르기 항목
// ──────────────────────────────────────────────────────────────────────────────

class AllergyModel {
  const AllergyModel({
    required this.id,
    required this.name,
    required this.allergen,
    this.severity,
    this.diagnosedAt,
    this.notes,
  });

  final String id;
  final String name;      // 예: 꽃가루 알레르기
  final String allergen;  // 예: 수목화분
  final String? severity; // mild | moderate | severe
  final DateTime? diagnosedAt;
  final String? notes;

  factory AllergyModel.fromJson(Map<String, dynamic> json) => AllergyModel(
        id: json['id'] as String,
        name: json['name'] as String,
        allergen: json['allergen'] as String,
        severity: json['severity'] as String?,
        diagnosedAt: json['diagnosed_at'] != null
            ? DateTime.parse(json['diagnosed_at'] as String)
            : null,
        notes: json['notes'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// SeasonAlertModel — 시즌 알림
// ──────────────────────────────────────────────────────────────────────────────

class SeasonAlertModel {
  const SeasonAlertModel({
    required this.id,
    required this.title,
    required this.body,
    required this.season,
    this.iconCode,
  });

  final String id;
  final String title;
  final String body;
  final String season; // spring | summer | fall | winter
  final int? iconCode;
}

// ──────────────────────────────────────────────────────────────────────────────
// AddSymptomLogDto
// ──────────────────────────────────────────────────────────────────────────────

class AddSymptomLogDto {
  const AddSymptomLogDto({
    required this.symptoms,
    required this.intensities,
    this.memo,
  });

  final List<EntSymptom> symptoms;
  final Map<String, int> intensities;
  final String? memo;

  Map<String, dynamic> toJson() => {
        'recorded_at': DateTime.now().toIso8601String(),
        'symptoms': symptoms.map((s) => s.apiKey).toList(),
        'intensities': intensities,
        if (memo != null) 'memo': memo,
      };
}
