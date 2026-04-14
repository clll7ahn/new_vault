import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/family_medicine_repository.dart';
import '../domain/family_medicine_model.dart';

final familyMedicineRepositoryProvider =
    Provider<FamilyMedicineRepository>((_) => FamilyMedicineRepository());

final healthCheckResultsProvider =
    FutureProvider<List<HealthCheckResultModel>>((ref) {
  return ref.read(familyMedicineRepositoryProvider).getHealthCheckResults();
});

final lifestyleLogsProvider =
    FutureProvider<List<LifestyleLogModel>>((ref) {
  return ref.read(familyMedicineRepositoryProvider).getLifestyleLogs();
});

final bmiRecordsProvider =
    FutureProvider<List<BmiRecordModel>>((ref) {
  return ref.read(familyMedicineRepositoryProvider).getBmiRecords();
});

// ── 생활습관 추가 Notifier ────────────────────────────────────────────────────

sealed class LifestyleAddState { const LifestyleAddState(); }
final class LifestyleAddIdle extends LifestyleAddState { const LifestyleAddIdle(); }
final class LifestyleAddLoading extends LifestyleAddState { const LifestyleAddLoading(); }
final class LifestyleAddSuccess extends LifestyleAddState {
  const LifestyleAddSuccess(this.log);
  final LifestyleLogModel log;
}
final class LifestyleAddError extends LifestyleAddState {
  const LifestyleAddError(this.message);
  final String message;
}

class LifestyleAddNotifier extends Notifier<LifestyleAddState> {
  @override
  LifestyleAddState build() => const LifestyleAddIdle();

  FamilyMedicineRepository get _repo =>
      ref.read(familyMedicineRepositoryProvider);

  Future<void> add(AddLifestyleLogDto dto) async {
    state = const LifestyleAddLoading();
    try {
      final log = await _repo.addLifestyleLog(dto);
      ref.invalidate(lifestyleLogsProvider);
      state = LifestyleAddSuccess(log);
    } on Exception catch (e) {
      state = LifestyleAddError(e.toString());
    }
  }

  void reset() => state = const LifestyleAddIdle();
}

final lifestyleAddProvider =
    NotifierProvider<LifestyleAddNotifier, LifestyleAddState>(
  LifestyleAddNotifier.new,
);

// ── BMI 추가 Notifier ─────────────────────────────────────────────────────────

sealed class BmiAddState { const BmiAddState(); }
final class BmiAddIdle extends BmiAddState { const BmiAddIdle(); }
final class BmiAddLoading extends BmiAddState { const BmiAddLoading(); }
final class BmiAddSuccess extends BmiAddState {
  const BmiAddSuccess(this.record);
  final BmiRecordModel record;
}
final class BmiAddError extends BmiAddState {
  const BmiAddError(this.message);
  final String message;
}

class BmiAddNotifier extends Notifier<BmiAddState> {
  @override
  BmiAddState build() => const BmiAddIdle();

  FamilyMedicineRepository get _repo =>
      ref.read(familyMedicineRepositoryProvider);

  Future<void> add(AddBmiRecordDto dto) async {
    state = const BmiAddLoading();
    try {
      final rec = await _repo.addBmiRecord(dto);
      ref.invalidate(bmiRecordsProvider);
      state = BmiAddSuccess(rec);
    } on Exception catch (e) {
      state = BmiAddError(e.toString());
    }
  }

  void reset() => state = const BmiAddIdle();
}

final bmiAddProvider =
    NotifierProvider<BmiAddNotifier, BmiAddState>(BmiAddNotifier.new);
