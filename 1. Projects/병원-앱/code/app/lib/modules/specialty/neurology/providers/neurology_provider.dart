import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/neurology_repository.dart';
import '../domain/neurology_model.dart';

final neurologyRepositoryProvider =
    Provider<NeurologyRepository>((_) => NeurologyRepository());

final headacheLogsProvider = FutureProvider<List<HeadacheLogModel>>((ref) {
  return ref.read(neurologyRepositoryProvider).getHeadacheLogs();
});

final cognitivScoresProvider = FutureProvider<List<CognitivScoreModel>>((ref) {
  return ref.read(neurologyRepositoryProvider).getCognitivScores();
});

// ── 두통 기록 추가 Notifier ───────────────────────────────────────────────────

sealed class HeadacheAddState { const HeadacheAddState(); }
final class HeadacheAddIdle extends HeadacheAddState { const HeadacheAddIdle(); }
final class HeadacheAddLoading extends HeadacheAddState { const HeadacheAddLoading(); }
final class HeadacheAddSuccess extends HeadacheAddState {
  const HeadacheAddSuccess(this.log);
  final HeadacheLogModel log;
}
final class HeadacheAddError extends HeadacheAddState {
  const HeadacheAddError(this.message);
  final String message;
}

class HeadacheAddNotifier extends Notifier<HeadacheAddState> {
  @override
  HeadacheAddState build() => const HeadacheAddIdle();

  NeurologyRepository get _repo => ref.read(neurologyRepositoryProvider);

  Future<void> add(AddHeadacheLogDto dto) async {
    state = const HeadacheAddLoading();
    try {
      final log = await _repo.addHeadacheLog(dto);
      ref.invalidate(headacheLogsProvider);
      state = HeadacheAddSuccess(log);
    } on Exception catch (e) {
      state = HeadacheAddError(e.toString());
    }
  }

  void reset() => state = const HeadacheAddIdle();
}

final headacheAddProvider =
    NotifierProvider<HeadacheAddNotifier, HeadacheAddState>(
  HeadacheAddNotifier.new,
);
