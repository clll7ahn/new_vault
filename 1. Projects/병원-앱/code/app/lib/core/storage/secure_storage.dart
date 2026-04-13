import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 보안 스토리지 키 상수
class _StorageKeys {
  _StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
}

/// JWT 토큰 및 민감 정보를 OS 보안 키체인에 저장
///
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences (API 23+)
class SecureStorage {
  SecureStorage._() : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  static final SecureStorage instance = SecureStorage._();

  final FlutterSecureStorage _storage;

  // ──────────────────────────────────────────
  // Access Token
  // ──────────────────────────────────────────

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _StorageKeys.accessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _StorageKeys.accessToken);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _StorageKeys.accessToken);
  }

  // ──────────────────────────────────────────
  // Refresh Token
  // ──────────────────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _StorageKeys.refreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _StorageKeys.refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _StorageKeys.refreshToken);
  }

  // ──────────────────────────────────────────
  // User ID
  // ──────────────────────────────────────────

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _StorageKeys.userId, value: userId);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _StorageKeys.userId);
  }

  // ──────────────────────────────────────────
  // 일괄 저장 / 삭제
  // ──────────────────────────────────────────

  /// 로그인 성공 후 토큰 일괄 저장
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      if (userId != null) saveUserId(userId),
    ]);
  }

  /// 로그아웃 시 모든 저장 정보 삭제
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// 저장된 토큰이 있는지 확인 (앱 재시작 시 자동 로그인 판단)
  Future<bool> hasValidTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null && access.isNotEmpty &&
           refresh != null && refresh.isNotEmpty;
  }
}
