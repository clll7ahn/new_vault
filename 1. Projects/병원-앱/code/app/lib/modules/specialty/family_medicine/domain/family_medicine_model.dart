/// 가정의학과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// HealthCheckResultModel — 건강검진 결과
// ──────────────────────────────────────────────────────────────────────────────

enum RiskLevel { normal, caution, danger }

extension RiskLevelX on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.normal:  return '정상';
      case RiskLevel.caution: return '주의';
      case RiskLevel.danger:  return '위험';
    }
  }

  static RiskLevel fromString(String? v) {
    switch (v) {
      case 'caution': return RiskLevel.caution;
      case 'danger':  return RiskLevel.danger;
      default:        return RiskLevel.normal;
    }
  }
}

class CheckResultItem {
  const CheckResultItem({
    required this.name,
    required this.value,
    required this.unit,
    required this.riskLevel,
    this.referenceRange,
  });

  final String name;
  final double value;
  final String unit;
  final RiskLevel riskLevel;
  final String? referenceRange;

  factory CheckResultItem.fromJson(Map<String, dynamic> json) =>
      CheckResultItem(
        name: json['name'] as String,
        value: (json['value'] as num).toDouble(),
        unit: json['unit'] as String,
        riskLevel: RiskLevelX.fromString(json['risk_level'] as String?),
        referenceRange: json['reference_range'] as String?,
      );
}

class HealthCheckResultModel {
  const HealthCheckResultModel({
    required this.id,
    required this.checkDate,
    required this.items,
    this.hospitalName,
    this.overallRisk,
  });

  final String id;
  final DateTime checkDate;
  final List<CheckResultItem> items;
  final String? hospitalName;
  final RiskLevel? overallRisk;

  factory HealthCheckResultModel.fromJson(Map<String, dynamic> json) =>
      HealthCheckResultModel(
        id: json['id'] as String,
        checkDate: DateTime.parse(json['check_date'] as String),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => CheckResultItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        hospitalName: json['hospital_name'] as String?,
        overallRisk: json['overall_risk'] != null
            ? RiskLevelX.fromString(json['overall_risk'] as String)
            : null,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// LifestyleTracker — 생활습관 트래커 (금주/금연/운동/식단)
// ──────────────────────────────────────────────────────────────────────────────

enum LifestyleCategory { alcohol, smoking, exercise, diet }

extension LifestyleCategoryX on LifestyleCategory {
  String get label {
    switch (this) {
      case LifestyleCategory.alcohol:  return '금주';
      case LifestyleCategory.smoking:  return '금연';
      case LifestyleCategory.exercise: return '운동';
      case LifestyleCategory.diet:     return '식단';
    }
  }

  String get apiKey => name;
}

class LifestyleLogModel {
  const LifestyleLogModel({
    required this.id,
    required this.recordedAt,
    required this.category,
    required this.achieved, // 목표 달성 여부
    this.note,
    this.value, // 예: 운동 분수
  });

  final String id;
  final DateTime recordedAt;
  final LifestyleCategory category;
  final bool achieved;
  final String? note;
  final double? value;

  factory LifestyleLogModel.fromJson(Map<String, dynamic> json) =>
      LifestyleLogModel(
        id: json['id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        category: LifestyleCategory.values.firstWhere(
          (c) => c.apiKey == json['category'],
          orElse: () => LifestyleCategory.exercise,
        ),
        achieved: json['achieved'] as bool? ?? false,
        note: json['note'] as String?,
        value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'category': category.apiKey,
        'achieved': achieved,
        if (note != null) 'note': note,
        if (value != null) 'value': value,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// BmiRecordModel — BMI 기록
// ──────────────────────────────────────────────────────────────────────────────

class BmiRecordModel {
  const BmiRecordModel({
    required this.id,
    required this.recordedAt,
    required this.weightKg,
    required this.heightCm,
  });

  final String id;
  final DateTime recordedAt;
  final double weightKg;
  final double heightCm;

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return '저체중';
    if (b < 23.0) return '정상';
    if (b < 25.0) return '과체중';
    if (b < 30.0) return '비만 1단계';
    return '비만 2단계';
  }

  factory BmiRecordModel.fromJson(Map<String, dynamic> json) => BmiRecordModel(
        id: json['id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        weightKg: (json['weight_kg'] as num).toDouble(),
        heightCm: (json['height_cm'] as num).toDouble(),
      );
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

class AddLifestyleLogDto {
  const AddLifestyleLogDto({
    required this.category,
    required this.achieved,
    this.note,
    this.value,
  });
  final LifestyleCategory category;
  final bool achieved;
  final String? note;
  final double? value;

  Map<String, dynamic> toJson() => {
        'recorded_at': DateTime.now().toIso8601String(),
        'category': category.apiKey,
        'achieved': achieved,
        if (note != null) 'note': note,
        if (value != null) 'value': value,
      };
}

class AddBmiRecordDto {
  const AddBmiRecordDto({required this.weightKg, required this.heightCm});
  final double weightKg;
  final double heightCm;

  Map<String, dynamic> toJson() => {
        'recorded_at': DateTime.now().toIso8601String(),
        'weight_kg': weightKg,
        'height_cm': heightCm,
      };
}
