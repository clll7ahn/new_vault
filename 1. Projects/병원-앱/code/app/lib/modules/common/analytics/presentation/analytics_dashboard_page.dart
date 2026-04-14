import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/analytics_model.dart';
import '../providers/analytics_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// AnalyticsDashboardPage — AI 대시보드 (admin 전용)
// ──────────────────────────────────────────────────────────────────────────────

class AnalyticsDashboardPage extends ConsumerWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 운영 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새로고침',
            onPressed: () {
              ref.invalidate(noShowRiskProvider);
              ref.invalidate(peakTimeSlotsProvider);
              ref.invalidate(churnRiskSummaryProvider);
              ref.invalidate(revenueSummaryProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(noShowRiskProvider);
          ref.invalidate(peakTimeSlotsProvider);
          ref.invalidate(churnRiskSummaryProvider);
          ref.invalidate(revenueSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Admin 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      color: cs.onErrorContainer, size: 18),
                  const SizedBox(width: 6),
                  Text('관리자 전용 대시보드',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onErrorContainer,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _RevenueSummarySection(),
            const SizedBox(height: 20),
            const _ChurnRiskSection(),
            const SizedBox(height: 20),
            const _NoShowRiskSection(),
            const SizedBox(height: 20),
            const _PeakTimeHeatmapSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 매출 요약 카드
// ──────────────────────────────────────────────────────────────────────────────

class _RevenueSummarySection extends ConsumerWidget {
  const _RevenueSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(revenueSummaryProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = NumberFormat('#,###', 'ko');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.attach_money_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('매출 요약', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '매출 정보를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(revenueSummaryProvider),
              ),
              data: (revenue) {
                final todayVsYest = revenue.todayVsYesterday;
                final isPositive = todayVsYest >= 0;
                final changeColor = isPositive
                    ? const Color(0xFF16A34A)
                    : cs.error;

                return Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: _RevenueCard(
                          label: '오늘 매출',
                          value: '${fmt.format(revenue.todayRevenue.toInt())}원',
                          sub: Row(children: [
                            Icon(
                              isPositive
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 16,
                              color: changeColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${isPositive ? '+' : ''}${(todayVsYest * 100).toStringAsFixed(1)}%',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: changeColor),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RevenueCard(
                          label: '이번 달 매출',
                          value:
                              '${fmt.format(revenue.monthRevenue.toInt())}원',
                          sub: Text(
                            '목표 ${(revenue.monthAchievementRatio * 100).toStringAsFixed(0)}% 달성',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('월 목표 달성률',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                            Text(
                              '${fmt.format(revenue.monthRevenue.toInt())} / '
                              '${fmt.format(revenue.targetRevenue.toInt())}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: revenue.monthAchievementRatio,
                            minHeight: 8,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                cs.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.label, required this.value, this.sub});
  final String label;
  final String value;
  final Widget? sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (sub != null) ...[const SizedBox(height: 2), sub!],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 이탈 위험 환자수
// ──────────────────────────────────────────────────────────────────────────────

class _ChurnRiskSection extends ConsumerWidget {
  const _ChurnRiskSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(churnRiskSummaryProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.person_off_outlined, color: cs.error),
              const SizedBox(width: 8),
              Text('이탈 위험 환자', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '이탈 위험 정보를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(churnRiskSummaryProvider),
              ),
              data: (summary) => Row(
                children: [
                  _ChurnBadge(
                    count: summary.highRiskCount,
                    label: '고위험',
                    color: cs.error,
                  ),
                  const SizedBox(width: 12),
                  _ChurnBadge(
                    count: summary.mediumRiskCount,
                    label: '중위험',
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 12),
                  _ChurnBadge(
                    count: summary.totalAtRisk,
                    label: '전체 위험',
                    color: cs.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChurnBadge extends StatelessWidget {
  const _ChurnBadge({
    required this.count,
    required this.label,
    required this.color,
  });
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 노쇼 위험 예약 리스트
// ──────────────────────────────────────────────────────────────────────────────

class _NoShowRiskSection extends ConsumerWidget {
  const _NoShowRiskSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(noShowRiskProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.event_busy_outlined, color: cs.error),
              const SizedBox(width: 8),
              Text('오늘 노쇼 위험 예약', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '노쇼 위험 예약을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(noShowRiskProvider),
              ),
              data: (appointments) {
                if (appointments.isEmpty) {
                  return Text('노쇼 위험 예약이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                final sorted = [...appointments]
                  ..sort((a, b) =>
                      b.riskScore.compareTo(a.riskScore));
                return Column(
                  children:
                      sorted.map(_NoShowRiskTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoShowRiskTile extends StatelessWidget {
  const _NoShowRiskTile(this.appt);
  final NoShowRiskAppointmentModel appt;

  Color _riskColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (appt.riskLevel) {
      case NoShowRiskLevel.high:   return cs.error;
      case NoShowRiskLevel.medium: return const Color(0xFFF59E0B);
      case NoShowRiskLevel.low:    return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _riskColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // 위험 점수 게이지
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                '${(appt.riskScore * 100).toInt()}%',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt.patientName, style: theme.textTheme.bodyMedium),
                Text(
                  [
                    DateFormat('HH:mm')
                        .format(appt.appointmentTime.toLocal()),
                    if (appt.doctorName != null) appt.doctorName!,
                    if (appt.department != null) appt.department!,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appt.riskLevel.label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 피크타임 히트맵 (시간대별 색상 바)
// ──────────────────────────────────────────────────────────────────────────────

class _PeakTimeHeatmapSection extends ConsumerWidget {
  const _PeakTimeHeatmapSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(peakTimeSlotsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.bar_chart_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('피크타임 히트맵', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 4),
            Text('오늘 시간대별 예약 밀도',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '피크타임 데이터를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(peakTimeSlotsProvider),
              ),
              data: (slots) {
                if (slots.isEmpty) {
                  return Text('데이터가 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                // 운영 시간(08~20) 필터
                final opSlots = slots
                    .where((s) => s.hour >= 8 && s.hour <= 20)
                    .toList()
                  ..sort((a, b) => a.hour.compareTo(b.hour));

                return Column(
                  children: opSlots
                      .map((s) => _HeatmapBar(slot: s))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapBar extends StatelessWidget {
  const _HeatmapBar({required this.slot});
  final PeakTimeSlotModel slot;

  Color _heatColor(double ratio) {
    if (ratio < 0.3) return const Color(0xFF93C5FD); // 파랑 (한산)
    if (ratio < 0.6) return const Color(0xFF34D399); // 초록
    if (ratio < 0.8) return const Color(0xFFF59E0B); // 주황
    return const Color(0xFFEF4444);                  // 빨강 (혼잡)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ratio = slot.ratio;
    final color = _heatColor(ratio);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(slot.hourLabel,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.02, 1.0),
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '${slot.count}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 공통 오류 위젯
// ──────────────────────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 36),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('다시 시도'),
        ),
      ],
    );
  }
}
