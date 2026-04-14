/// 보호자 연동 계정 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// 관계 유형
// ──────────────────────────────────────────────────────────────────────────────

/// 보호자와 피보호자 간의 관계
enum GuardianRelationship {
  parent('부모'),
  child('자녀'),
  spouse('배우자'),
  sibling('형제/자매'),
  other('기타');

  const GuardianRelationship(this.label);
  final String label;

  static GuardianRelationship fromJson(String value) {
    return GuardianRelationship.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GuardianRelationship.other,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// GuardianLink — 보호자-피보호자 연결 정보
// ──────────────────────────────────────────────────────────────────────────────

/// 보호자와 피보호자 간의 연결 레코드
///
/// - [id]: 연결 레코드 고유 ID
/// - [guardianUserId]: 보호하는 사람(보호자)의 userId
/// - [dependentUserId]: 보호받는 사람(피보호자)의 userId
/// - [relationship]: 관계 유형
/// - [createdAt]: 연결 생성 시각
class GuardianLink {
  const GuardianLink({
    required this.id,
    required this.guardianUserId,
    required this.dependentUserId,
    required this.relationship,
    required this.createdAt,
    this.dependentName,
    this.dependentEmail,
    this.guardianName,
    this.guardianEmail,
  });

  final String id;
  final String guardianUserId;
  final String dependentUserId;
  final GuardianRelationship relationship;
  final DateTime createdAt;

  /// 조회 편의용 — 상대방 이름/이메일 (서버 응답에 포함될 수 있음)
  final String? dependentName;
  final String? dependentEmail;
  final String? guardianName;
  final String? guardianEmail;

  factory GuardianLink.fromJson(Map<String, dynamic> json) {
    return GuardianLink(
      id: json['id'] as String,
      guardianUserId: json['guardian_user_id'] as String,
      dependentUserId: json['dependent_user_id'] as String,
      relationship:
          GuardianRelationship.fromJson(json['relationship'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      dependentName: json['dependent_name'] as String?,
      dependentEmail: json['dependent_email'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianEmail: json['guardian_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'guardian_user_id': guardianUserId,
        'dependent_user_id': dependentUserId,
        'relationship': relationship.name,
        'created_at': createdAt.toIso8601String(),
        if (dependentName != null) 'dependent_name': dependentName,
        if (dependentEmail != null) 'dependent_email': dependentEmail,
        if (guardianName != null) 'guardian_name': guardianName,
        if (guardianEmail != null) 'guardian_email': guardianEmail,
      };

  GuardianLink copyWith({
    String? id,
    String? guardianUserId,
    String? dependentUserId,
    GuardianRelationship? relationship,
    DateTime? createdAt,
    String? dependentName,
    String? dependentEmail,
    String? guardianName,
    String? guardianEmail,
  }) {
    return GuardianLink(
      id: id ?? this.id,
      guardianUserId: guardianUserId ?? this.guardianUserId,
      dependentUserId: dependentUserId ?? this.dependentUserId,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt ?? this.createdAt,
      dependentName: dependentName ?? this.dependentName,
      dependentEmail: dependentEmail ?? this.dependentEmail,
      guardianName: guardianName ?? this.guardianName,
      guardianEmail: guardianEmail ?? this.guardianEmail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardianLink &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GuardianLink(id: $id, guardian: $guardianUserId → dependent: $dependentUserId, '
      'rel: ${relationship.label})';
}

// ──────────────────────────────────────────────────────────────────────────────
// LinkRequest — 연결 코드로 링크 요청 시 사용
// ──────────────────────────────────────────────────────────────────────────────

/// 연결 코드 생성 응답
class GuardianLinkCode {
  const GuardianLinkCode({
    required this.code,
    required this.expiresAt,
  });

  final String code;
  final DateTime expiresAt;

  factory GuardianLinkCode.fromJson(Map<String, dynamic> json) {
    return GuardianLinkCode(
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}
