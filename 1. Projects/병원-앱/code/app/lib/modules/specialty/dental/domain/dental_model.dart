/// 치과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// ToothStatus
// ──────────────────────────────────────────────────────────────────────────────

enum ToothStatus {
  healthy,    // 정상
  treated,    // 치료 완료 (충치 치료, 임플란트 등)
  missing,    // 발치/결손
  decayed,    // 충치 진행 중
  crown,      // 크라운
  implant,    // 임플란트
}

extension ToothStatusX on ToothStatus {
  String get label {
    switch (this) {
      case ToothStatus.healthy:
        return '정상';
      case ToothStatus.treated:
        return '치료';
      case ToothStatus.missing:
        return '결손';
      case ToothStatus.decayed:
        return '충치';
      case ToothStatus.crown:
        return '크라운';
      case ToothStatus.implant:
        return '임플란트';
    }
  }

  static ToothStatus fromString(String? v) {
    switch (v) {
      case 'treated':
        return ToothStatus.treated;
      case 'missing':
        return ToothStatus.missing;
      case 'decayed':
        return ToothStatus.decayed;
      case 'crown':
        return ToothStatus.crown;
      case 'implant':
        return ToothStatus.implant;
      default:
        return ToothStatus.healthy;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ToothInfo — 개별 치아 정보
// ──────────────────────────────────────────────────────────────────────────────

class ToothInfo {
  const ToothInfo({
    required this.number,    // 국제 치아 번호 (FDI: 11~48)
    required this.status,
    this.notes,
  });

  final int number;
  final ToothStatus status;
  final String? notes;

  factory ToothInfo.fromJson(Map<String, dynamic> json) => ToothInfo(
        number: json['number'] as int,
        status: ToothStatusX.fromString(json['status'] as String?),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'status': status.name,
        if (notes != null) 'notes': notes,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// ToothChartModel — 전체 치아 차트
// ──────────────────────────────────────────────────────────────────────────────

class ToothChartModel {
  const ToothChartModel({
    required this.id,
    required this.updatedAt,
    required this.teeth,
  });

  final String id;
  final DateTime updatedAt;
  final List<ToothInfo> teeth; // 최대 32개

  ToothInfo? getByNumber(int number) {
    try {
      return teeth.firstWhere((t) => t.number == number);
    } catch (_) {
      return null;
    }
  }

  factory ToothChartModel.fromJson(Map<String, dynamic> json) =>
      ToothChartModel(
        id: json['id'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        teeth: (json['teeth'] as List<dynamic>)
            .map((e) => ToothInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'updated_at': updatedAt.toIso8601String(),
        'teeth': teeth.map((t) => t.toJson()).toList(),
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// DentalTreatmentStatus
// ──────────────────────────────────────────────────────────────────────────────

enum DentalTreatmentStatus { planned, inProgress, completed, cancelled }

extension DentalTreatmentStatusX on DentalTreatmentStatus {
  String get label {
    switch (this) {
      case DentalTreatmentStatus.planned:
        return '예정';
      case DentalTreatmentStatus.inProgress:
        return '진행 중';
      case DentalTreatmentStatus.completed:
        return '완료';
      case DentalTreatmentStatus.cancelled:
        return '취소';
    }
  }

  static DentalTreatmentStatus fromString(String? v) {
    switch (v) {
      case 'in_progress':
        return DentalTreatmentStatus.inProgress;
      case 'completed':
        return DentalTreatmentStatus.completed;
      case 'cancelled':
        return DentalTreatmentStatus.cancelled;
      default:
        return DentalTreatmentStatus.planned;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// DentalTreatmentModel — 치과 치료 계획
// ──────────────────────────────────────────────────────────────────────────────

class DentalTreatmentModel {
  const DentalTreatmentModel({
    required this.id,
    required this.treatmentName,
    required this.status,
    this.toothNumbers,
    required this.scheduledDate,
    this.completedDate,
    this.estimatedCost,
    this.notes,
  });

  final String id;
  final String treatmentName;
  final DentalTreatmentStatus status;
  final List<int>? toothNumbers;   // 관련 치아 번호
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final double? estimatedCost;
  final String? notes;

  factory DentalTreatmentModel.fromJson(Map<String, dynamic> json) =>
      DentalTreatmentModel(
        id: json['id'] as String,
        treatmentName: json['treatment_name'] as String,
        status: DentalTreatmentStatusX.fromString(json['status'] as String?),
        toothNumbers: (json['tooth_numbers'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList(),
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        completedDate: json['completed_date'] != null
            ? DateTime.parse(json['completed_date'] as String)
            : null,
        estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'treatment_name': treatmentName,
        'status': status.name,
        if (toothNumbers != null) 'tooth_numbers': toothNumbers,
        'scheduled_date': scheduledDate.toIso8601String().substring(0, 10),
        if (completedDate != null)
          'completed_date': completedDate!.toIso8601String().substring(0, 10),
        if (estimatedCost != null) 'estimated_cost': estimatedCost,
        if (notes != null) 'notes': notes,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// NextCheckupModel — 다음 정기 검진
// ──────────────────────────────────────────────────────────────────────────────

class NextCheckupModel {
  const NextCheckupModel({
    required this.id,
    required this.scheduledDate,
    this.notes,
  });

  final String id;
  final DateTime scheduledDate;
  final String? notes;

  int get daysUntil =>
      scheduledDate.difference(DateTime.now()).inDays;

  factory NextCheckupModel.fromJson(Map<String, dynamic> json) =>
      NextCheckupModel(
        id: json['id'] as String,
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        notes: json['notes'] as String?,
      );
}
