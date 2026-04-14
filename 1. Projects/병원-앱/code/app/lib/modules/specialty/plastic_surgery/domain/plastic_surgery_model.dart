/// 성형외과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// ProcedureRecordModel — 시술 이력
// ──────────────────────────────────────────────────────────────────────────────

class ProcedureRecordModel {
  const ProcedureRecordModel({
    required this.id,
    required this.procedureName,
    required this.performedAt,
    this.doctorName,
    this.notes,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
  });

  final String id;
  final String procedureName;
  final DateTime performedAt;
  final String? doctorName;
  final String? notes;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;

  bool get hasPhotos => beforePhotoUrl != null || afterPhotoUrl != null;

  factory ProcedureRecordModel.fromJson(Map<String, dynamic> json) =>
      ProcedureRecordModel(
        id: json['id'] as String,
        procedureName: json['procedure_name'] as String,
        performedAt: DateTime.parse(json['performed_at'] as String),
        doctorName: json['doctor_name'] as String?,
        notes: json['notes'] as String?,
        beforePhotoUrl: json['before_photo_url'] as String?,
        afterPhotoUrl: json['after_photo_url'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// RecoveryLogModel — 회복 일지 (부기/통증 레벨)
// ──────────────────────────────────────────────────────────────────────────────

class RecoveryLogModel {
  const RecoveryLogModel({
    required this.id,
    required this.procedureId,
    required this.recordedAt,
    required this.swellingLevel,  // 1~5
    required this.painLevel,      // 1~10
    this.note,
    this.photoUrl,
  });

  final String id;
  final String procedureId;
  final DateTime recordedAt;
  final int swellingLevel;
  final int painLevel;
  final String? note;
  final String? photoUrl;

  factory RecoveryLogModel.fromJson(Map<String, dynamic> json) =>
      RecoveryLogModel(
        id: json['id'] as String,
        procedureId: json['procedure_id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        swellingLevel: (json['swelling_level'] as num).toInt(),
        painLevel: (json['pain_level'] as num).toInt(),
        note: json['note'] as String?,
        photoUrl: json['photo_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'procedure_id': procedureId,
        'recorded_at': recordedAt.toIso8601String(),
        'swelling_level': swellingLevel,
        'pain_level': painLevel,
        if (note != null) 'note': note,
      };
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

class AddRecoveryLogDto {
  const AddRecoveryLogDto({
    required this.procedureId,
    required this.swellingLevel,
    required this.painLevel,
    this.note,
  });

  final String procedureId;
  final int swellingLevel;
  final int painLevel;
  final String? note;

  Map<String, dynamic> toJson() => {
        'procedure_id': procedureId,
        'recorded_at': DateTime.now().toIso8601String(),
        'swelling_level': swellingLevel,
        'pain_level': painLevel,
        if (note != null) 'note': note,
      };
}
