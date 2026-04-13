/// 병원 정보 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// HospitalModel
// ──────────────────────────────────────────────────────────────────────────────

/// 병원 기본 정보
class HospitalModel {
  const HospitalModel({
    required this.name,
    required this.address,
    required this.phone,
    required this.operatingHours,
    this.logoUrl,
    this.lat,
    this.lng,
  });

  final String name;
  final String address;
  final String phone;

  /// 요일별 운영 시간. key: 요일 레이블, value: 시간 문자열
  /// 예: {"월~금": "09:00 – 18:00", "토": "09:00 – 13:00", "일·공휴일": "휴진"}
  final Map<String, String> operatingHours;

  final String? logoUrl;
  final double? lat;
  final double? lng;

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    final rawHours = json['operating_hours'];
    final Map<String, String> hours;
    if (rawHours is Map) {
      hours = rawHours.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else {
      hours = const {};
    }

    return HospitalModel(
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      operatingHours: hours,
      logoUrl: json['logo_url'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'phone': phone,
        'operating_hours': operatingHours,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// DepartmentModel
// ──────────────────────────────────────────────────────────────────────────────

/// 진료과 모델
class DepartmentModel {
  const DepartmentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final bool isActive;

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'is_active': isActive,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// DoctorModel
// ──────────────────────────────────────────────────────────────────────────────

/// 의료진 모델
class DoctorModel {
  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
    required this.departmentId,
    required this.isAvailable,
    this.profileImageUrl,
  });

  final String id;
  final String name;
  final String specialty;
  final String bio;
  final String? profileImageUrl;
  final String departmentId;
  final bool isAvailable;

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String?,
      departmentId: json['department_id'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'bio': bio,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
        'department_id': departmentId,
        'is_available': isAvailable,
      };
}
