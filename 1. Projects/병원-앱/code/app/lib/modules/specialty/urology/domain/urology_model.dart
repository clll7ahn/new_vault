/// 비뇨의학과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// VoidingLogModel — 배뇨 일지
// ──────────────────────────────────────────────────────────────────────────────

class VoidingLogModel {
  const VoidingLogModel({
    required this.id,
    required this.recordedAt,
    required this.volumeMl,
    this.urgency,  // 1~5 절박뇨 강도
    this.note,
  });

  final String id;
  final DateTime recordedAt;
  final int volumeMl;
  final int? urgency;
  final String? note;

  factory VoidingLogModel.fromJson(Map<String, dynamic> json) =>
      VoidingLogModel(
        id: json['id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        volumeMl: (json['volume_ml'] as num).toInt(),
        urgency: json['urgency'] as int?,
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'volume_ml': volumeMl,
        if (urgency != null) 'urgency': urgency,
        if (note != null) 'note': note,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// PsaRecordModel — PSA 수치 기록
// ──────────────────────────────────────────────────────────────────────────────

class PsaRecordModel {
  const PsaRecordModel({
    required this.id,
    required this.measuredAt,
    required this.valueNgMl,
    this.note,
  });

  final String id;
  final DateTime measuredAt;
  final double valueNgMl;
  final String? note;

  String get riskLabel {
    if (valueNgMl < 4.0)  return '정상';
    if (valueNgMl < 10.0) return '주의';
    return '높음';
  }

  factory PsaRecordModel.fromJson(Map<String, dynamic> json) => PsaRecordModel(
        id: json['id'] as String,
        measuredAt: DateTime.parse(json['measured_at'] as String),
        valueNgMl: (json['value_ng_ml'] as num).toDouble(),
        note: json['note'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// HydrationReminderModel — 수분 섭취 알림
// ──────────────────────────────────────────────────────────────────────────────

class HydrationLogModel {
  const HydrationLogModel({
    required this.id,
    required this.recordedAt,
    required this.volumeMl,
  });

  final String id;
  final DateTime recordedAt;
  final int volumeMl;

  factory HydrationLogModel.fromJson(Map<String, dynamic> json) =>
      HydrationLogModel(
        id: json['id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        volumeMl: (json['volume_ml'] as num).toInt(),
      );
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

class AddVoidingLogDto {
  const AddVoidingLogDto({required this.volumeMl, this.urgency, this.note});
  final int volumeMl;
  final int? urgency;
  final String? note;

  Map<String, dynamic> toJson() => {
        'recorded_at': DateTime.now().toIso8601String(),
        'volume_ml': volumeMl,
        if (urgency != null) 'urgency': urgency,
        if (note != null) 'note': note,
      };
}

class AddHydrationLogDto {
  const AddHydrationLogDto({required this.volumeMl});
  final int volumeMl;

  Map<String, dynamic> toJson() => {
        'recorded_at': DateTime.now().toIso8601String(),
        'volume_ml': volumeMl,
      };
}
