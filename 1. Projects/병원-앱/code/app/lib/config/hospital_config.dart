/// 활성화 가능한 병원 모듈 목록
///
/// 병원 규모·계약에 따라 켜고 끌 수 있는 기능 단위입니다.
enum HospitalModule {
  /// 진료 예약 시스템
  appointment,

  /// 전자 처방전 조회
  prescription,

  /// 진료 기록 조회
  medicalRecord,

  /// 알림 (예약 리마인더, 검사 결과 등)
  notification,

  /// 증명서 발급 (진단서, 소견서 등)
  certificate,

  /// 비대면 진료 (화상 진료)
  telemedicine,

  /// 건강 검진 예약
  healthCheckup,

  /// 진료비 결제
  payment,
}

/// 병원별 설정 모델
///
/// 각 병원 인스턴스에 맞게 커스터마이징되는 설정값입니다.
/// 빌드 타임에 --dart-define 또는 환경 파일로 주입합니다.
class HospitalConfig {
  const HospitalConfig({
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalShortName,
    required this.activeModules,
    this.logoAssetPath,
    this.primaryColor,
    this.supportPhone,
    this.supportEmail,
    this.address,
    this.businessHours,
    this.enableElderlyMode = false,
    this.defaultLocale = 'ko_KR',
  });

  /// 병원 고유 식별자 (서버 연동 키)
  final String hospitalId;

  /// 병원 전체 이름 (예: "서울중앙병원")
  final String hospitalName;

  /// 병원 약칭 (앱바, 탭바 등 짧은 공간 표시용)
  final String hospitalShortName;

  /// 활성화된 모듈 목록
  final List<HospitalModule> activeModules;

  /// 병원 로고 이미지 경로 (assets/)
  final String? logoAssetPath;

  /// 병원 브랜드 색상 (hex 문자열, 예: '#1A3A5C')
  final String? primaryColor;

  /// 고객 지원 전화번호
  final String? supportPhone;

  /// 고객 지원 이메일
  final String? supportEmail;

  /// 병원 주소
  final String? address;

  /// 운영 시간 (표시용 문자열, 예: "평일 08:30 – 17:30")
  final String? businessHours;

  /// 어르신 모드 기본 활성화 여부
  final bool enableElderlyMode;

  /// 기본 로케일
  final String defaultLocale;

  // ──────────────────────────────────────────
  // 편의 메서드
  // ──────────────────────────────────────────

  /// 특정 모듈이 활성화되어 있는지 확인
  bool isModuleActive(HospitalModule module) =>
      activeModules.contains(module);

  /// 현재 설정의 복사본 생성 (일부 값 오버라이드)
  HospitalConfig copyWith({
    String? hospitalId,
    String? hospitalName,
    String? hospitalShortName,
    List<HospitalModule>? activeModules,
    String? logoAssetPath,
    String? primaryColor,
    String? supportPhone,
    String? supportEmail,
    String? address,
    String? businessHours,
    bool? enableElderlyMode,
    String? defaultLocale,
  }) {
    return HospitalConfig(
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalShortName: hospitalShortName ?? this.hospitalShortName,
      activeModules: activeModules ?? this.activeModules,
      logoAssetPath: logoAssetPath ?? this.logoAssetPath,
      primaryColor: primaryColor ?? this.primaryColor,
      supportPhone: supportPhone ?? this.supportPhone,
      supportEmail: supportEmail ?? this.supportEmail,
      address: address ?? this.address,
      businessHours: businessHours ?? this.businessHours,
      enableElderlyMode: enableElderlyMode ?? this.enableElderlyMode,
      defaultLocale: defaultLocale ?? this.defaultLocale,
    );
  }

  @override
  String toString() =>
      'HospitalConfig(id: $hospitalId, name: $hospitalName, '
      'modules: ${activeModules.map((m) => m.name).join(', ')})';
}

// ──────────────────────────────────────────────────────────────────────────────
// 기본 설정 (개발/데모 환경)
// ──────────────────────────────────────────────────────────────────────────────

/// 전체 모듈이 활성화된 데모 설정
const HospitalConfig defaultHospitalConfig = HospitalConfig(
  hospitalId: 'demo-hospital-001',
  hospitalName: '데모 병원',
  hospitalShortName: '데모',
  activeModules: [
    HospitalModule.appointment,
    HospitalModule.prescription,
    HospitalModule.medicalRecord,
    HospitalModule.notification,
    HospitalModule.certificate,
    HospitalModule.payment,
  ],
  supportPhone: '1599-0000',
  supportEmail: 'support@demo-hospital.com',
  address: '서울특별시 중구 세종대로 1',
  businessHours: '평일 08:30 – 17:30 / 토요일 08:30 – 12:30',
  enableElderlyMode: false,
);

/// 소규모 의원 설정 예시 (예약 + 알림만 활성화)
const HospitalConfig smallClinicConfig = HospitalConfig(
  hospitalId: 'small-clinic-001',
  hospitalName: '예시 의원',
  hospitalShortName: '예시',
  activeModules: [
    HospitalModule.appointment,
    HospitalModule.notification,
  ],
  businessHours: '평일 09:00 – 18:00',
  enableElderlyMode: true, // 소규모 의원 = 어르신 환자 비율 높음
);

/// 종합병원 설정 예시 (전체 모듈 + 비대면 진료)
const HospitalConfig generalHospitalConfig = HospitalConfig(
  hospitalId: 'general-hospital-001',
  hospitalName: '예시 종합병원',
  hospitalShortName: '예시종합',
  activeModules: HospitalModule.values, // 모든 모듈 활성화
  businessHours: '24시간 응급실 운영 / 외래 평일 08:00 – 17:00',
);
