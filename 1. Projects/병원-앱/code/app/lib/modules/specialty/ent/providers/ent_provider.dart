import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ent_repository.dart';
import '../domain/ent_model.dart';

final entRepositoryProvider = Provider<EntRepository>((_) => EntRepository());

final symptomLogsProvider = FutureProvider<List<SymptomLogModel>>((ref) {
  return ref.read(entRepositoryProvider).getSymptomLogs();
});

final allergiesProvider = FutureProvider<List<AllergyModel>>((ref) {
  return ref.read(entRepositoryProvider).getAllergies();
});

final seasonAlertsProvider = FutureProvider<List<SeasonAlertModel>>((ref) {
  return ref.read(entRepositoryProvider).getSeasonAlerts();
});

// ── 증상 일지 추가 Notifier ───────────────────────────────────────────────────

sealed class SymptomAddState { const SymptomAddState(); }
final class SymptomAddIdle extends SymptomAddState { const SymptomAddIdle(); }
final class SymptomAddLoading extends SymptomAddState { const SymptomAddLoading(); }
final class SymptomAddSuccess extends SymptomAddState {
  const SymptomAddSuccess(this.log);
  final SymptomLogModel log;
}
final class SymptomAddError extends SymptomAddState {
  const SymptomAddError(this.message);
  final String message;
}

class SymptomAddNotifier extends Notifier<SymptomAddState> {
  @override
  SymptomAddState build() => const SymptomAddIdle();

  EntRepository get _repo => ref.read(entRepositoryProvider);

  Future<void> add(AddSymptomLogDto dto) async {
    state = const SymptomAddLoading();
    try {
      final log = await _repo.addSymptomLog(dto);
      ref.invalidate(symptomLogsProvider);
      state = SymptomAddSuccess(log);
    } on Exception catch (e) {
      state = SymptomAddError(e.toString());
    }
  }

  void reset() => state = const SymptomAddIdle();
}

final symptomAddProvider =
    NotifierProvider<SymptomAddNotifier, SymptomAddState>(
  SymptomAddNotifier.new,
);
