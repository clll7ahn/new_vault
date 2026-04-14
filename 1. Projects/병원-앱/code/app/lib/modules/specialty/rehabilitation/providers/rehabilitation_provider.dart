import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rehabilitation_repository.dart';
import '../domain/rehabilitation_model.dart';

final rehabilitationRepositoryProvider =
    Provider<RehabilitationRepository>((_) => RehabilitationRepository());

final evalScoresProvider = FutureProvider<List<EvalScoreModel>>((ref) {
  return ref.read(rehabilitationRepositoryProvider).getEvalScores();
});

final rehabExercisesProvider =
    FutureProvider<List<RehabExerciseModel>>((ref) {
  return ref.read(rehabilitationRepositoryProvider).getExerciseList();
});

final sessionPainLogsProvider =
    FutureProvider<List<SessionPainLogModel>>((ref) {
  return ref.read(rehabilitationRepositoryProvider).getSessionPainLogs();
});

// ── 운동 완료 체크 (로컬 상태) ────────────────────────────────────────────────

class ExerciseCheckNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String exerciseId) {
    final current = Set<String>.from(state);
    if (current.contains(exerciseId)) {
      current.remove(exerciseId);
    } else {
      current.add(exerciseId);
    }
    state = current;
  }

  void resetAll() => state = {};
}

final exerciseCheckProvider =
    NotifierProvider<ExerciseCheckNotifier, Set<String>>(
  ExerciseCheckNotifier.new,
);

// ── 세션 통증 기록 추가 Notifier ──────────────────────────────────────────────

sealed class PainLogAddState { const PainLogAddState(); }
final class PainLogAddIdle extends PainLogAddState { const PainLogAddIdle(); }
final class PainLogAddLoading extends PainLogAddState { const PainLogAddLoading(); }
final class PainLogAddSuccess extends PainLogAddState {
  const PainLogAddSuccess(this.log);
  final SessionPainLogModel log;
}
final class PainLogAddError extends PainLogAddState {
  const PainLogAddError(this.message);
  final String message;
}

class PainLogAddNotifier extends Notifier<PainLogAddState> {
  @override
  PainLogAddState build() => const PainLogAddIdle();

  RehabilitationRepository get _repo =>
      ref.read(rehabilitationRepositoryProvider);

  Future<void> add(AddSessionPainLogDto dto) async {
    state = const PainLogAddLoading();
    try {
      final log = await _repo.addSessionPainLog(dto);
      ref.invalidate(sessionPainLogsProvider);
      state = PainLogAddSuccess(log);
    } on Exception catch (e) {
      state = PainLogAddError(e.toString());
    }
  }

  void reset() => state = const PainLogAddIdle();
}

final painLogAddProvider =
    NotifierProvider<PainLogAddNotifier, PainLogAddState>(
  PainLogAddNotifier.new,
);
