import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/obstetrics_repository.dart';
import '../domain/obstetrics_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final obstetricsRepositoryProvider = Provider<ObstetricsRepository>(
  (_) => ObstetricsRepository(),
);

// ── 임신 정보 ─────────────────────────────────────────────────────────────────

final pregnancyProvider = FutureProvider<PregnancyModel?>((ref) {
  return ref.read(obstetricsRepositoryProvider).getPregnancy();
});

// ── 산전 검진 ─────────────────────────────────────────────────────────────────

final checkupsProvider = FutureProvider<List<CheckupModel>>((ref) {
  return ref.read(obstetricsRepositoryProvider).getCheckups();
});

// ── 오늘 태동 횟수 ────────────────────────────────────────────────────────────

final fetalMovementsTodayProvider =
    FutureProvider<List<FetalMovementModel>>((ref) {
  return ref.read(obstetricsRepositoryProvider).getFetalMovementsToday();
});

// 로컬 태동 카운터 (실시간 카운트 — 앱 세션 내)
final fetalMovementCountProvider = StateProvider<int>((ref) => 0);

// ── 태동 추가 Notifier ────────────────────────────────────────────────────────

sealed class FetalMovementAddState {
  const FetalMovementAddState();
}

final class FetalMovementIdle extends FetalMovementAddState {
  const FetalMovementIdle();
}

final class FetalMovementLoading extends FetalMovementAddState {
  const FetalMovementLoading();
}

final class FetalMovementSuccess extends FetalMovementAddState {
  const FetalMovementSuccess(this.model);
  final FetalMovementModel model;
}

final class FetalMovementError extends FetalMovementAddState {
  const FetalMovementError(this.message);
  final String message;
}

class FetalMovementNotifier extends Notifier<FetalMovementAddState> {
  @override
  FetalMovementAddState build() => const FetalMovementIdle();

  ObstetricsRepository get _repo =>
      ref.read(obstetricsRepositoryProvider);

  Future<void> addOne() async {
    state = const FetalMovementLoading();
    try {
      ref.read(fetalMovementCountProvider.notifier).update((c) => c + 1);
      final model = await _repo.addFetalMovement(
        const AddFetalMovementDto(count: 1),
      );
      ref.invalidate(fetalMovementsTodayProvider);
      state = FetalMovementSuccess(model);
    } on Exception catch (e) {
      state = FetalMovementError(e.toString());
    }
  }

  void reset() => state = const FetalMovementIdle();
}

final fetalMovementNotifierProvider =
    NotifierProvider<FetalMovementNotifier, FetalMovementAddState>(
  FetalMovementNotifier.new,
);

// ── 산모 건강 기록 ────────────────────────────────────────────────────────────

final maternalLogsProvider = FutureProvider<List<MaternalLogModel>>((ref) {
  return ref.read(obstetricsRepositoryProvider).getMaternalLogs();
});
