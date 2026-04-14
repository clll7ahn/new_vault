/// 한의원 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// SasangType — 사상체질 (태양/태음/소양/소음)
// ──────────────────────────────────────────────────────────────────────────────

enum SasangType { taeyang, taeum, soyang, soeum }

extension SasangTypeX on SasangType {
  String get label {
    switch (this) {
      case SasangType.taeyang: return '태양인';
      case SasangType.taeum:   return '태음인';
      case SasangType.soyang:  return '소양인';
      case SasangType.soeum:   return '소음인';
    }
  }

  String get description {
    switch (this) {
      case SasangType.taeyang:
        return '창의적이고 진취적. 폐 기능이 강하고 간 기능이 약함.';
      case SasangType.taeum:
        return '꾸준하고 인내심 강함. 간 기능이 강하고 폐 기능이 약함.';
      case SasangType.soyang:
        return '활동적이고 외향적. 비장 기능이 강하고 신장 기능이 약함.';
      case SasangType.soeum:
        return '섬세하고 내향적. 신장 기능이 강하고 비장 기능이 약함.';
    }
  }

  String get apiKey => name;

  static SasangType fromString(String? v) {
    return SasangType.values.firstWhere(
      (t) => t.apiKey == v,
      orElse: () => SasangType.taeum,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TreatmentType — 치료 유형
// ──────────────────────────────────────────────────────────────────────────────

enum TreatmentType { acupuncture, moxibustion, herbalMedicine, cupping }

extension TreatmentTypeX on TreatmentType {
  String get label {
    switch (this) {
      case TreatmentType.acupuncture:    return '침';
      case TreatmentType.moxibustion:    return '뜸';
      case TreatmentType.herbalMedicine: return '한약';
      case TreatmentType.cupping:        return '부항';
    }
  }

  String get apiKey => name;
}

// ──────────────────────────────────────────────────────────────────────────────
// TreatmentRecordModel — 치료 이력
// ──────────────────────────────────────────────────────────────────────────────

class TreatmentRecordModel {
  const TreatmentRecordModel({
    required this.id,
    required this.treatmentType,
    required this.performedAt,
    this.points,        // 침 자리 등
    this.duration,      // 분
    this.note,
  });

  final String id;
  final TreatmentType treatmentType;
  final DateTime performedAt;
  final List<String>? points;
  final int? duration;
  final String? note;

  factory TreatmentRecordModel.fromJson(Map<String, dynamic> json) =>
      TreatmentRecordModel(
        id: json['id'] as String,
        treatmentType: TreatmentType.values.firstWhere(
          (t) => t.apiKey == json['treatment_type'],
          orElse: () => TreatmentType.acupuncture,
        ),
        performedAt: DateTime.parse(json['performed_at'] as String),
        points: (json['points'] as List<dynamic>?)?.cast<String>(),
        duration: json['duration'] as int?,
        note: json['note'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// SasangGuideModel — 섭생 가이드
// ──────────────────────────────────────────────────────────────────────────────

class SasangGuideModel {
  const SasangGuideModel({
    required this.sasangType,
    required this.recommendedFoods,
    required this.avoidFoods,
    this.lifestyleTips,
  });

  final SasangType sasangType;
  final List<String> recommendedFoods;
  final List<String> avoidFoods;
  final List<String>? lifestyleTips;

  factory SasangGuideModel.fromJson(Map<String, dynamic> json) =>
      SasangGuideModel(
        sasangType: SasangTypeX.fromString(json['sasang_type'] as String?),
        recommendedFoods:
            (json['recommended_foods'] as List<dynamic>?)?.cast<String>() ??
                [],
        avoidFoods:
            (json['avoid_foods'] as List<dynamic>?)?.cast<String>() ?? [],
        lifestyleTips:
            (json['lifestyle_tips'] as List<dynamic>?)?.cast<String>(),
      );
}

// 기본 섭생 가이드 (하드코딩)
final kDefaultSasangGuides = <SasangType, SasangGuideModel>{
  SasangType.taeyang: SasangGuideModel(
    sasangType: SasangType.taeyang,
    recommendedFoods: ['새우', '굴', '붕어', '포도', '모과'],
    avoidFoods: ['맵고 자극적인 음식', '지방 많은 육류', '술'],
  ),
  SasangType.taeum: SasangGuideModel(
    sasangType: SasangType.taeum,
    recommendedFoods: ['쇠고기', '무', '도라지', '호두', '율무'],
    avoidFoods: ['닭고기', '돼지고기', '인삼', '자극적인 향신료'],
  ),
  SasangType.soyang: SasangGuideModel(
    sasangType: SasangType.soyang,
    recommendedFoods: ['돼지고기', '보리', '녹두', '수박', '오이'],
    avoidFoods: ['닭고기', '개고기', '인삼', '더운 성질 음식'],
  ),
  SasangType.soeum: SasangGuideModel(
    sasangType: SasangType.soeum,
    recommendedFoods: ['닭고기', '인삼', '생강', '대추', '쌀'],
    avoidFoods: ['돼지고기', '보리', '녹두', '찬 음식'],
  ),
};

// ── 체질 Profile ──────────────────────────────────────────────────────────────

class PatientSasangProfile {
  const PatientSasangProfile({
    required this.sasangType,
    this.diagnosedAt,
    this.diagnosingDoctor,
  });

  final SasangType sasangType;
  final DateTime? diagnosedAt;
  final String? diagnosingDoctor;

  factory PatientSasangProfile.fromJson(Map<String, dynamic> json) =>
      PatientSasangProfile(
        sasangType: SasangTypeX.fromString(json['sasang_type'] as String?),
        diagnosedAt: json['diagnosed_at'] != null
            ? DateTime.parse(json['diagnosed_at'] as String)
            : null,
        diagnosingDoctor: json['diagnosing_doctor'] as String?,
      );
}
