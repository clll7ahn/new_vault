import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dental_repository.dart';
import '../domain/dental_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final dentalRepositoryProvider = Provider<DentalRepository>(
  (_) => DentalRepository(),
);

// ── 치아 차트 ─────────────────────────────────────────────────────────────────

final toothChartProvider = FutureProvider<ToothChartModel>((ref) {
  return ref.read(dentalRepositoryProvider).getToothChart();
});

// ── 치료 계획 ─────────────────────────────────────────────────────────────────

final dentalTreatmentsProvider =
    FutureProvider<List<DentalTreatmentModel>>((ref) {
  return ref.read(dentalRepositoryProvider).getTreatments();
});

// ── 다음 검진 ─────────────────────────────────────────────────────────────────

final nextCheckupProvider = FutureProvider<NextCheckupModel?>((ref) {
  return ref.read(dentalRepositoryProvider).getNextCheckup();
});
