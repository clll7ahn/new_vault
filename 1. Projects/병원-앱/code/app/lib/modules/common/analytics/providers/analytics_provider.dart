import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';
import '../domain/analytics_model.dart';

final analyticsRepositoryProvider =
    Provider<AnalyticsRepository>((_) => AnalyticsRepository());

final noShowRiskProvider =
    FutureProvider<List<NoShowRiskAppointmentModel>>((ref) {
  return ref.read(analyticsRepositoryProvider).getNoShowRiskAppointments();
});

final peakTimeSlotsProvider =
    FutureProvider<List<PeakTimeSlotModel>>((ref) {
  return ref.read(analyticsRepositoryProvider).getPeakTimeSlots();
});

final churnRiskSummaryProvider =
    FutureProvider<ChurnRiskSummaryModel>((ref) {
  return ref.read(analyticsRepositoryProvider).getChurnRiskSummary();
});

final revenueSummaryProvider =
    FutureProvider<RevenueSummaryModel>((ref) {
  return ref.read(analyticsRepositoryProvider).getRevenueSummary();
});
