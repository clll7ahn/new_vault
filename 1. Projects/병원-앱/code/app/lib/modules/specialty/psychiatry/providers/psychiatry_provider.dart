import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/psychiatry_repository.dart';
import '../domain/psychiatry_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final psychiatryRepositoryProvider = Provider<PsychiatryRepository>(
  (_) => PsychiatryRepository(),
);

// ── 기분 기록 목록 ────────────────────────────────────────────────────────────

final moodLogsProvider = FutureProvider<List<MoodLogModel>>((ref) {
  return ref.read(psychiatryRepositoryProvider).getMoodLogs();
});

// ── 수면 기록 목록 ────────────────────────────────────────────────────────────

final sleepLogsProvider = FutureProvider<List<SleepLogModel>>((ref) {
  return ref.read(psychiatryRepositoryProvider).getSleepLogs();
});

// ── 위기 상담 리소스 ──────────────────────────────────────────────────────────

final crisisResourcesProvider = FutureProvider<List<CrisisResource>>((ref) {
  return ref.read(psychiatryRepositoryProvider).getCrisisResources();
});

// ── 기분 기록 추가 Notifier ───────────────────────────────────────────────────

sealed class MoodAddState {
  const MoodAddState();
}

final class MoodAddIdle extends MoodAddState {
  const MoodAddIdle();
}

final class MoodAddLoading extends MoodAddState {
  const MoodAddLoading();
}

final class MoodAddSuccess extends MoodAddState {
  const MoodAddSuccess(this.log);
  final MoodLogModel log;
}

final class MoodAddError extends MoodAddState {
  const MoodAddError(this.message);
  final String message;
}

class MoodAddNotifier extends Notifier<MoodAddState> {
  @override
  MoodAddState build() => const MoodAddIdle();

  PsychiatryRepository get _repo => ref.read(psychiatryRepositoryProvider);

  Future<void> add(AddMoodLogDto dto) async {
    state = const MoodAddLoading();
    try {
      final log = await _repo.addMoodLog(dto);
      ref.invalidate(moodLogsProvider);
      state = MoodAddSuccess(log);
    } on Exception catch (e) {
      state = MoodAddError(e.toString());
    }
  }

  void reset() => state = const MoodAddIdle();
}

final moodAddProvider = NotifierProvider<MoodAddNotifier, MoodAddState>(
  MoodAddNotifier.new,
);

// ── 수면 기록 추가 Notifier ───────────────────────────────────────────────────

sealed class SleepAddState {
  const SleepAddState();
}

final class SleepAddIdle extends SleepAddState {
  const SleepAddIdle();
}

final class SleepAddLoading extends SleepAddState {
  const SleepAddLoading();
}

final class SleepAddSuccess extends SleepAddState {
  const SleepAddSuccess(this.log);
  final SleepLogModel log;
}

final class SleepAddError extends SleepAddState {
  const SleepAddError(this.message);
  final String message;
}

class SleepAddNotifier extends Notifier<SleepAddState> {
  @override
  SleepAddState build() => const SleepAddIdle();

  PsychiatryRepository get _repo => ref.read(psychiatryRepositoryProvider);

  Future<void> add(AddSleepLogDto dto) async {
    state = const SleepAddLoading();
    try {
      final log = await _repo.addSleepLog(dto);
      ref.invalidate(sleepLogsProvider);
      state = SleepAddSuccess(log);
    } on Exception catch (e) {
      state = SleepAddError(e.toString());
    }
  }

  void reset() => state = const SleepAddIdle();
}

final sleepAddProvider = NotifierProvider<SleepAddNotifier, SleepAddState>(
  SleepAddNotifier.new,
);
