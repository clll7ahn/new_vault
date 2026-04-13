import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Auth State (Sealed)
// ──────────────────────────────────────────────────────────────────────────────

/// 인증 상태를 표현하는 sealed 클래스
sealed class AuthState {
  const AuthState();
}

/// 초기 로딩 (앱 재시작, 자동 로그인 확인 중)
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// 인증됨
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

/// 미인증 (비로그인)
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// 오류 상태
final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// Auth Notifier
// ──────────────────────────────────────────────────────────────────────────────

/// 인증 상태를 관리하는 Riverpod Notifier
///
/// 상태 흐름:
///   AuthLoading → AuthAuthenticated | AuthUnauthenticated | AuthError
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 앱 시작 시 자동 로그인 시도
    _tryAutoLogin();
    return const AuthLoading();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  // ──────────────────────────────────────────
  // 자동 로그인
  // ──────────────────────────────────────────

  Future<void> _tryAutoLogin() async {
    try {
      final user = await _repo.tryAutoLogin();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  // ──────────────────────────────────────────
  // 로그인
  // ──────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final authResponse = await _repo.login(email: email, password: password);
      state = AuthAuthenticated(authResponse.user);
    } on Exception catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  // ──────────────────────────────────────────
  // 회원가입
  // ──────────────────────────────────────────

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AuthLoading();
    try {
      final authResponse = await _repo.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = AuthAuthenticated(authResponse.user);
    } on Exception catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  // ──────────────────────────────────────────
  // 로그아웃
  // ──────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _repo.logout();
    } finally {
      state = const AuthUnauthenticated();
    }
  }

  // ──────────────────────────────────────────
  // 오류 초기화
  // ──────────────────────────────────────────

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  // ──────────────────────────────────────────
  // 편의 getter
  // ──────────────────────────────────────────

  bool get isAuthenticated => state is AuthAuthenticated;
  bool get isLoading => state is AuthLoading;
  UserModel? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;

  // ──────────────────────────────────────────
  // 내부 유틸리티
  // ──────────────────────────────────────────

  String _parseError(Exception e) {
    final message = e.toString();
    if (message.contains('401') || message.contains('Unauthorized')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    } else if (message.contains('409') || message.contains('Conflict')) {
      return '이미 사용 중인 이메일입니다.';
    } else if (message.contains('SocketException') ||
        message.contains('network')) {
      return '네트워크 연결을 확인해 주세요.';
    } else if (message.contains('timeout')) {
      return '서버 응답이 없습니다. 잠시 후 다시 시도해 주세요.';
    }
    return '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Provider 선언
// ──────────────────────────────────────────────────────────────────────────────

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// 현재 사용자 편의 provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthAuthenticated ? authState.user : null;
});

/// 로그인 여부 편의 provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider) is AuthAuthenticated;
});
