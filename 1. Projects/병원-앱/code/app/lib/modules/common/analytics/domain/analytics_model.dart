/// AI 대시보드 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// NoShowRiskAppointment — 노쇼 위험 예약
// ──────────────────────────────────────────────────────────────────────────────

enum NoShowRiskLevel { low, medium, high }

extension NoShowRiskLevelX on NoShowRiskLevel {
  String get label {
    switch (this) {
      case NoShowRiskLevel.low:    return '낮음';
      case NoShowRiskLevel.medium: return '중간';
      case NoShowRiskLevel.high:   return '높음';
    }
  }

  static NoShowRiskLevel fromString(String? v) {
    switch (v) {
      case 'high':   return NoShowRiskLevel.high;
      case 'medium': return NoShowRiskLevel.medium;
      default:       return NoShowRiskLevel.low;
    }
  }
}

class NoShowRiskAppointmentModel {
  const NoShowRiskAppointmentModel({
    required this.appointmentId,
    required this.patientName,
    required this.appointmentTime,
    required this.riskLevel,
    required this.riskScore, // 0.0~1.0
    this.doctorName,
    this.department,
  });

  final String appointmentId;
  final String patientName;
  final DateTime appointmentTime;
  final NoShowRiskLevel riskLevel;
  final double riskScore;
  final String? doctorName;
  final String? department;

  factory NoShowRiskAppointmentModel.fromJson(Map<String, dynamic> json) =>
      NoShowRiskAppointmentModel(
        appointmentId: json['appointment_id'] as String,
        patientName: json['patient_name'] as String,
        appointmentTime: DateTime.parse(json['appointment_time'] as String),
        riskLevel: NoShowRiskLevelX.fromString(json['risk_level'] as String?),
        riskScore: (json['risk_score'] as num).toDouble(),
        doctorName: json['doctor_name'] as String?,
        department: json['department'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// PeakTimeSlot — 피크타임 히트맵 데이터
// ──────────────────────────────────────────────────────────────────────────────

class PeakTimeSlotModel {
  const PeakTimeSlotModel({
    required this.hour,     // 0~23
    required this.count,    // 예약/방문 수
    required this.capacity, // 정원
  });

  final int hour;
  final int count;
  final int capacity;

  double get ratio => capacity > 0 ? (count / capacity).clamp(0.0, 1.0) : 0.0;

  String get hourLabel => '${hour.toString().padLeft(2, '0')}:00';

  factory PeakTimeSlotModel.fromJson(Map<String, dynamic> json) =>
      PeakTimeSlotModel(
        hour: (json['hour'] as num).toInt(),
        count: (json['count'] as num).toInt(),
        capacity: (json['capacity'] as num).toInt(),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// ChurnRiskSummaryModel — 이탈 위험 환자 요약
// ──────────────────────────────────────────────────────────────────────────────

class ChurnRiskSummaryModel {
  const ChurnRiskSummaryModel({
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.totalAtRisk,
    this.updatedAt,
  });

  final int highRiskCount;
  final int mediumRiskCount;
  final int totalAtRisk;
  final DateTime? updatedAt;

  factory ChurnRiskSummaryModel.fromJson(Map<String, dynamic> json) =>
      ChurnRiskSummaryModel(
        highRiskCount: (json['high_risk_count'] as num).toInt(),
        mediumRiskCount: (json['medium_risk_count'] as num).toInt(),
        totalAtRisk: (json['total_at_risk'] as num).toInt(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// RevenueSummaryModel — 매출 요약
// ──────────────────────────────────────────────────────────────────────────────

class RevenueSummaryModel {
  const RevenueSummaryModel({
    required this.todayRevenue,
    required this.monthRevenue,
    required this.targetRevenue,
    required this.yesterdayRevenue,
  });

  final double todayRevenue;
  final double monthRevenue;
  final double targetRevenue;
  final double yesterdayRevenue;

  double get monthAchievementRatio =>
      targetRevenue > 0 ? (monthRevenue / targetRevenue).clamp(0.0, 1.0) : 0.0;

  double get todayVsYesterday => yesterdayRevenue > 0
      ? (todayRevenue - yesterdayRevenue) / yesterdayRevenue
      : 0.0;

  factory RevenueSummaryModel.fromJson(Map<String, dynamic> json) =>
      RevenueSummaryModel(
        todayRevenue: (json['today_revenue'] as num).toDouble(),
        monthRevenue: (json['month_revenue'] as num).toDouble(),
        targetRevenue: (json['target_revenue'] as num).toDouble(),
        yesterdayRevenue: (json['yesterday_revenue'] as num).toDouble(),
      );
}
