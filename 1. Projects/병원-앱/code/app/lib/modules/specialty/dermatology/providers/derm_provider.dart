import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/derm_repository.dart';
import '../domain/derm_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final dermRepositoryProvider =
    Provider<DermRepository>((ref) => DermRepository());

// ──────────────────────────────────────────────────────────────────────────────
// photoTimelineProvider — 날짜순 타임라인
// ──────────────────────────────────────────────────────────────────────────────

final photoTimelineProvider =
    FutureProvider.family<List<SkinPhotoModel>, SkinRegion?>((ref, region) {
  return ref.read(dermRepositoryProvider).getTimeline(region: region);
});

// ──────────────────────────────────────────────────────────────────────────────
// treatmentsProvider — 시술 이력 목록
// ──────────────────────────────────────────────────────────────────────────────

final treatmentsProvider =
    FutureProvider<List<TreatmentModel>>((ref) {
  return ref.read(dermRepositoryProvider).getTreatments();
});

// ──────────────────────────────────────────────────────────────────────────────
// beforeAfterProvider — Before/After 쌍
// ──────────────────────────────────────────────────────────────────────────────

final beforeAfterProvider =
    FutureProvider<List<BeforeAfterPair>>((ref) {
  return ref.read(dermRepositoryProvider).getBeforeAfter();
});

// ──────────────────────────────────────────────────────────────────────────────
// latestAnalysisProvider — 최신 AI 분석 결과 (타임라인 첫 번째)
// ──────────────────────────────────────────────────────────────────────────────

final latestAnalysisProvider =
    FutureProvider<SkinAnalysisResult?>((ref) async {
  final photos = await ref.read(dermRepositoryProvider).getTimeline();
  if (photos.isEmpty) return null;
  final sorted = [...photos]
    ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  return sorted.first.analysis;
});

// ──────────────────────────────────────────────────────────────────────────────
// selectedRegionProvider — 부위 필터 상태
// ──────────────────────────────────────────────────────────────────────────────

final selectedRegionProvider =
    StateProvider<SkinRegion?>((ref) => null);

// ──────────────────────────────────────────────────────────────────────────────
// BeforeAfterSliderNotifier — 슬라이더 드래그 위치 (0.0 ~ 1.0)
// ──────────────────────────────────────────────────────────────────────────────

final beforeAfterSliderProvider = StateProvider<double>((ref) => 0.5);
