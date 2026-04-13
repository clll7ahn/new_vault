import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// Dio HTTP 클라이언트 싱글턴
///
/// 기능:
/// - JWT 액세스 토큰 자동 첨부 (Authorization 헤더)
/// - 401 응답 시 리프레시 토큰으로 자동 갱신
/// - 개발 환경에서 요청/응답 로깅
class DioClient {
  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_dio),
      if (kDebugMode) _LoggingInterceptor(),
    ]);
  }

  static final DioClient instance = DioClient._();

  late final Dio _dio;

  Dio get dio => _dio;
}

// ──────────────────────────────────────────────────────────────────────────────
// Auth Interceptor
// ──────────────────────────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 인증이 필요 없는 엔드포인트는 토큰 첨부 생략
    final skipAuth = _shouldSkipAuth(options.path);
    if (!skipAuth) {
      final token = await SecureStorage.instance.getAccessToken();
      if (token != null) {
        options.headers[ApiConstants.authorizationHeader] =
            '${ApiConstants.bearerPrefix}$token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          // 실패한 요청 재시도
          final opts = err.requestOptions;
          opts.headers[ApiConstants.authorizationHeader] =
              '${ApiConstants.bearerPrefix}$newToken';
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // 리프레시 실패 → 로그아웃 처리는 auth_provider에서 담당
        await SecureStorage.instance.clearAll();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await SecureStorage.instance.getRefreshToken();
    if (refreshToken == null) return null;

    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String?;

      await SecureStorage.instance.saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await SecureStorage.instance.saveRefreshToken(newRefreshToken);
      }
      return newAccessToken;
    }
    return null;
  }

  bool _shouldSkipAuth(String path) {
    const publicPaths = [
      ApiConstants.login,
      ApiConstants.register,
      ApiConstants.refresh,
    ];
    return publicPaths.any((p) => path.startsWith(p));
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Logging Interceptor (개발 전용)
// ──────────────────────────────────────────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[DIO →] ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('       data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[DIO ←] ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[DIO ✗] ${err.response?.statusCode} ${err.requestOptions.uri}'
      '\n        ${err.message}',
    );
    handler.next(err);
  }
}
