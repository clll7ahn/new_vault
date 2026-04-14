import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/guardian_repository.dart';
import '../domain/guardian_model.dart';
import '../domain/user_model.dart';
import 'auth_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final guardianRepositoryProvider = Provider<GuardianRepository>((ref) {
  return GuardianRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// 피보호자 목록 Provider (내가 보호하는 사람들)
// ──────────────────────────────────────────────────────────────────────────────

/// 내가 보호하는 피보호자 목록 (보호자 입장에서 조회)
final dependentsProvider =
    AsyncNotifierProvider<DependentsNotifier, List<GuardianLink>>(
  DependentsNotifier.new,
);

class DependentsNotifier extends AsyncNotifier<List<GuardianLink>> {
  @override
  Future<List<GuardianLink>> build() async {
    final isAuth = ref.watch(isAuthenticatedProvider);
    if (!isAuth) return [];
    return ref.read(guardianRepositoryProvider).getMyDependents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(guardianRepositoryProvider).getMyDependents(),
    );
  }

  Future<void> unlink(String linkId) async {
    await ref.read(guardianRepositoryProvider).unlinkGuardian(linkId);
    await refresh();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 보호자 목록 Provider (나를 보호하는 사람들)
// ──────────────────────────────────────────────────────────────────────────────

/// 나를 보호하는 보호자 목록 (피보호자 입장에서 조회)
final guardiansProvider =
    AsyncNotifierProvider<GuardiansNotifier, List<GuardianLink>>(
  GuardiansNotifier.new,
);

class GuardiansNotifier extends AsyncNotifier<List<GuardianLink>> {
  @override
  Future<List<GuardianLink>> build() async {
    final isAuth = ref.watch(isAuthenticatedProvider);
    if (!isAuth) return [];
    return ref.read(guardianRepositoryProvider).getMyGuardians();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(guardianRepositoryProvider).getMyGuardians(),
    );
  }

  /// 연결 코드로 보호자 연결
  Future<void> link({
    required String code,
    required GuardianRelationship relationship,
  }) async {
    await ref.read(guardianRepositoryProvider).linkGuardian(
          code: code,
          relationship: relationship,
        );
    await refresh();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 활성 계정 Provider (대리 관리 모드 포함)
// ──────────────────────────────────────────────────────────────────────────────

/// 현재 활성 계정 상태
///
/// - [null]: 내 계정으로 정상 접속 중
/// - [UserModel]: 해당 피보호자 계정으로 대리 관리 중
class ActiveAccountNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => null; // 기본: 내 계정

  /// 피보호자 계정으로 전환
  Future<void> switchToDependentAccount(String dependentId) async {
    final dependent = await ref
        .read(guardianRepositoryProvider)
        .switchAccount(dependentId);
    state = dependent;
  }

  /// 내 계정으로 복귀
  void switchBackToMyAccount() {
    state = null;
  }

  bool get isProxyMode => state != null;
}

final activeAccountProvider =
    NotifierProvider<ActiveAccountNotifier, UserModel?>(
  ActiveAccountNotifier.new,
);

/// 현재 실질적으로 사용 중인 사용자 (내 계정 또는 대리 관리 계정)
///
/// 대리 관리 중이면 피보호자 정보 반환, 아니면 내 계정 정보 반환
final effectiveUserProvider = Provider<UserModel?>((ref) {
  final proxy = ref.watch(activeAccountProvider);
  if (proxy != null) return proxy;
  return ref.watch(currentUserProvider);
});

/// 대리 관리 모드 여부
final isProxyModeProvider = Provider<bool>((ref) {
  return ref.watch(activeAccountProvider) != null;
});

// ──────────────────────────────────────────────────────────────────────────────
// 연결 코드 생성 Provider
// ──────────────────────────────────────────────────────────────────────────────

/// 연결 코드 생성 (FutureProvider.family 로 호출 시 사용)
///
/// 사용: ref.read(linkCodeGeneratorProvider.future)
final linkCodeGeneratorProvider =
    FutureProvider.autoDispose<GuardianLinkCode>((ref) async {
  return ref.read(guardianRepositoryProvider).generateLinkCode();
});
