import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plastic_surgery_repository.dart';
import '../domain/plastic_surgery_model.dart';

final plasticSurgeryRepositoryProvider =
    Provider<PlasticSurgeryRepository>((_) => PlasticSurgeryRepository());

final proceduresProvider =
    FutureProvider<List<ProcedureRecordModel>>((ref) {
  return ref.read(plasticSurgeryRepositoryProvider).getProcedures();
});

// 특정 procedure id 기준 회복 로그
final recoveryLogsProvider =
    FutureProvider.family<List<RecoveryLogModel>, String>((ref, procedureId) {
  return ref
      .read(plasticSurgeryRepositoryProvider)
      .getRecoveryLogs(procedureId: procedureId);
});

// ── 회복 기록 추가 Notifier ───────────────────────────────────────────────────

sealed class RecoveryAddState { const RecoveryAddState(); }
final class RecoveryAddIdle extends RecoveryAddState { const RecoveryAddIdle(); }
final class RecoveryAddLoading extends RecoveryAddState { const RecoveryAddLoading(); }
final class RecoveryAddSuccess extends RecoveryAddState {
  const RecoveryAddSuccess(this.log);
  final RecoveryLogModel log;
}
final class RecoveryAddError extends RecoveryAddState {
  const RecoveryAddError(this.message);
  final String message;
}

class RecoveryAddNotifier extends Notifier<RecoveryAddState> {
  @override
  RecoveryAddState build() => const RecoveryAddIdle();

  PlasticSurgeryRepository get _repo =>
      ref.read(plasticSurgeryRepositoryProvider);

  Future<void> add(AddRecoveryLogDto dto) async {
    state = const RecoveryAddLoading();
    try {
      final log = await _repo.addRecoveryLog(dto);
      ref.invalidate(recoveryLogsProvider);
      state = RecoveryAddSuccess(log);
    } on Exception catch (e) {
      state = RecoveryAddError(e.toString());
    }
  }

  void reset() => state = const RecoveryAddIdle();
}

final recoveryAddProvider =
    NotifierProvider<RecoveryAddNotifier, RecoveryAddState>(
  RecoveryAddNotifier.new,
);
