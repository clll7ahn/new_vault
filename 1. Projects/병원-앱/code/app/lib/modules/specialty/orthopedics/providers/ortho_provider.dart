import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ortho_repository.dart';
import '../domain/ortho_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final orthoRepositoryProvider =
    Provider<OrthoRepository>((ref) => OrthoRepository());

// ──────────────────────────────────────────────────────────────────────────────
// painLogsProvider — 기간별 통증 기록
// ──────────────────────────────────────────────────────────────────────────────

typedef PainLogsQuery = ({BodyPart? bodyPart, DateTime from, DateTime to});

final painLogsProvider =
    FutureProvider.family<List<PainLogModel>, PainLogsQuery>((ref, q) {
  return ref
      .read(orthoRepositoryProvider)
      .getPainLogs(bodyPart: q.bodyPart, from: q.from, to: q.to);
});

// ──────────────────────────────────────────────────────────────────────────────
// painTrendProvider — 통증 트렌드
// ──────────────────────────────────────────────────────────────────────────────

typedef PainTrendQuery = ({BodyPart? bodyPart, int days});

final painTrendProvider =
    FutureProvider.family<List<PainTrendPoint>, PainTrendQuery>((ref, q) {
  return ref
      .read(orthoRepositoryProvider)
      .getPainTrend(bodyPart: q.bodyPart, days: q.days);
});

// ──────────────────────────────────────────────────────────────────────────────
// rehabProgramsProvider — 재활 프로그램 목록
// ──────────────────────────────────────────────────────────────────────────────

final rehabProgramsProvider =
    FutureProvider<List<RehabProgramModel>>((ref) {
  return ref.read(orthoRepositoryProvider).getPrograms();
});

// ──────────────────────────────────────────────────────────────────────────────
// rehabAdherenceProvider — 수행률 (programId 기준)
// ──────────────────────────────────────────────────────────────────────────────

final rehabAdherenceProvider =
    FutureProvider.family<RehabAdherence, String>((ref, programId) {
  return ref
      .read(orthoRepositoryProvider)
      .getAdherence(programId: programId);
});

// ──────────────────────────────────────────────────────────────────────────────
// PainLogNotifier — 통증 일지 추가
// ──────────────────────────────────────────────────────────────────────────────

sealed class PainLogState {
  const PainLogState();
}

final class PainLogIdle extends PainLogState {
  const PainLogIdle();
}

final class PainLogLoading extends PainLogState {
  const PainLogLoading();
}

final class PainLogSuccess extends PainLogState {
  const PainLogSuccess(this.log);
  final PainLogModel log;
}

final class PainLogError extends PainLogState {
  const PainLogError(this.message);
  final String message;
}

class PainLogNotifier extends Notifier<PainLogState> {
  @override
  PainLogState build() => const PainLogIdle();

  OrthoRepository get _repo => ref.read(orthoRepositoryProvider);

  Future<void> add({
    required BodyPart bodyPart,
    required int intensity,
    PainType? painType,
    String? notes,
    List<String>? triggers,
  }) async {
    state = const PainLogLoading();
    try {
      final log = await _repo.addPainLog(
        bodyPart: bodyPart,
        intensity: intensity,
        painType: painType,
        notes: notes,
        triggers: triggers,
      );
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 30));
      ref.invalidate(
          painLogsProvider((bodyPart: null, from: from, to: now)));
      ref.invalidate(painTrendProvider((bodyPart: null, days: 14)));
      state = PainLogSuccess(log);
    } on Exception catch (e) {
      state = PainLogError(_parseError(e));
    }
  }

  void reset() => state = const PainLogIdle();

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    return '통증 기록 저장 중 오류가 발생했습니다.';
  }
}

final painLogNotifierProvider =
    NotifierProvider<PainLogNotifier, PainLogState>(PainLogNotifier.new);

// ──────────────────────────────────────────────────────────────────────────────
// ExerciseChecklistNotifier — 오늘 운동 체크 상태 관리
// Set<exerciseId>: 오늘 완료된 운동 id
// ──────────────────────────────────────────────────────────────────────────────

class ExerciseChecklistNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  OrthoRepository get _repo => ref.read(orthoRepositoryProvider);

  Future<void> toggle({
    required String programId,
    required ExerciseModel exercise,
  }) async {
    final checked = state.contains(exercise.id);
    if (checked) {
      state = {...state}..remove(exercise.id);
    } else {
      state = {...state, exercise.id};
      try {
        await _repo.logExercise(
          programId: programId,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          completedSets: exercise.sets,
        );
        ref.invalidate(rehabAdherenceProvider(programId));
      } on Exception {
        // 서버 에러 시 체크 롤백
        state = {...state}..remove(exercise.id);
      }
    }
  }

  void reset() => state = {};
}

final exerciseChecklistProvider =
    NotifierProvider<ExerciseChecklistNotifier, Set<String>>(
        ExerciseChecklistNotifier.new);

// ──────────────────────────────────────────────────────────────────────────────
// selectedBodyPartProvider — 부위 선택 상태
// ──────────────────────────────────────────────────────────────────────────────

final selectedBodyPartProvider = StateProvider<BodyPart?>((ref) => null);
