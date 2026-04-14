import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/billing_model.dart';
import '../providers/billing_provider.dart';

/// 수납/결제 내역 화면
///
/// - 미납 / 결제완료 탭
/// - 각 청구 카드: 금액 큰 글씨, 상태 뱃지, 결제 버튼
class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (label: '미납', status: BillingStatus.pending),
    (label: '결제완료', status: BillingStatus.paid),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 결제 상태 변경 감지 → 스낵바 표시
    ref.listen<BillingPayState>(billingPayProvider, (prev, next) {
      if (next is BillingPaySuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '결제 완료! 영수증 번호: ${next.billing.receiptNumber ?? '-'}',
            ),
            backgroundColor: cs.primary,
          ),
        );
        ref.read(billingPayProvider.notifier).reset();
      } else if (next is BillingPayError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: cs.error,
          ),
        );
        ref.read(billingPayProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('수납/결제'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onPrimary.withOpacity(0.6),
          indicatorColor: cs.onPrimary,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 미납 탭: pending + overdue 모두 표시 (unpaid 엔드포인트 사용)
          _UnpaidTabView(),
          // 결제완료 탭
          _BillingTabView(status: BillingStatus.paid),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 미납 탭 (pending + overdue 통합)
// ──────────────────────────────────────────────────────────────────────────────

class _UnpaidTabView extends ConsumerWidget {
  const _UnpaidTabView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(unpaidBillingsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: '미납 내역을 불러오지 못했습니다.',
        onRetry: () => ref.invalidate(unpaidBillingsProvider),
      ),
      data: (billings) {
        if (billings.isEmpty) {
          return _EmptyBillings(message: '미납 청구가 없습니다.');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(unpaidBillingsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: billings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _BillingCard(
              billing: billings[i],
              showPayButton: true,
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 결제완료 탭
// ──────────────────────────────────────────────────────────────────────────────

class _BillingTabView extends ConsumerWidget {
  const _BillingTabView({required this.status});

  final BillingStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBillingsProvider(status));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: '결제 내역을 불러오지 못했습니다.',
        onRetry: () => ref.invalidate(myBillingsProvider(status)),
      ),
      data: (billings) {
        if (billings.isEmpty) {
          return _EmptyBillings(message: '결제 완료된 내역이 없습니다.');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myBillingsProvider(status)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: billings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _BillingCard(
              billing: billings[i],
              showPayButton: false,
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 청구 카드
// ──────────────────────────────────────────────────────────────────────────────

class _BillingCard extends ConsumerWidget {
  const _BillingCard({
    required this.billing,
    required this.showPayButton,
  });

  final BillingModel billing;
  final bool showPayButton;

  static final _currencyFmt =
      NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
  static final _dateFmt = DateFormat('yyyy년 M월 d일', 'ko');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPaying = ref.watch(billingPayProvider) is BillingPayLoading;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더: 상태 뱃지 ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    billing.description,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: billing.status),
              ],
            ),
            const SizedBox(height: 12),

            // ── 금액 (큰 글씨) ──────────────────────────────────────────────
            Text(
              _currencyFmt.format(billing.amount),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // ── 청구일 ───────────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '청구일: ${_dateFmt.format(billing.createdAt.toLocal())}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),

            // ── 결제일 / 영수증 (결제 완료 시) ─────────────────────────────
            if (billing.paidAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '결제일: ${_dateFmt.format(billing.paidAt!.toLocal())}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              if (billing.receiptNumber != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.receipt_outlined,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '영수증: ${billing.receiptNumber}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],

            // ── 결제 버튼 (미납 탭만) ───────────────────────────────────────
            if (showPayButton) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isPaying
                      ? null
                      : () => _showPaymentMethodDialog(context, ref),
                  icon: isPaying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payment_outlined, size: 18),
                  label: Text(isPaying ? '처리 중...' : '결제하기'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodDialog(BuildContext context, WidgetRef ref) {
    showDialog<PaymentMethod>(
      context: context,
      builder: (_) => _PaymentMethodDialog(),
    ).then((method) {
      if (method != null) {
        ref.read(billingPayProvider.notifier).pay(
              billingId: billing.id,
              paymentMethod: method,
            );
      }
    });
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 결제 수단 선택 다이얼로그
// ──────────────────────────────────────────────────────────────────────────────

class _PaymentMethodDialog extends StatefulWidget {
  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  PaymentMethod _selected = PaymentMethod.card;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('결제 수단 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: PaymentMethod.values.map((method) {
          return RadioListTile<PaymentMethod>(
            title: Text(method.label),
            value: method,
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(minimumSize: const Size(80, 48)),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 48)),
          child: const Text('결제'),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 상태 뱃지
// ──────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BillingStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    switch (status) {
      case BillingStatus.pending:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
      case BillingStatus.paid:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
      case BillingStatus.refunded:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
      case BillingStatus.overdue:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 빈 상태
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyBillings extends StatelessWidget {
  const _EmptyBillings({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 오류 재시도
// ──────────────────────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 52)),
          ),
        ],
      ),
    );
  }
}
