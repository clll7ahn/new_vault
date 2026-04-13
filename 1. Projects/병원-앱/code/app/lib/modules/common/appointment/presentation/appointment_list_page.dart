import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/appointment_model.dart';
import '../providers/appointment_provider.dart';

/// 내 예약 목록 화면
///
/// - 예정 / 완료 / 취소 탭 (TabBar)
/// - 각 탭마다 예약 카드 목록
/// - 예정 탭: 취소 버튼 포함
class AppointmentListPage extends ConsumerStatefulWidget {
  const AppointmentListPage({super.key});

  @override
  ConsumerState<AppointmentListPage> createState() =>
      _AppointmentListPageState();
}

class _AppointmentListPageState extends ConsumerState<AppointmentListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (label: '예정', status: AppointmentStatus.scheduled),
    (label: '완료', status: AppointmentStatus.completed),
    (label: '취소', status: AppointmentStatus.cancelled),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 예약'),
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
        children: _tabs
            .map((t) => _AppointmentTabView(status: t.status))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/booking'),
        icon: const Icon(Icons.add),
        label: const Text('예약하기'),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 탭별 예약 목록
// ──────────────────────────────────────────────────────────────────────────────

class _AppointmentTabView extends ConsumerWidget {
  const _AppointmentTabView({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAppointmentsByStatusProvider(status));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: '예약 목록을 불러오지 못했습니다.',
        onRetry: () =>
            ref.invalidate(myAppointmentsByStatusProvider(status)),
      ),
      data: (appointments) {
        if (appointments.isEmpty) {
          return _EmptyAppointments(status: status);
        }

        // 예정 탭: 날짜 오름차순, 나머지: 내림차순
        final sorted = [...appointments];
        if (status == AppointmentStatus.scheduled) {
          sorted.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        } else {
          sorted.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myAppointmentsByStatusProvider(status));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _AppointmentCard(
              appointment: sorted[i],
              showCancel: status == AppointmentStatus.scheduled,
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 예약 카드
// ──────────────────────────────────────────────────────────────────────────────

class _AppointmentCard extends ConsumerWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.showCancel,
  });

  final AppointmentModel appointment;
  final bool showCancel;

  static final _dateFmt = DateFormat('yyyy년 M월 d일 (E)', 'ko');
  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isCancelling = ref.watch(appointmentCreateProvider)
        is AppointmentCreateLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더: 진료과 배지 + 상태 칩 ────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment.departmentName ?? '진료과',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                _StatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 12),

            // ── 의사 이름 ────────────────────────────────────────────────
            Text(
              '${appointment.doctorName ?? '담당의'} 원장',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            // ── 날짜 / 시간 ──────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  _dateFmt.format(appointment.scheduledAt.toLocal()),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_outlined,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  _timeFmt.format(appointment.scheduledAt.toLocal()),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            // ── 증상 (있을 때) ────────────────────────────────────────────
            if (appointment.symptoms != null &&
                appointment.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                '증상: ${appointment.symptoms}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ── 취소 버튼 (예정 탭만) ─────────────────────────────────────
            if (showCancel) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isCancelling
                      ? null
                      : () => _confirmCancel(context, ref),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('예약 취소'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error),
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

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('예약 취소'),
        content: const Text('예약을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(minimumSize: const Size(80, 48)),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(appointmentCreateProvider.notifier)
                  .cancel(appointment.id);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 48),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 상태 칩
// ──────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    switch (status) {
      case AppointmentStatus.scheduled:
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
      case AppointmentStatus.completed:
        bg = cs.tertiaryContainer ?? cs.secondaryContainer;
        fg = cs.onTertiaryContainer ?? cs.onSecondaryContainer;
      case AppointmentStatus.cancelled:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
      case AppointmentStatus.noShow:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
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

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final message = switch (status) {
      AppointmentStatus.scheduled => '예정된 예약이 없습니다.',
      AppointmentStatus.completed => '완료된 예약이 없습니다.',
      AppointmentStatus.cancelled => '취소된 예약이 없습니다.',
      AppointmentStatus.noShow => '미방문 예약이 없습니다.',
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note_outlined, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (status == AppointmentStatus.scheduled) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/booking'),
              icon: const Icon(Icons.add),
              label: const Text('예약하기'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 52)),
            ),
          ],
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
