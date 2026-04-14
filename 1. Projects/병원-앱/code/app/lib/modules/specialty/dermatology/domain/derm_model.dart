/// 피부과 전문 모듈 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// SkinRegion — 피부 분석 부위
// ──────────────────────────────────────────────────────────────────────────────

enum SkinRegion {
  face,
  neck,
  chest,
  back,
  arm,
  leg,
  hand,
  other,
}

extension SkinRegionX on SkinRegion {
  String get label {
    switch (this) {
      case SkinRegion.face:
        return '얼굴';
      case SkinRegion.neck:
        return '목';
      case SkinRegion.chest:
        return '가슴';
      case SkinRegion.back:
        return '등';
      case SkinRegion.arm:
        return '팔';
      case SkinRegion.leg:
        return '다리';
      case SkinRegion.hand:
        return '손';
      case SkinRegion.other:
        return '기타';
    }
  }

  static SkinRegion fromString(String? v) {
    return SkinRegion.values.firstWhere(
      (e) => e.name == v,
      orElse: () => SkinRegion.other,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SkinAnalysisResult — AI 분석 결과
// ──────────────────────────────────────────────────────────────────────────────

class SkinAnalysisResult {
  const SkinAnalysisResult({
    required this.overallScore,    // 0.0 ~ 100.0
    required this.hydration,       // 수분도
    required this.oiliness,        // 유분도
    required this.sensitivity,     // 민감도
    required this.wrinkle,         // 주름
    required this.pigmentation,    // 색소침착
    this.concerns,                 // 주요 피부 고민 리스트
    this.recommendation,           // 추천 케어
  });

  final double overallScore;
  final double hydration;
  final double oiliness;
  final double sensitivity;
  final double wrinkle;
  final double pigmentation;
  final List<String>? concerns;
  final String? recommendation;

  factory SkinAnalysisResult.fromJson(Map<String, dynamic> json) =>
      SkinAnalysisResult(
        overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0,
        hydration: (json['hydration'] as num?)?.toDouble() ?? 0,
        oiliness: (json['oiliness'] as num?)?.toDouble() ?? 0,
        sensitivity: (json['sensitivity'] as num?)?.toDouble() ?? 0,
        wrinkle: (json['wrinkle'] as num?)?.toDouble() ?? 0,
        pigmentation: (json['pigmentation'] as num?)?.toDouble() ?? 0,
        concerns: (json['concerns'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        recommendation: json['recommendation'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// SkinPhotoModel — 피부 사진 기록
// ──────────────────────────────────────────────────────────────────────────────

class SkinPhotoModel {
  const SkinPhotoModel({
    required this.id,
    required this.photoUrl,
    required this.region,
    required this.takenAt,
    this.thumbnailUrl,
    this.analysis,
    this.notes,
  });

  final String id;
  final String photoUrl;
  final SkinRegion region;
  final DateTime takenAt;
  final String? thumbnailUrl;
  final SkinAnalysisResult? analysis;
  final String? notes;

  factory SkinPhotoModel.fromJson(Map<String, dynamic> json) => SkinPhotoModel(
        id: json['id'] as String,
        photoUrl: json['photo_url'] as String,
        region: SkinRegionX.fromString(json['region'] as String?),
        takenAt: DateTime.parse(json['taken_at'] as String),
        thumbnailUrl: json['thumbnail_url'] as String?,
        analysis: json['analysis'] != null
            ? SkinAnalysisResult.fromJson(
                json['analysis'] as Map<String, dynamic>)
            : null,
        notes: json['notes'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// TreatmentStatus — 시술 상태
// ──────────────────────────────────────────────────────────────────────────────

enum TreatmentStatus { scheduled, completed, cancelled }

extension TreatmentStatusX on TreatmentStatus {
  String get label {
    switch (this) {
      case TreatmentStatus.scheduled:
        return '예정';
      case TreatmentStatus.completed:
        return '완료';
      case TreatmentStatus.cancelled:
        return '취소';
    }
  }

  static TreatmentStatus fromString(String? v) {
    switch (v) {
      case 'scheduled':
        return TreatmentStatus.scheduled;
      case 'completed':
        return TreatmentStatus.completed;
      case 'cancelled':
        return TreatmentStatus.cancelled;
      default:
        return TreatmentStatus.scheduled;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TreatmentModel — 시술 이력
// ──────────────────────────────────────────────────────────────────────────────

class TreatmentModel {
  const TreatmentModel({
    required this.id,
    required this.name,           // 시술명: '레이저 토닝', '보톡스' 등
    required this.treatedAt,
    required this.status,
    this.region,
    this.doctorName,
    this.notes,
    this.nextScheduled,
  });

  final String id;
  final String name;
  final DateTime treatedAt;
  final TreatmentStatus status;
  final SkinRegion? region;
  final String? doctorName;
  final String? notes;
  final DateTime? nextScheduled;

  factory TreatmentModel.fromJson(Map<String, dynamic> json) => TreatmentModel(
        id: json['id'] as String,
        name: json['name'] as String,
        treatedAt: DateTime.parse(json['treated_at'] as String),
        status: TreatmentStatusX.fromString(json['status'] as String?),
        region: json['region'] != null
            ? SkinRegionX.fromString(json['region'] as String?)
            : null,
        doctorName: json['doctor_name'] as String?,
        notes: json['notes'] as String?,
        nextScheduled: json['next_scheduled'] != null
            ? DateTime.parse(json['next_scheduled'] as String)
            : null,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// BeforeAfterPair — Before/After 이미지 쌍
// ──────────────────────────────────────────────────────────────────────────────

class BeforeAfterPair {
  const BeforeAfterPair({
    required this.treatmentId,
    required this.before,
    required this.after,
  });

  final String treatmentId;
  final SkinPhotoModel before;
  final SkinPhotoModel after;

  factory BeforeAfterPair.fromJson(Map<String, dynamic> json) =>
      BeforeAfterPair(
        treatmentId: json['treatment_id'] as String,
        before: SkinPhotoModel.fromJson(
            json['before'] as Map<String, dynamic>),
        after: SkinPhotoModel.fromJson(
            json['after'] as Map<String, dynamic>),
      );
}
