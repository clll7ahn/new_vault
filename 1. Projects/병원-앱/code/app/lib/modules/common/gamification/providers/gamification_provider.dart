import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gamification_repository.dart';
import '../domain/gamification_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final gamificationRepositoryProvider =
    Provider<GamificationRepository>((ref) {
  return GamificationRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// 미션 Providers
// ──────────────────────────────────────────────────────────────────────────────

final allMissionsProvider =
    FutureProvider<List<MissionModel>>((ref) {
  return ref.read(gamificationRepositoryProvider).getMissions();
});

final myMissionsProvider =
    FutureProvider<List<MissionModel>>((ref) {
  return ref.read(gamificationRepositoryProvider).getMyMissions();
});

// ──────────────────────────────────────────────────────────────────────────────
// 포인트 잔액 Provider
// ──────────────────────────────────────────────────────────────────────────────

final pointBalanceProvider = FutureProvider<int>((ref) {
  return ref.read(gamificationRepositoryProvider).getPoints();
});

// ──────────────────────────────────────────────────────────────────────────────
// 포인트 이력 Provider
// ──────────────────────────────────────────────────────────────────────────────

final pointHistoryProvider =
    FutureProvider<List<PointHistoryModel>>((ref) {
  return ref.read(gamificationRepositoryProvider).getPointHistory();
});

// ──────────────────────────────────────────────────────────────────────────────
// 배지 Providers
// ──────────────────────────────────────────────────────────────────────────────

final allBadgesProvider = FutureProvider<List<BadgeModel>>((ref) {
  return ref.read(gamificationRepositoryProvider).getBadges();
});

final myBadgesProvider = FutureProvider<List<BadgeModel>>((ref) {
  return ref.read(gamificationRepositoryProvider).getMyBadges();
});

// ──────────────────────────────────────────────────────────────────────────────
// CheckIn Notifier
// ──────────────────────────────────────────────────────────────────────────────

sealed class CheckInState {
  const CheckInState();
}

final class CheckInIdle extends CheckInState {
  const CheckInIdle();
}

final class CheckInLoading extends CheckInState {
  const CheckInLoading();
}

final class CheckInSuccess extends CheckInState {
  const CheckInSuccess(this.pointsEarned);
  final int pointsEarned;
}

final class CheckInAlreadyDone extends CheckInState {
  const CheckInAlreadyDone();
}

final class CheckInError extends CheckInState {
  const CheckInError(this.message);
  final String message;
}

class CheckInNotifier extends Notifier<CheckInState> {
  @override
  CheckInState build() => const CheckInIdle();

  GamificationRepository get _repo =>
      ref.read(gamificationRepositoryProvider);

  Future<void> checkIn() async {
    if (state is CheckInLoading) return;
    state = const CheckInLoading();
    try {
      final earned = await _repo.checkIn();
      if (earned == 0) {
        state = const CheckInAlreadyDone();
      } else {
        // 포인트 잔액 캐시 무효화
        ref.invalidate(pointBalanceProvider);
        ref.invalidate(pointHistoryProvider);
        ref.invalidate(myMissionsProvider);
        state = CheckInSuccess(earned);
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('409') || msg.contains('already')) {
        state = const CheckInAlreadyDone();
      } else {
        state = CheckInError(_parseError(e));
      }
    }
  }

  void reset() => state = const CheckInIdle();

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    return '출석 체크 중 오류가 발생했습니다.';
  }
}

final checkInProvider =
    NotifierProvider<CheckInNotifier, CheckInState>(CheckInNotifier.new);
