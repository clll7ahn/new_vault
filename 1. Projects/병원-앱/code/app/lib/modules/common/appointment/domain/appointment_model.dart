/// 예약 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// AppointmentStatus
// ──────────────────────────────────────────────────────────────────────────────

enum AppointmentStatus {
  scheduled,   // 예정
  completed,   // 완료
  cancelled,   // 취소
  noShow,      // 미방문
}

extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.scheduled:
        return '예정';
      case AppointmentStatus.completed:
        return '완료';
      case AppointmentStatus.cancelled:
        return '취소';
      case AppointmentStatus.noShow:
        return '미방문';
    }
  }

  static AppointmentStatus fromString(String? value) {
    switch (value) {
      case 'scheduled':
        return AppointmentStatus.scheduled;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.scheduled;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SlotModel — 예약 가능 시간 슬롯
// ──────────────────────────────────────────────────────────────────────────────

class SlotModel {
  const SlotModel({
    required this.id,
    required this.doctorId,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  final String id;
  final String doctorId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctor_id': doctorId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'is_available': isAvailable,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// AppointmentModel
// ──────────────────────────────────────────────────────────────────────────────

class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.departmentId,
    required this.slotId,
    required this.scheduledAt,
    required this.status,
    this.doctorName,
    this.departmentName,
    this.symptoms,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String departmentId;
  final String slotId;
  final DateTime scheduledAt;
  final AppointmentStatus status;

  // 조회 편의용 (서버에서 조인 반환)
  final String? doctorName;
  final String? departmentName;
  final String? symptoms;
  final String? notes;
  final DateTime? createdAt;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      departmentId: json['department_id'] as String,
      slotId: json['slot_id'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: AppointmentStatusX.fromString(json['status'] as String?),
      doctorName: json['doctor_name'] as String?,
      departmentName: json['department_name'] as String?,
      symptoms: json['symptoms'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'department_id': departmentId,
        'slot_id': slotId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status.name,
        if (doctorName != null) 'doctor_name': doctorName,
        if (departmentName != null) 'department_name': departmentName,
        if (symptoms != null) 'symptoms': symptoms,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  AppointmentModel copyWith({
    AppointmentStatus? status,
    String? notes,
  }) {
    return AppointmentModel(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      departmentId: departmentId,
      slotId: slotId,
      scheduledAt: scheduledAt,
      status: status ?? this.status,
      doctorName: doctorName,
      departmentName: departmentName,
      symptoms: symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CreateAppointmentDto — 예약 생성 요청 DTO
// ──────────────────────────────────────────────────────────────────────────────

class CreateAppointmentDto {
  const CreateAppointmentDto({
    required this.doctorId,
    required this.departmentId,
    required this.slotId,
    this.symptoms,
  });

  final String doctorId;
  final String departmentId;
  final String slotId;
  final String? symptoms;

  Map<String, dynamic> toJson() => {
        'doctor_id': doctorId,
        'department_id': departmentId,
        'slot_id': slotId,
        if (symptoms != null && symptoms!.isNotEmpty) 'symptoms': symptoms,
      };
}
