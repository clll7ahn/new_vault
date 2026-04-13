import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../domain/user_model.dart';

/// 인증 API 응답 모델
class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserModel user;
  final String accessToken;
  final String refreshToken;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }
}

/// 인증 관련 API 호출을 담당하는 레포지토리
///
/// - login: 이메일/비밀번호 로그인
/// - register: 신규 회원가입
/// - refresh: 액세스 토큰 갱신
/// - logout: 서버 측 세션 무효화
/// - getMe: 현재 로그인 사용자 조회
class AuthRepository {
  AuthRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  /// 이메일 + 비밀번호 로그인
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data!);

    // 토큰 보안 스토리지에 저장
    await SecureStorage.instance.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      userId: authResponse.user.id,
    );

    return authResponse;
  }

  /// 신규 회원가입
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data!);

    await SecureStorage.instance.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      userId: authResponse.user.id,
    );

    return authResponse;
  }

  /// 리프레시 토큰으로 액세스 토큰 갱신
  Future<String> refresh() async {
    final refreshToken = await SecureStorage.instance.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('리프레시 토큰이 없습니다. 다시 로그인해 주세요.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );

    final newAccessToken = response.data!['access_token'] as String;
    final newRefreshToken = response.data!['refresh_token'] as String?;

    await SecureStorage.instance.saveAccessToken(newAccessToken);
    if (newRefreshToken != null) {
      await SecureStorage.instance.saveRefreshToken(newRefreshToken);
    }

    return newAccessToken;
  }

  /// 서버 측 세션 무효화 + 로컬 토큰 삭제
  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiConstants.logout);
    } on DioException catch (_) {
      // 서버 오류여도 로컬 정리는 반드시 수행
    } finally {
      await SecureStorage.instance.clearAll();
    }
  }

  /// 현재 로그인 사용자 정보 조회
  Future<UserModel> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiConstants.me);
    return UserModel.fromJson(response.data!);
  }

  /// 저장된 토큰으로 자동 로그인 시도 (앱 재시작 시 사용)
  Future<UserModel?> tryAutoLogin() async {
    final hasTokens = await SecureStorage.instance.hasValidTokens();
    if (!hasTokens) return null;

    try {
      return await getMe();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // 액세스 토큰 만료 → 갱신 시도
        try {
          await refresh();
          return await getMe();
        } catch (_) {
          await SecureStorage.instance.clearAll();
          return null;
        }
      }
      rethrow;
    }
  }
}
