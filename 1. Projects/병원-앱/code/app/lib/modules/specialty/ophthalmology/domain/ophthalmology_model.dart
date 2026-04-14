/// 안과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// VisionLogModel — 시력 측정 기록
// ──────────────────────────────────────────────────────────────────────────────

class VisionLogModel {
  const VisionLogModel({
    required this.id,
    required this.measuredAt,
    required this.rightEyeVision,
    required this.leftEyeVision,
    this.rightEyeWithCorrection,
    this.leftEyeWithCorrection,
    this.notes,
  });

  final String id;
  final DateTime measuredAt;
  final double rightEyeVision;   // 나안 우안 시력
  final double leftEyeVision;    // 나안 좌안 시력
  final double? rightEyeWithCorrection; // 교정 우안
  final double? leftEyeWithCorrection;  // 교정 좌안
  final String? notes;

  factory VisionLogModel.fromJson(Map<String, dynamic> json) => VisionLogModel(
        id: json['id'] as String,
        measuredAt: DateTime.parse(json['measured_at'] as String),
        rightEyeVision: (json['right_eye_vision'] as num).toDouble(),
        leftEyeVision: (json['left_eye_vision'] as num).toDouble(),
        rightEyeWithCorrection:
            (json['right_eye_with_correction'] as num?)?.toDouble(),
        leftEyeWithCorrection:
            (json['left_eye_with_correction'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'measured_at': measuredAt.toIso8601String(),
        'right_eye_vision': rightEyeVision,
        'left_eye_vision': leftEyeVision,
        if (rightEyeWithCorrection != null)
          'right_eye_with_correction': rightEyeWithCorrection,
        if (leftEyeWithCorrection != null)
          'left_eye_with_correction': leftEyeWithCorrection,
        if (notes != null) 'notes': notes,
      };

  String visionLabel(double vision) {
    if (vision >= 1.0) return '${vision.toStringAsFixed(1)}';
    return vision.toStringAsFixed(2);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PrescriptionModel — 안경/렌즈 처방 정보
// ──────────────────────────────────────────────────────────────────────────────

enum PrescriptionType { glasses, contactLens }

extension PrescriptionTypeX on PrescriptionType {
  String get label {
    switch (this) {
      case PrescriptionType.glasses:
        return '안경';
      case PrescriptionType.contactLens:
        return '콘택트렌즈';
    }
  }

  static PrescriptionType fromString(String? v) =>
      v == 'contact_lens' ? PrescriptionType.contactLens : PrescriptionType.glasses;
}

class PrescriptionModel {
  const PrescriptionModel({
    required this.id,
    required this.prescribedAt,
    required this.type,
    required this.rightSphereDiopter,
    required this.leftSphereDiopter,
    this.rightCylinderDiopter,
    this.leftCylinderDiopter,
    this.rightAxis,
    this.leftAxis,
    this.rightPd,
    this.leftPd,
    this.notes,
    this.expiresAt,
  });

  final String id;
  final DateTime prescribedAt;
  final PrescriptionType type;
  final double rightSphereDiopter; // 구면 (S)
  final double leftSphereDiopter;
  final double? rightCylinderDiopter; // 원주 (C)
  final double? leftCylinderDiopter;
  final int? rightAxis;     // 축 (A)
  final int? leftAxis;
  final double? rightPd;    // 동공 간 거리
  final double? leftPd;
  final String? notes;
  final DateTime? expiresAt;

  String get diopterLabel {
    String fmt(double d) => d >= 0 ? '+${d.toStringAsFixed(2)}' : d.toStringAsFixed(2);
    return '우: ${fmt(rightSphereDiopter)} / 좌: ${fmt(leftSphereDiopter)}';
  }

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) =>
      PrescriptionModel(
        id: json['id'] as String,
        prescribedAt: DateTime.parse(json['prescribed_at'] as String),
        type: PrescriptionTypeX.fromString(json['type'] as String?),
        rightSphereDiopter: (json['right_sphere'] as num).toDouble(),
        leftSphereDiopter: (json['left_sphere'] as num).toDouble(),
        rightCylinderDiopter: (json['right_cylinder'] as num?)?.toDouble(),
        leftCylinderDiopter: (json['left_cylinder'] as num?)?.toDouble(),
        rightAxis: json['right_axis'] as int?,
        leftAxis: json['left_axis'] as int?,
        rightPd: (json['right_pd'] as num?)?.toDouble(),
        leftPd: (json['left_pd'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'prescribed_at': prescribedAt.toIso8601String(),
        'type': type == PrescriptionType.contactLens ? 'contact_lens' : 'glasses',
        'right_sphere': rightSphereDiopter,
        'left_sphere': leftSphereDiopter,
        if (rightCylinderDiopter != null) 'right_cylinder': rightCylinderDiopter,
        if (leftCylinderDiopter != null) 'left_cylinder': leftCylinderDiopter,
        if (rightAxis != null) 'right_axis': rightAxis,
        if (leftAxis != null) 'left_axis': leftAxis,
        if (rightPd != null) 'right_pd': rightPd,
        if (leftPd != null) 'left_pd': leftPd,
        if (notes != null) 'notes': notes,
        if (expiresAt != null)
          'expires_at': expiresAt!.toIso8601String().substring(0, 10),
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// EyeDropModel — 안약 투약 정보
// ──────────────────────────────────────────────────────────────────────────────

class EyeDropModel {
  const EyeDropModel({
    required this.id,
    required this.name,
    required this.dosagePerDay,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.lastAdministeredAt,
  });

  final String id;
  final String name;
  final int dosagePerDay;       // 하루 투약 횟수
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;  // 투약 지시사항
  final DateTime? lastAdministeredAt;

  bool get isActive =>
      endDate == null || endDate!.isAfter(DateTime.now());

  String get nextDoseLabel {
    if (lastAdministeredAt == null) return '오늘 첫 투약';
    final intervalHours = 24 ~/ dosagePerDay;
    final next =
        lastAdministeredAt!.add(Duration(hours: intervalHours));
    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return '지금 투약 필요';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 후';
    return '${diff.inHours}시간 후';
  }

  factory EyeDropModel.fromJson(Map<String, dynamic> json) => EyeDropModel(
        id: json['id'] as String,
        name: json['name'] as String,
        dosagePerDay: json['dosage_per_day'] as int? ?? 1,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        instructions: json['instructions'] as String?,
        lastAdministeredAt: json['last_administered_at'] != null
            ? DateTime.parse(json['last_administered_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage_per_day': dosagePerDay,
        'start_date': startDate.toIso8601String().substring(0, 10),
        if (endDate != null)
          'end_date': endDate!.toIso8601String().substring(0, 10),
        if (instructions != null) 'instructions': instructions,
        if (lastAdministeredAt != null)
          'last_administered_at': lastAdministeredAt!.toIso8601String(),
      };
}
