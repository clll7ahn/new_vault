import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/billing_repository.dart';
import '../domain/billing_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// 내 청구 목록 (상태 필터)
// ──────────────────────────────────────────────────────────────────────────────

final myBillingsProvider =
    FutureProvider.family<List<BillingModel>, BillingStatus?>(
        (ref, status) async {
  return ref.read(billingRepositoryProvider).getMyBillings(status: status);
});

// ──────────────────────────────────────────────────────────────────────────────
// 미납 청구 목록
// ──────────────────────────────────────────────────────────────────────────────

final unpaidBillingsProvider = FutureProvider<List<BillingModel>>((ref) {
  return ref.read(billingRepositoryProvider).getUnpaidBillings();
});

// ──────────────────────────────────────────────────────────────────────────────
// 결제 처리 Notifier
// ──────────────────────────────────────────────────────────────────────────────

sealed class BillingPayState {
  const BillingPayState();
}

final class BillingPayIdle extends BillingPayState {
  const BillingPayIdle();
}

final class BillingPayLoading extends BillingPayState {
  const BillingPayLoading();
}

final class BillingPaySuccess extends BillingPayState {
  const BillingPaySuccess(this.billing);
  final BillingModel billing;
}

final class BillingPayError extends BillingPayState {
  const BillingPayError(this.message);
  final String message;
}

class BillingPayNotifier extends Notifier<BillingPayState> {
  @override
  BillingPayState build() => const BillingPayIdle();

  BillingRepository get _repo => ref.read(billingRepositoryProvider);

  Future<void> pay({
    required String billingId,
    required PaymentMethod paymentMethod,
  }) async {
    state = const BillingPayLoading();
    try {
      final billing = await _repo.processPayment(
        id: billingId,
        paymentMethod: paymentMethod,
      );
      // 목록 캐시 무효화
      ref.invalidate(myBillingsProvider);
      ref.invalidate(unpaidBillingsProvider);
      state = BillingPaySuccess(billing);
    } on Exception catch (e) {
      state = BillingPayError(_parseError(e));
    }
  }

  void reset() => state = const BillingPayIdle();

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('400') || msg.contains('BadRequest')) {
      return '결제할 수 없는 상태입니다.';
    } else if (msg.contains('404')) {
      return '청구서를 찾을 수 없습니다.';
    } else if (msg.contains('SocketException') || msg.contains('network')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    return '결제 처리 중 오류가 발생했습니다.';
  }
}

final billingPayProvider =
    NotifierProvider<BillingPayNotifier, BillingPayState>(
        BillingPayNotifier.new);
