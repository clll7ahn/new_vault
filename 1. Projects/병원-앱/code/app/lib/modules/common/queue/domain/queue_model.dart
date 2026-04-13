/// 대기열(Queue) 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// QueueStatus
// ──────────────────────────────────────────────────────────────────────────────

enum QueueStatus {
  waiting,    // 대기 중
  called,     // 호출됨
  inProgress, // 진료 중
  completed,  // 진료 완료
  cancelled,  // 취소
}

extension QueueStatusX on QueueStatus {
  String get label {
    switch (this) {
      case QueueStatus.waiting:
        return '대기 중';
      case QueueStatus.called:
        return '호출됨';
      case QueueStatus.inProgress:
        return '진료 중';
      case QueueStatus.completed:
        return '진료 완료';
      case QueueStatus.cancelled:
        return '취소됨';
    }
  }

  static QueueStatus fromString(String? value) {
    switch (value) {
      case 'waiting':
        return QueueStatus.waiting;
      case 'called':
        return QueueStatus.called;
      case 'in_progress':
        return QueueStatus.inProgress;
      case 'completed':
        return QueueStatus.completed;
      case 'cancelled':
        return QueueStatus.cancelled;
      default:
        return QueueStatus.waiting;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// QueueEntryModel — 내 대기열 항목
// ──────────────────────────────────────────────────────────────────────────────

class QueueEntryModel {
  const QueueEntryModel({
    required this.id,
    required this.queueNumber,
    required this.status,
    this.doctorName,
    this.departmentName,
    this.checkInAt,
    this.calledAt,
    this.estimatedWaitMin,
    this.waitingAhead,
  });

  final String id;
  final int queueNumber;
  final QueueStatus status;
  final String? doctorName;
  final String? departmentName;
  final DateTime? checkInAt;
  final DateTime? calledAt;
  final int? estimatedWaitMin; // 예상 대기 시간(분)
  final int? waitingAhead;    // 내 앞 대기 인원

  factory QueueEntryModel.fromJson(Map<String, dynamic> json) {
    return QueueEntryModel(
      id: json['id'] as String,
      queueNumber: json['queue_number'] as int,
      status: QueueStatusX.fromString(json['status'] as String?),
      doctorName: json['doctor_name'] as String?,
      departmentName: json['department_name'] as String?,
      checkInAt: json['check_in_at'] != null
          ? DateTime.parse(json['check_in_at'] as String)
          : null,
      calledAt: json['called_at'] != null
          ? DateTime.parse(json['called_at'] as String)
          : null,
      estimatedWaitMin: json['estimated_wait_min'] as int?,
      waitingAhead: json['waiting_ahead'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'queue_number': queueNumber,
        'status': status.name,
        if (doctorName != null) 'doctor_name': doctorName,
        if (departmentName != null) 'department_name': departmentName,
        if (checkInAt != null) 'check_in_at': checkInAt!.toIso8601String(),
        if (calledAt != null) 'called_at': calledAt!.toIso8601String(),
        if (estimatedWaitMin != null) 'estimated_wait_min': estimatedWaitMin,
        if (waitingAhead != null) 'waiting_ahead': waitingAhead,
      };

  QueueEntryModel copyWith({
    QueueStatus? status,
    int? estimatedWaitMin,
    int? waitingAhead,
    DateTime? calledAt,
  }) {
    return QueueEntryModel(
      id: id,
      queueNumber: queueNumber,
      status: status ?? this.status,
      doctorName: doctorName,
      departmentName: departmentName,
      checkInAt: checkInAt,
      calledAt: calledAt ?? this.calledAt,
      estimatedWaitMin: estimatedWaitMin ?? this.estimatedWaitMin,
      waitingAhead: waitingAhead ?? this.waitingAhead,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// QueueEstimate — 의사별 대기 예측 정보
// ──────────────────────────────────────────────────────────────────────────────

class QueueEstimate {
  const QueueEstimate({
    required this.estimatedWaitMin,
    required this.waitingCount,
  });

  final int estimatedWaitMin; // 현재 예상 대기 시간(분)
  final int waitingCount;     // 현재 총 대기 인원

  factory QueueEstimate.fromJson(Map<String, dynamic> json) {
    return QueueEstimate(
      estimatedWaitMin: json['estimated_wait_min'] as int? ?? 0,
      waitingCount: json['waiting_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'estimated_wait_min': estimatedWaitMin,
        'waiting_count': waitingCount,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// CheckInDto — 체크인 요청 DTO
// ──────────────────────────────────────────────────────────────────────────────

class CheckInDto {
  const CheckInDto({
    required this.doctorId,
    required this.departmentId,
    this.appointmentId,
  });

  final String doctorId;
  final String departmentId;
  final String? appointmentId;

  Map<String, dynamic> toJson() => {
        'doctor_id': doctorId,
        'department_id': departmentId,
        if (appointmentId != null) 'appointment_id': appointmentId,
      };
}
