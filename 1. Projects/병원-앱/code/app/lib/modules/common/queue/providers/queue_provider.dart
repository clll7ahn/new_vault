import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/queue_repository.dart';
import '../domain/queue_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  return QueueRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// 내 대기 상태 — 주기적 자동 새로고침
// ──────────────────────────────────────────────────────────────────────────────

/// 30초마다 자동 폴링하는 내 대기 상태 Notifier
class MyQueueNotifier extends AsyncNotifier<QueueEntryModel?> {
  static const _pollInterval = Duration(seconds: 30);

  @override
  Future<QueueEntryModel?> build() async {
    // 폴링: keepAlive + 타이머로 주기적 갱신
    final link = ref.keepAlive();
    bool disposed = false;

    ref.onDispose(() {
      disposed = true;
      link.close();
    });

    _schedulePoll(() => disposed);
    return _fetch();
  }

  void _schedulePoll(bool Function() isDisposed) {
    Future.delayed(_pollInterval, () async {
      if (isDisposed()) return;
      await refresh();
      _schedulePoll(isDisposed);
    });
  }

  Future<QueueEntryModel?> _fetch() {
    return ref.read(queueRepositoryProvider).getMyStatus();
  }

  /// 수동 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 체크인
  Future<QueueEntryModel?> checkIn(CheckInDto dto) async {
    state = const AsyncValue.loading();
    try {
      final entry = await ref.read(queueRepositoryProvider).checkIn(dto);
      state = AsyncValue.data(entry);
      // 추정 정보도 무효화
      ref.invalidate(queueEstimateProvider(entry.id));
      return entry;
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 대기 취소
  Future<void> cancel(String id) async {
    try {
      await ref.read(queueRepositoryProvider).cancelEntry(id);
      state = const AsyncValue.data(null);
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final myQueueProvider =
    AsyncNotifierProvider<MyQueueNotifier, QueueEntryModel?>(
  MyQueueNotifier.new,
);

// ──────────────────────────────────────────────────────────────────────────────
// 의사별 대기 예측
// ──────────────────────────────────────────────────────────────────────────────

final queueEstimateProvider =
    FutureProvider.family<QueueEstimate, String>((ref, doctorId) {
  return ref.read(queueRepositoryProvider).getEstimate(doctorId);
});

// ──────────────────────────────────────────────────────────────────────────────
// 특정 의사의 현재 전체 대기열 (병원 내부용 / 관리자 뷰에서 재사용 가능)
// ──────────────────────────────────────────────────────────────────────────────

final currentQueueProvider =
    FutureProvider.family<List<QueueEntryModel>, String>((ref, doctorId) {
  return ref.read(queueRepositoryProvider).getCurrentQueue(doctorId);
});
