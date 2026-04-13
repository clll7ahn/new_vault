/// API 관련 상수
///
/// 환경에 따라 baseUrl을 전환하려면 flutter run --dart-define=ENV=prod 사용
class ApiConstants {
  ApiConstants._();

  // ──────────────────────────────────────────
  // Base URL
  // ──────────────────────────────────────────
  static const String _devBaseUrl = 'http://10.0.2.2:8000'; // Android 에뮬레이터 → localhost
  static const String _prodBaseUrl = 'https://api.hospital-app.com';

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: _devBaseUrl,
  );

  // ──────────────────────────────────────────
  // API 버전 prefix
  // ──────────────────────────────────────────
  static const String apiV1 = '/api/v1';

  // ──────────────────────────────────────────
  // Auth 엔드포인트
  // ──────────────────────────────────────────
  static const String login = '$apiV1/auth/login';
  static const String register = '$apiV1/auth/register';
  static const String refresh = '$apiV1/auth/refresh';
  static const String logout = '$apiV1/auth/logout';
  static const String me = '$apiV1/auth/me';

  // ──────────────────────────────────────────
  // 예약 엔드포인트
  // ──────────────────────────────────────────
  static const String appointments = '$apiV1/appointments';
  static const String availableSlots = '$apiV1/appointments/available-slots';

  // ──────────────────────────────────────────
  // 진료 기록 엔드포인트
  // ──────────────────────────────────────────
  static const String medicalRecords = '$apiV1/medical-records';

  // ──────────────────────────────────────────
  // 처방전 엔드포인트
  // ──────────────────────────────────────────
  static const String prescriptions = '$apiV1/prescriptions';

  // ──────────────────────────────────────────
  // 알림 엔드포인트
  // ──────────────────────────────────────────
  static const String notifications = '$apiV1/notifications';
  static const String fcmToken = '$apiV1/notifications/fcm-token';

  // ──────────────────────────────────────────
  // 의사/부서 엔드포인트
  // ──────────────────────────────────────────
  static const String doctors = '$apiV1/doctors';
  static const String departments = '$apiV1/departments';

  // ──────────────────────────────────────────
  // Timeout 설정 (밀리초)
  // ──────────────────────────────────────────
  static const int connectTimeout = 10000; // 10초
  static const int receiveTimeout = 30000; // 30초
  static const int sendTimeout = 30000;    // 30초

  // ──────────────────────────────────────────
  // 헤더 키
  // ──────────────────────────────────────────
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const String contentType = 'application/json';
}
