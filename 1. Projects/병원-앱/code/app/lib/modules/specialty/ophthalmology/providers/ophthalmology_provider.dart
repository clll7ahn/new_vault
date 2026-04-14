import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ophthalmology_repository.dart';
import '../domain/ophthalmology_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final ophthalmologyRepositoryProvider = Provider<OphthalmologyRepository>(
  (_) => OphthalmologyRepository(),
);

// ── 시력 기록 ─────────────────────────────────────────────────────────────────

final visionLogsProvider = FutureProvider<List<VisionLogModel>>((ref) {
  return ref.read(ophthalmologyRepositoryProvider).getVisionLogs();
});

// ── 처방 정보 ─────────────────────────────────────────────────────────────────

final prescriptionsProvider = FutureProvider<List<PrescriptionModel>>((ref) {
  return ref.read(ophthalmologyRepositoryProvider).getPrescriptions();
});

// ── 안약 정보 ─────────────────────────────────────────────────────────────────

final eyeDropsProvider = FutureProvider<List<EyeDropModel>>((ref) {
  return ref.read(ophthalmologyRepositoryProvider).getEyeDrops();
});
