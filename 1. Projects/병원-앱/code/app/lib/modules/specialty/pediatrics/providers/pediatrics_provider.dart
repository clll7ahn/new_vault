import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pediatrics_repository.dart';
import '../domain/pediatrics_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final pediatricsRepositoryProvider = Provider<PediatricsRepository>(
  (_) => PediatricsRepository(),
);

// ── 자녀 목록 ─────────────────────────────────────────────────────────────────

final childrenProvider = FutureProvider<List<ChildModel>>((ref) {
  return ref.read(pediatricsRepositoryProvider).getChildren();
});

// ── 선택된 자녀 ID ────────────────────────────────────────────────────────────

final selectedChildIdProvider = StateProvider<String?>((ref) => null);

// ── 성장 기록 ─────────────────────────────────────────────────────────────────

final growthLogsProvider =
    FutureProvider.family<List<GrowthLogModel>, String>((ref, childId) {
  return ref.read(pediatricsRepositoryProvider).getGrowthLogs(childId);
});

// ── 예방접종 목록 ─────────────────────────────────────────────────────────────

final vaccinationsProvider =
    FutureProvider.family<List<VaccinationModel>, String>((ref, childId) {
  return ref.read(pediatricsRepositoryProvider).getVaccinations(childId);
});

// ── 예방접종 업데이트 Notifier ──────────────────────────────────────────────

sealed class VaccinationUpdateState {
  const VaccinationUpdateState();
}

final class VaccinationUpdateIdle extends VaccinationUpdateState {
  const VaccinationUpdateIdle();
}

final class VaccinationUpdateLoading extends VaccinationUpdateState {
  const VaccinationUpdateLoading();
}

final class VaccinationUpdateSuccess extends VaccinationUpdateState {
  const VaccinationUpdateSuccess(this.vaccination);
  final VaccinationModel vaccination;
}

final class VaccinationUpdateError extends VaccinationUpdateState {
  const VaccinationUpdateError(this.message);
  final String message;
}

class VaccinationUpdateNotifier extends Notifier<VaccinationUpdateState> {
  @override
  VaccinationUpdateState build() => const VaccinationUpdateIdle();

  PediatricsRepository get _repo =>
      ref.read(pediatricsRepositoryProvider);

  Future<void> markCompleted({
    required String vaccinationId,
    required String childId,
  }) async {
    state = const VaccinationUpdateLoading();
    try {
      final updated = await _repo.updateVaccination(
        vaccinationId: vaccinationId,
        status: VaccinationStatus.completed,
        administeredDate: DateTime.now(),
      );
      ref.invalidate(vaccinationsProvider(childId));
      state = VaccinationUpdateSuccess(updated);
    } on Exception catch (e) {
      state = VaccinationUpdateError(e.toString());
    }
  }

  void reset() => state = const VaccinationUpdateIdle();
}

final vaccinationUpdateProvider =
    NotifierProvider<VaccinationUpdateNotifier, VaccinationUpdateState>(
  VaccinationUpdateNotifier.new,
);
