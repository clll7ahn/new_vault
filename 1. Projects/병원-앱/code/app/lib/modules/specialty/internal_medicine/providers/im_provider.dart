import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/im_repository.dart';
import '../domain/im_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final imRepositoryProvider = Provider<ImRepository>((ref) => ImRepository());

// ──────────────────────────────────────────────────────────────────────────────
// vitalsProvider — 기간별 활력 징후
// ──────────────────────────────────────────────────────────────────────────────

typedef VitalsQuery = ({VitalsType type, DateTime from, DateTime to});

final vitalsProvider =
    FutureProvider.family<List<VitalsModel>, VitalsQuery>((ref, q) {
  return ref
      .read(imRepositoryProvider)
      .getVitals(type: q.type, from: q.from, to: q.to);
});

// ──────────────────────────────────────────────────────────────────────────────
// vitalsTrendProvider — 트렌드 데이터
// ──────────────────────────────────────────────────────────────────────────────

typedef VitalsTrendQuery = ({VitalsType type, int days});

final vitalsTrendProvider =
    FutureProvider.family<List<VitalsTrendPoint>, VitalsTrendQuery>((ref, q) {
  return ref
      .read(imRepositoryProvider)
      .getVitalsTrend(type: q.type, days: q.days);
});

// ──────────────────────────────────────────────────────────────────────────────
// medicationsProvider — 활성 처방 목록
// ──────────────────────────────────────────────────────────────────────────────

final medicationsProvider = FutureProvider<List<MedicationModel>>((ref) {
  return ref.read(imRepositoryProvider).getMedications();
});

// ──────────────────────────────────────────────────────────────────────────────
// todayLogsProvider — 오늘 복약 기록
// ──────────────────────────────────────────────────────────────────────────────

final todayLogsProvider = FutureProvider<List<MedLogModel>>((ref) {
  return ref.read(imRepositoryProvider).getTodayLogs();
});

// ──────────────────────────────────────────────────────────────────────────────
// adherenceProvider — 복약 순응도
// ──────────────────────────────────────────────────────────────────────────────

final adherenceProvider = FutureProvider<AdherenceModel>((ref) {
  return ref.read(imRepositoryProvider).getAdherence();
});

// ──────────────────────────────────────────────────────────────────────────────
// MedLogNotifier — 복약 상태 토글
// ──────────────────────────────────────────────────────────────────────────────

sealed class MedLogState {
  const MedLogState();
}

final class MedLogIdle extends MedLogState {
  const MedLogIdle();
}

final class MedLogLoading extends MedLogState {
  const MedLogLoading(this.logId);
  final String logId;
}

final class MedLogSuccess extends MedLogState {
  const MedLogSuccess(this.log);
  final MedLogModel log;
}

final class MedLogError extends MedLogState {
  const MedLogError(this.message);
  final String message;
}

class MedLogNotifier extends Notifier<MedLogState> {
  @override
  MedLogState build() => const MedLogIdle();

  ImRepository get _repo => ref.read(imRepositoryProvider);

  Future<void> toggle(MedLogModel log) async {
    final newStatus = log.status == MedLogStatus.taken
        ? MedLogStatus.skipped
        : MedLogStatus.taken;

    state = MedLogLoading(log.id);
    try {
      final updated = await _repo.logMedication(
        logId: log.id,
        status: newStatus,
      );
      ref.invalidate(todayLogsProvider);
      ref.invalidate(adherenceProvider);
      state = MedLogSuccess(updated);
    } on Exception catch (e) {
      state = MedLogError(_parseError(e));
    }
  }

  void reset() => state = const MedLogIdle();

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    return '복약 상태 업데이트 중 오류가 발생했습니다.';
  }
}

final medLogNotifierProvider =
    NotifierProvider<MedLogNotifier, MedLogState>(MedLogNotifier.new);
