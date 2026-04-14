import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/health_repository.dart';
import '../domain/health_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// 일일 집계 Provider (날짜별)
// ──────────────────────────────────────────────────────────────────────────────

final dailySummaryProvider =
    FutureProvider.family<List<HealthSummary>, DateTime>((ref, date) {
  // 시간 정보 제거하여 캐시 키 안정화
  final normalised = DateTime(date.year, date.month, date.day);
  return ref.read(healthRepositoryProvider).getDailySummary(normalised);
});

// ──────────────────────────────────────────────────────────────────────────────
// 주간 집계 Provider
// ──────────────────────────────────────────────────────────────────────────────

final weeklyProvider = FutureProvider<List<HealthSummary>>((ref) {
  return ref.read(healthRepositoryProvider).getWeeklySummary();
});

// ──────────────────────────────────────────────────────────────────────────────
// 전체 스냅샷 Provider
// ──────────────────────────────────────────────────────────────────────────────

final snapshotProvider = FutureProvider<HealthSnapshot>((ref) {
  return ref.read(healthRepositoryProvider).getSnapshot();
});

// ──────────────────────────────────────────────────────────────────────────────
// 타입별 기간 기록 Provider
// ──────────────────────────────────────────────────────────────────────────────

typedef HealthRecordsQuery = ({
  HealthRecordType type,
  DateTime from,
  DateTime to,
});

final healthRecordsProvider = FutureProvider.family<List<HealthRecordModel>,
    HealthRecordsQuery>((ref, query) {
  return ref.read(healthRepositoryProvider).getRecords(
        type: query.type,
        from: query.from,
        to: query.to,
      );
});

// ──────────────────────────────────────────────────────────────────────────────
// 건강 기록 추가 Notifier
// ──────────────────────────────────────────────────────────────────────────────

sealed class HealthAddState {
  const HealthAddState();
}

final class HealthAddIdle extends HealthAddState {
  const HealthAddIdle();
}

final class HealthAddLoading extends HealthAddState {
  const HealthAddLoading();
}

final class HealthAddSuccess extends HealthAddState {
  const HealthAddSuccess(this.record);
  final HealthRecordModel record;
}

final class HealthAddError extends HealthAddState {
  const HealthAddError(this.message);
  final String message;
}

class HealthAddNotifier extends Notifier<HealthAddState> {
  @override
  HealthAddState build() => const HealthAddIdle();

  HealthRepository get _repo => ref.read(healthRepositoryProvider);

  Future<void> add(AddHealthRecordDto dto) async {
    state = const HealthAddLoading();
    try {
      final record = await _repo.addRecord(dto);
      // 관련 캐시 무효화
      ref.invalidate(snapshotProvider);
      ref.invalidate(weeklyProvider);
      final today = DateTime.now();
      ref.invalidate(dailySummaryProvider(
        DateTime(today.year, today.month, today.day),
      ));
      state = HealthAddSuccess(record);
    } on Exception catch (e) {
      state = HealthAddError(_parseError(e));
    }
  }

  void reset() => state = const HealthAddIdle();

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    if (msg.contains('422')) {
      return '입력값이 올바르지 않습니다.';
    }
    return '건강 수치 저장 중 오류가 발생했습니다.';
  }
}

final healthAddProvider =
    NotifierProvider<HealthAddNotifier, HealthAddState>(
  HealthAddNotifier.new,
);
