import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/urology_repository.dart';
import '../domain/urology_model.dart';

final urologyRepositoryProvider =
    Provider<UrologyRepository>((_) => UrologyRepository());

final voidingLogsProvider = FutureProvider<List<VoidingLogModel>>((ref) {
  return ref.read(urologyRepositoryProvider).getVoidingLogs();
});

final psaRecordsProvider = FutureProvider<List<PsaRecordModel>>((ref) {
  return ref.read(urologyRepositoryProvider).getPsaRecords();
});

final todayHydrationProvider = FutureProvider<int>((ref) {
  return ref.read(urologyRepositoryProvider).getTodayHydrationMl();
});

// ── 배뇨 기록 추가 ─────────────────────────────────────────────────────────────

sealed class VoidingAddState { const VoidingAddState(); }
final class VoidingAddIdle extends VoidingAddState { const VoidingAddIdle(); }
final class VoidingAddLoading extends VoidingAddState { const VoidingAddLoading(); }
final class VoidingAddSuccess extends VoidingAddState {
  const VoidingAddSuccess(this.log);
  final VoidingLogModel log;
}
final class VoidingAddError extends VoidingAddState {
  const VoidingAddError(this.message);
  final String message;
}

class VoidingAddNotifier extends Notifier<VoidingAddState> {
  @override
  VoidingAddState build() => const VoidingAddIdle();

  UrologyRepository get _repo => ref.read(urologyRepositoryProvider);

  Future<void> add(AddVoidingLogDto dto) async {
    state = const VoidingAddLoading();
    try {
      final log = await _repo.addVoidingLog(dto);
      ref.invalidate(voidingLogsProvider);
      state = VoidingAddSuccess(log);
    } on Exception catch (e) {
      state = VoidingAddError(e.toString());
    }
  }

  void reset() => state = const VoidingAddIdle();
}

final voidingAddProvider =
    NotifierProvider<VoidingAddNotifier, VoidingAddState>(
  VoidingAddNotifier.new,
);

// ── 수분 섭취 기록 추가 ───────────────────────────────────────────────────────

sealed class HydrationAddState { const HydrationAddState(); }
final class HydrationAddIdle extends HydrationAddState { const HydrationAddIdle(); }
final class HydrationAddLoading extends HydrationAddState { const HydrationAddLoading(); }
final class HydrationAddSuccess extends HydrationAddState { const HydrationAddSuccess(); }
final class HydrationAddError extends HydrationAddState {
  const HydrationAddError(this.message);
  final String message;
}

class HydrationAddNotifier extends Notifier<HydrationAddState> {
  @override
  HydrationAddState build() => const HydrationAddIdle();

  UrologyRepository get _repo => ref.read(urologyRepositoryProvider);

  Future<void> add(AddHydrationLogDto dto) async {
    state = const HydrationAddLoading();
    try {
      await _repo.addHydrationLog(dto);
      ref.invalidate(todayHydrationProvider);
      state = const HydrationAddSuccess();
    } on Exception catch (e) {
      state = HydrationAddError(e.toString());
    }
  }

  void reset() => state = const HydrationAddIdle();
}

final hydrationAddProvider =
    NotifierProvider<HydrationAddNotifier, HydrationAddState>(
  HydrationAddNotifier.new,
);
