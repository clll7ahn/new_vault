/// 소아과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// ChildModel — 자녀 정보
// ──────────────────────────────────────────────────────────────────────────────

class ChildModel {
  const ChildModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final DateTime birthDate;
  final String gender; // 'male' | 'female'
  final String? avatarUrl;

  int get ageMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 +
        (now.month - birthDate.month);
  }

  String get ageLabel {
    final months = ageMonths;
    if (months < 12) return '$months개월';
    final years = months ~/ 12;
    final rem = months % 12;
    return rem == 0 ? '$years세' : '$years세 $rem개월';
  }

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
        id: json['id'] as String,
        name: json['name'] as String,
        birthDate: DateTime.parse(json['birth_date'] as String),
        gender: json['gender'] as String? ?? 'unknown',
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birth_date': birthDate.toIso8601String().substring(0, 10),
        'gender': gender,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// GrowthLogModel — 성장 기록 (키/몸무게)
// ──────────────────────────────────────────────────────────────────────────────

class GrowthLogModel {
  const GrowthLogModel({
    required this.id,
    required this.childId,
    required this.measuredAt,
    required this.heightCm,
    required this.weightKg,
    this.headCircumferenceCm,
    this.heightPercentile,
    this.weightPercentile,
  });

  final String id;
  final String childId;
  final DateTime measuredAt;
  final double heightCm;
  final double weightKg;
  final double? headCircumferenceCm;
  final double? heightPercentile;  // 0~100
  final double? weightPercentile;

  factory GrowthLogModel.fromJson(Map<String, dynamic> json) => GrowthLogModel(
        id: json['id'] as String,
        childId: json['child_id'] as String,
        measuredAt: DateTime.parse(json['measured_at'] as String),
        heightCm: (json['height_cm'] as num).toDouble(),
        weightKg: (json['weight_kg'] as num).toDouble(),
        headCircumferenceCm:
            (json['head_circumference_cm'] as num?)?.toDouble(),
        heightPercentile: (json['height_percentile'] as num?)?.toDouble(),
        weightPercentile: (json['weight_percentile'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'measured_at': measuredAt.toIso8601String(),
        'height_cm': heightCm,
        'weight_kg': weightKg,
        if (headCircumferenceCm != null)
          'head_circumference_cm': headCircumferenceCm,
        if (heightPercentile != null) 'height_percentile': heightPercentile,
        if (weightPercentile != null) 'weight_percentile': weightPercentile,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// VaccinationStatus
// ──────────────────────────────────────────────────────────────────────────────

enum VaccinationStatus { completed, upcoming, delayed }

extension VaccinationStatusX on VaccinationStatus {
  String get label {
    switch (this) {
      case VaccinationStatus.completed:
        return '완료';
      case VaccinationStatus.upcoming:
        return '예정';
      case VaccinationStatus.delayed:
        return '지연';
    }
  }

  static VaccinationStatus fromString(String? v) {
    switch (v) {
      case 'completed':
        return VaccinationStatus.completed;
      case 'delayed':
        return VaccinationStatus.delayed;
      default:
        return VaccinationStatus.upcoming;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// VaccinationModel — 예방접종 항목
// ──────────────────────────────────────────────────────────────────────────────

class VaccinationModel {
  const VaccinationModel({
    required this.id,
    required this.childId,
    required this.vaccineName,
    required this.doseNumber,
    required this.scheduledDate,
    required this.status,
    this.administeredDate,
    this.notes,
  });

  final String id;
  final String childId;
  final String vaccineName;
  final int doseNumber;
  final DateTime scheduledDate;
  final VaccinationStatus status;
  final DateTime? administeredDate;
  final String? notes;

  factory VaccinationModel.fromJson(Map<String, dynamic> json) =>
      VaccinationModel(
        id: json['id'] as String,
        childId: json['child_id'] as String,
        vaccineName: json['vaccine_name'] as String,
        doseNumber: json['dose_number'] as int? ?? 1,
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        status: VaccinationStatusX.fromString(json['status'] as String?),
        administeredDate: json['administered_date'] != null
            ? DateTime.parse(json['administered_date'] as String)
            : null,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'vaccine_name': vaccineName,
        'dose_number': doseNumber,
        'scheduled_date': scheduledDate.toIso8601String().substring(0, 10),
        'status': status.name,
        if (administeredDate != null)
          'administered_date':
              administeredDate!.toIso8601String().substring(0, 10),
        if (notes != null) 'notes': notes,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// AddChildDto
// ──────────────────────────────────────────────────────────────────────────────

class AddChildDto {
  const AddChildDto({
    required this.name,
    required this.birthDate,
    required this.gender,
  });

  final String name;
  final DateTime birthDate;
  final String gender;

  Map<String, dynamic> toJson() => {
        'name': name,
        'birth_date': birthDate.toIso8601String().substring(0, 10),
        'gender': gender,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// AddGrowthLogDto
// ──────────────────────────────────────────────────────────────────────────────

class AddGrowthLogDto {
  const AddGrowthLogDto({
    required this.childId,
    required this.heightCm,
    required this.weightKg,
    this.headCircumferenceCm,
  });

  final String childId;
  final double heightCm;
  final double weightKg;
  final double? headCircumferenceCm;

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'measured_at': DateTime.now().toIso8601String(),
        if (headCircumferenceCm != null)
          'head_circumference_cm': headCircumferenceCm,
      };
}
