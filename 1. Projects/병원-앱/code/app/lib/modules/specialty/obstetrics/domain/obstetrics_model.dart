/// 산부인과 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// PregnancyModel — 임신 정보
// ──────────────────────────────────────────────────────────────────────────────

class PregnancyModel {
  const PregnancyModel({
    required this.id,
    required this.lastMenstrualPeriod,
    this.dueDate,
    this.currentWeek,
    this.fetalNickname,
    this.doctorName,
    this.hospitalName,
  });

  final String id;
  final DateTime lastMenstrualPeriod; // 마지막 월경일
  final DateTime? dueDate;            // 예정일
  final int? currentWeek;             // 현재 임신 주수 (서버 계산)
  final String? fetalNickname;
  final String? doctorName;
  final String? hospitalName;

  int get weekNumber {
    if (currentWeek != null) return currentWeek!;
    final days =
        DateTime.now().difference(lastMenstrualPeriod).inDays;
    return (days ~/ 7).clamp(0, 42);
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  /// 태아 크기 비유 (주수별)
  String get fetalSizeComparison {
    final w = weekNumber;
    if (w < 5) return '양귀비 씨앗';
    if (w < 7) return '블루베리';
    if (w < 9) return '라즈베리';
    if (w < 11) return '딸기';
    if (w < 13) return '라임';
    if (w < 15) return '레몬';
    if (w < 17) return '아보카도';
    if (w < 19) return '망고';
    if (w < 21) return '바나나';
    if (w < 23) return '옥수수';
    if (w < 25) return '파파야';
    if (w < 28) return '무';
    if (w < 31) return '양배추';
    if (w < 34) return '파인애플';
    if (w < 37) return '참외';
    if (w < 40) return '수박';
    return '신생아';
  }

  factory PregnancyModel.fromJson(Map<String, dynamic> json) => PregnancyModel(
        id: json['id'] as String,
        lastMenstrualPeriod:
            DateTime.parse(json['last_menstrual_period'] as String),
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
        currentWeek: json['current_week'] as int?,
        fetalNickname: json['fetal_nickname'] as String?,
        doctorName: json['doctor_name'] as String?,
        hospitalName: json['hospital_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'last_menstrual_period':
            lastMenstrualPeriod.toIso8601String().substring(0, 10),
        if (dueDate != null)
          'due_date': dueDate!.toIso8601String().substring(0, 10),
        if (currentWeek != null) 'current_week': currentWeek,
        if (fetalNickname != null) 'fetal_nickname': fetalNickname,
        if (doctorName != null) 'doctor_name': doctorName,
        if (hospitalName != null) 'hospital_name': hospitalName,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// CheckupModel — 산전 검진 일정
// ──────────────────────────────────────────────────────────────────────────────

class CheckupModel {
  const CheckupModel({
    required this.id,
    required this.title,
    required this.scheduledWeek,
    required this.scheduledDate,
    required this.isCompleted,
    this.completedDate,
    this.notes,
  });

  final String id;
  final String title;          // 검진명 (예: 1차 기형아 검사)
  final int scheduledWeek;     // 권장 주수
  final DateTime scheduledDate;
  final bool isCompleted;
  final DateTime? completedDate;
  final String? notes;

  factory CheckupModel.fromJson(Map<String, dynamic> json) => CheckupModel(
        id: json['id'] as String,
        title: json['title'] as String,
        scheduledWeek: json['scheduled_week'] as int? ?? 0,
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        isCompleted: json['is_completed'] as bool? ?? false,
        completedDate: json['completed_date'] != null
            ? DateTime.parse(json['completed_date'] as String)
            : null,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'scheduled_week': scheduledWeek,
        'scheduled_date': scheduledDate.toIso8601String().substring(0, 10),
        'is_completed': isCompleted,
        if (completedDate != null)
          'completed_date': completedDate!.toIso8601String().substring(0, 10),
        if (notes != null) 'notes': notes,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// FetalMovementModel — 태동 기록
// ──────────────────────────────────────────────────────────────────────────────

class FetalMovementModel {
  const FetalMovementModel({
    required this.id,
    required this.recordedAt,
    required this.count,
    this.durationMinutes,
    this.notes,
  });

  final String id;
  final DateTime recordedAt;
  final int count;             // 태동 횟수
  final int? durationMinutes; // 측정 시간(분)
  final String? notes;

  factory FetalMovementModel.fromJson(Map<String, dynamic> json) =>
      FetalMovementModel(
        id: json['id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        count: json['count'] as int,
        durationMinutes: json['duration_minutes'] as int?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'count': count,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (notes != null) 'notes': notes,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// MaternalLogModel — 산모 건강 기록 (체중/혈압)
// ──────────────────────────────────────────────────────────────────────────────

class MaternalLogModel {
  const MaternalLogModel({
    required this.id,
    required this.recordedAt,
    this.weightKg,
    this.systolicBp,
    this.diastolicBp,
    this.notes,
  });

  final String id;
  final DateTime recordedAt;
  final double? weightKg;
  final int? systolicBp;   // 수축기 혈압
  final int? diastolicBp;  // 이완기 혈압

  final String? notes;

  String get bpLabel {
    if (systolicBp == null) return '-';
    return '$systolicBp/${diastolicBp ?? '-'} mmHg';
  }

  factory MaternalLogModel.fromJson(Map<String, dynamic> json) =>
      MaternalLogModel(
        id: json['id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        systolicBp: json['systolic_bp'] as int?,
        diastolicBp: json['diastolic_bp'] as int?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        if (weightKg != null) 'weight_kg': weightKg,
        if (systolicBp != null) 'systolic_bp': systolicBp,
        if (diastolicBp != null) 'diastolic_bp': diastolicBp,
        if (notes != null) 'notes': notes,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// AddFetalMovementDto
// ──────────────────────────────────────────────────────────────────────────────

class AddFetalMovementDto {
  const AddFetalMovementDto({required this.count, this.durationMinutes});
  final int count;
  final int? durationMinutes;

  Map<String, dynamic> toJson() => {
        'count': count,
        'recorded_at': DateTime.now().toIso8601String(),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// AddMaternalLogDto
// ──────────────────────────────────────────────────────────────────────────────

class AddMaternalLogDto {
  const AddMaternalLogDto({this.weightKg, this.systolicBp, this.diastolicBp});
  final double? weightKg;
  final int? systolicBp;
  final int? diastolicBp;

  Map<String, dynamic> toJson() => {
        'recorded_at': DateTime.now().toIso8601String(),
        if (weightKg != null) 'weight_kg': weightKg,
        if (systolicBp != null) 'systolic_bp': systolicBp,
        if (diastolicBp != null) 'diastolic_bp': diastolicBp,
      };
}
