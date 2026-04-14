/// 내과 전문 모듈 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// VitalsType — 활력 징후 종류
// ──────────────────────────────────────────────────────────────────────────────

enum VitalsType {
  bloodPressure, // 혈압 (수축기 / 이완기)
  bloodGlucose,  // 혈당
  weight,        // 체중
}

extension VitalsTypeX on VitalsType {
  String get label {
    switch (this) {
      case VitalsType.bloodPressure:
        return '혈압';
      case VitalsType.bloodGlucose:
        return '혈당';
      case VitalsType.weight:
        return '체중';
    }
  }

  String get unit {
    switch (this) {
      case VitalsType.bloodPressure:
        return 'mmHg';
      case VitalsType.bloodGlucose:
        return 'mg/dL';
      case VitalsType.weight:
        return 'kg';
    }
  }

  String get apiKey {
    switch (this) {
      case VitalsType.bloodPressure:
        return 'blood_pressure';
      case VitalsType.bloodGlucose:
        return 'blood_glucose';
      case VitalsType.weight:
        return 'weight';
    }
  }

  static VitalsType fromString(String? v) {
    switch (v) {
      case 'blood_pressure':
        return VitalsType.bloodPressure;
      case 'blood_glucose':
        return VitalsType.bloodGlucose;
      case 'weight':
        return VitalsType.weight;
      default:
        return VitalsType.bloodGlucose;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// VitalsModel — 활력 징후 측정 기록
// ──────────────────────────────────────────────────────────────────────────────

class VitalsModel {
  const VitalsModel({
    required this.id,
    required this.type,
    required this.value1,      // 주 수치 (혈압: 수축기, 혈당: mg/dL, 체중: kg)
    this.value2,               // 부 수치 (혈압: 이완기)
    required this.measuredAt,
    this.note,
  });

  final String id;
  final VitalsType type;
  final double value1;
  final double? value2;
  final DateTime measuredAt;
  final String? note;

  String get displayValue {
    if (type == VitalsType.bloodPressure && value2 != null) {
      return '${value1.toStringAsFixed(0)}/${value2!.toStringAsFixed(0)}';
    }
    if (type == VitalsType.weight) return value1.toStringAsFixed(1);
    return value1.toStringAsFixed(0);
  }

  factory VitalsModel.fromJson(Map<String, dynamic> json) => VitalsModel(
        id: json['id'] as String,
        type: VitalsTypeX.fromString(json['type'] as String?),
        value1: (json['value1'] as num).toDouble(),
        value2: (json['value2'] as num?)?.toDouble(),
        measuredAt: DateTime.parse(json['measured_at'] as String),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type': type.apiKey,
        'value1': value1,
        if (value2 != null) 'value2': value2,
        'measured_at': measuredAt.toIso8601String(),
        if (note != null) 'note': note,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// VitalsTrendPoint — 트렌드 차트용 데이터 포인트
// ──────────────────────────────────────────────────────────────────────────────

class VitalsTrendPoint {
  const VitalsTrendPoint({
    required this.date,
    required this.value1,
    this.value2,
  });

  final DateTime date;
  final double value1;
  final double? value2;

  factory VitalsTrendPoint.fromJson(Map<String, dynamic> json) =>
      VitalsTrendPoint(
        date: DateTime.parse(json['date'] as String),
        value1: (json['value1'] as num).toDouble(),
        value2: (json['value2'] as num?)?.toDouble(),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// MedicationModel — 처방 약물
// ──────────────────────────────────────────────────────────────────────────────

class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,   // 예: '1일 3회'
    required this.timings,     // 예: ['아침', '점심', '저녁']
    this.startDate,
    this.endDate,
    this.instructions,
  });

  final String id;
  final String name;
  final String dosage;         // 예: '5mg'
  final String frequency;
  final List<String> timings;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? instructions;

  bool get isActive {
    final now = DateTime.now();
    if (endDate != null && endDate!.isBefore(now)) return false;
    return true;
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) =>
      MedicationModel(
        id: json['id'] as String,
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        frequency: json['frequency'] as String,
        timings: (json['timings'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'] as String)
            : null,
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        instructions: json['instructions'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// MedLogStatus — 복약 상태
// ──────────────────────────────────────────────────────────────────────────────

enum MedLogStatus { taken, skipped, pending }

extension MedLogStatusX on MedLogStatus {
  String get label {
    switch (this) {
      case MedLogStatus.taken:
        return '복용 완료';
      case MedLogStatus.skipped:
        return '건너뜀';
      case MedLogStatus.pending:
        return '미복용';
    }
  }

  static MedLogStatus fromString(String? v) {
    switch (v) {
      case 'taken':
        return MedLogStatus.taken;
      case 'skipped':
        return MedLogStatus.skipped;
      default:
        return MedLogStatus.pending;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MedLogModel — 복약 기록 (약 × 타이밍 × 날짜)
// ──────────────────────────────────────────────────────────────────────────────

class MedLogModel {
  const MedLogModel({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.timing,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
  });

  final String id;
  final String medicationId;
  final String medicationName;
  final String timing;           // '아침' | '점심' | '저녁'
  final DateTime scheduledAt;
  final MedLogStatus status;
  final DateTime? takenAt;

  factory MedLogModel.fromJson(Map<String, dynamic> json) => MedLogModel(
        id: json['id'] as String,
        medicationId: json['medication_id'] as String,
        medicationName: json['medication_name'] as String,
        timing: json['timing'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        status: MedLogStatusX.fromString(json['status'] as String?),
        takenAt: json['taken_at'] != null
            ? DateTime.parse(json['taken_at'] as String)
            : null,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// AdherenceModel — 복약 순응도
// ──────────────────────────────────────────────────────────────────────────────

class AdherenceModel {
  const AdherenceModel({
    required this.period,       // '7일' | '30일'
    required this.total,
    required this.taken,
    required this.skipped,
  });

  final String period;
  final int total;
  final int taken;
  final int skipped;

  double get percent => total == 0 ? 0 : (taken / total).clamp(0.0, 1.0);

  factory AdherenceModel.fromJson(Map<String, dynamic> json) => AdherenceModel(
        period: json['period'] as String? ?? '30일',
        total: json['total'] as int? ?? 0,
        taken: json['taken'] as int? ?? 0,
        skipped: json['skipped'] as int? ?? 0,
      );
}
