import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 어르신 모드 상태
// ──────────────────────────────────────────────────────────────────────────────

/// 어르신 모드 설정 상태
class AccessibilityState {
  const AccessibilityState({
    this.isElderlyMode = false,
  });

  /// 어르신 모드 활성화 여부
  ///
  /// 활성화 시:
  /// - 폰트 크기 +6sp (bodyLarge 16→22sp 등)
  /// - 버튼 높이 64dp
  /// - 빠른 메뉴 4개 → 3개 (예약/대기/전화)
  final bool isElderlyMode;

  AccessibilityState copyWith({bool? isElderlyMode}) {
    return AccessibilityState(
      isElderlyMode: isElderlyMode ?? this.isElderlyMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilityState &&
          runtimeType == other.runtimeType &&
          isElderlyMode == other.isElderlyMode;

  @override
  int get hashCode => isElderlyMode.hashCode;
}

// ──────────────────────────────────────────────────────────────────────────────
// 스토리지 키
// ──────────────────────────────────────────────────────────────────────────────

class _AccessibilityKeys {
  _AccessibilityKeys._();
  static const String elderlyMode = 'accessibility_elderly_mode';
}

// ──────────────────────────────────────────────────────────────────────────────
// Notifier
// ──────────────────────────────────────────────────────────────────────────────

/// 어르신 모드 상태를 관리하는 Riverpod Notifier
///
/// - SecureStorage를 통해 설정을 영속적으로 저장/복원합니다.
/// - build() 시 저장된 값을 읽어 초기화합니다.
class AccessibilityNotifier extends AsyncNotifier<AccessibilityState> {
  static final _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<AccessibilityState> build() async {
    final raw = await _storage.read(key: _AccessibilityKeys.elderlyMode);
    return AccessibilityState(isElderlyMode: raw == 'true');
  }

  /// 어르신 모드 토글
  Future<void> toggleElderlyMode() async {
    final current = state.valueOrNull ?? const AccessibilityState();
    final next = current.copyWith(isElderlyMode: !current.isElderlyMode);
    await _setElderlyMode(next.isElderlyMode);
    state = AsyncData(next);
  }

  /// 어르신 모드 명시적 설정
  Future<void> setElderlyMode(bool value) async {
    final current = state.valueOrNull ?? const AccessibilityState();
    if (current.isElderlyMode == value) return;
    await _setElderlyMode(value);
    state = AsyncData(current.copyWith(isElderlyMode: value));
  }

  Future<void> _setElderlyMode(bool value) async {
    await _storage.write(
      key: _AccessibilityKeys.elderlyMode,
      value: value.toString(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Provider 선언
// ──────────────────────────────────────────────────────────────────────────────

final accessibilityProvider =
    AsyncNotifierProvider<AccessibilityNotifier, AccessibilityState>(
  AccessibilityNotifier.new,
);

/// 어르신 모드 bool 편의 provider (로딩 중엔 false 반환)
final isElderlyModeProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityProvider).valueOrNull?.isElderlyMode ?? false;
});
