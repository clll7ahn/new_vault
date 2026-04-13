import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/appointment_repository.dart';
import '../domain/appointment_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// 예약 가능 슬롯 (날짜 선택마다 새로 fetch)
// ──────────────────────────────────────────────────────────────────────────────

typedef SlotQuery = ({String doctorId, DateTime date});

final slotsProvider =
    FutureProvider.family<List<SlotModel>, SlotQuery>((ref, query) {
  return ref.read(appointmentRepositoryProvider).getSlots(
        doctorId: query.doctorId,
        date: query.date,
      );
});

// ──────────────────────────────────────────────────────────────────────────────
// 내 예약 목록
// ──────────────────────────────────────────────────────────────────────────────

/// 상태별 필터 없이 전체 내 예약 조회
final myAppointmentsProvider =
    FutureProvider<List<AppointmentModel>>((ref) async {
  return ref.read(appointmentRepositoryProvider).getMyList();
});

/// 상태 필터별 내 예약 조회
final myAppointmentsByStatusProvider =
    FutureProvider.family<List<AppointmentModel>, AppointmentStatus?>(
        (ref, status) {
  return ref.read(appointmentRepositoryProvider).getMyList(status: status);
});

// ──────────────────────────────────────────────────────────────────────────────
// 예약 생성 Notifier
// ──────────────────────────────────────────────────────────────────────────────

sealed class AppointmentCreateState {
  const AppointmentCreateState();
}

final class AppointmentCreateIdle extends AppointmentCreateState {
  const AppointmentCreateIdle();
}

final class AppointmentCreateLoading extends AppointmentCreateState {
  const AppointmentCreateLoading();
}

final class AppointmentCreateSuccess extends AppointmentCreateState {
  const AppointmentCreateSuccess(this.appointment);
  final AppointmentModel appointment;
}

final class AppointmentCreateError extends AppointmentCreateState {
  const AppointmentCreateError(this.message);
  final String message;
}

class AppointmentCreateNotifier
    extends Notifier<AppointmentCreateState> {
  @override
  AppointmentCreateState build() => const AppointmentCreateIdle();

  AppointmentRepository get _repo =>
      ref.read(appointmentRepositoryProvider);

  Future<void> create(CreateAppointmentDto dto) async {
    state = const AppointmentCreateLoading();
    try {
      final appointment = await _repo.create(dto);
      // 내 예약 목록 캐시 무효화
      ref.invalidate(myAppointmentsProvider);
      state = AppointmentCreateSuccess(appointment);
    } on Exception catch (e) {
      state = AppointmentCreateError(_parseError(e));
    }
  }

  Future<void> cancel(String id) async {
    try {
      await _repo.cancel(id);
      ref.invalidate(myAppointmentsProvider);
    } on Exception catch (e) {
      state = AppointmentCreateError(_parseError(e));
    }
  }

  void reset() => state = const AppointmentCreateIdle();

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('409') || msg.contains('Conflict')) {
      return '이미 선택된 시간대입니다. 다른 시간을 선택해 주세요.';
    } else if (msg.contains('404')) {
      return '선택한 슬롯을 찾을 수 없습니다.';
    } else if (msg.contains('SocketException') || msg.contains('network')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    return '예약 처리 중 오류가 발생했습니다.';
  }
}

final appointmentCreateProvider = NotifierProvider<AppointmentCreateNotifier,
    AppointmentCreateState>(AppointmentCreateNotifier.new);

// ──────────────────────────────────────────────────────────────────────────────
// 다음 예약 (홈 화면용 — 가장 가까운 예정 예약)
// ──────────────────────────────────────────────────────────────────────────────

final nextAppointmentProvider = FutureProvider<AppointmentModel?>((ref) async {
  final list = await ref
      .read(appointmentRepositoryProvider)
      .getMyList(status: AppointmentStatus.scheduled);
  if (list.isEmpty) return null;
  list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  final upcoming = list.where((a) => a.scheduledAt.isAfter(DateTime.now()));
  return upcoming.isEmpty ? null : upcoming.first;
});
