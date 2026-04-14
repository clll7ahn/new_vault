import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/dental_model.dart';
import '../providers/dental_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// FDI 치아 번호 레이아웃
// 상악: 18 17 16 15 14 13 12 11 | 21 22 23 24 25 26 27 28
// 하악: 48 47 46 45 44 43 42 41 | 31 32 33 34 35 36 37 38
// ──────────────────────────────────────────────────────────────────────────────

const _upperRight = [18, 17, 16, 15, 14, 13, 12, 11];
const _upperLeft = [21, 22, 23, 24, 25, 26, 27, 28];
const _lowerRight = [48, 47, 46, 45, 44, 43, 42, 41];
const _lowerLeft = [31, 32, 33, 34, 35, 36, 37, 38];

// ──────────────────────────────────────────────────────────────────────────────
// DentalPage
// ──────────────────────────────────────────────────────────────────────────────

class DentalPage extends ConsumerWidget {
  const DentalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('치과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새로고침',
            onPressed: () {
              ref.invalidate(toothChartProvider);
              ref.invalidate(dentalTreatmentsProvider);
              ref.invalidate(nextCheckupProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(toothChartProvider);
          ref.invalidate(dentalTreatmentsProvider);
          ref.invalidate(nextCheckupProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _NextCheckupCard(),
            SizedBox(height: 20),
            _ToothChartSection(),
            SizedBox(height: 20),
            _TreatmentTimelineSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// D-day 검진 카드
// ──────────────────────────────────────────────────────────────────────────────

class _NextCheckupCard extends ConsumerWidget {
  const _NextCheckupCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nextCheckupProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (checkup) {
        if (checkup == null) return const SizedBox.shrink();
        final days = checkup.daysUntil;
        final isPast = days < 0;
        final color = isPast ? cs.error : const Color(0xFF0EA5E9);

        return Card(
          color: color.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '다음 정기 검진',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('yyyy년 M월 d일')
                            .format(checkup.scheduledDate),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPast
                        ? 'D+${-days}'
                        : days == 0
                            ? 'D-Day'
                            : 'D-$days',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 치아 차트 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _ToothChartSection extends ConsumerWidget {
  const _ToothChartSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(toothChartProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety_outlined,
                    color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('치아 차트', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 4),
            // 범례
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ToothStatus.values.map((s) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _toothColor(s),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(s.label, style: theme.textTheme.labelSmall),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            async.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _ErrorRetry(
                message: '치아 차트를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(toothChartProvider),
              ),
              data: (chart) => _ToothGrid(chart: chart),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToothGrid extends StatelessWidget {
  const _ToothGrid({required this.chart});
  final ToothChartModel chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        // 상악
        Row(
          children: [
            Text('상악',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(width: 8),
            Expanded(child: _ToothRow(numbers: _upperRight, chart: chart)),
            Container(width: 1, height: 32, color: cs.outlineVariant),
            Expanded(child: _ToothRow(numbers: _upperLeft, chart: chart)),
          ],
        ),
        const SizedBox(height: 4),
        Divider(color: cs.outlineVariant),
        const SizedBox(height: 4),
        // 하악
        Row(
          children: [
            Text('하악',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(width: 8),
            Expanded(child: _ToothRow(numbers: _lowerRight, chart: chart)),
            Container(width: 1, height: 32, color: cs.outlineVariant),
            Expanded(child: _ToothRow(numbers: _lowerLeft, chart: chart)),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '갱신: ${DateFormat('yyyy.MM.dd').format(chart.updatedAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ToothRow extends StatelessWidget {
  const _ToothRow({required this.numbers, required this.chart});
  final List<int> numbers;
  final ToothChartModel chart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: numbers.map((n) {
        final info = chart.getByNumber(n);
        final status = info?.status ?? ToothStatus.healthy;
        return Expanded(
          child: Tooltip(
            message: '#$n ${status.label}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                children: [
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: _toothColor(status),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _toothColor(status).withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${n % 10}',
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

Color _toothColor(ToothStatus status) {
  switch (status) {
    case ToothStatus.healthy:
      return const Color(0xFFE2E8F0);
    case ToothStatus.treated:
      return const Color(0xFF93C5FD);
    case ToothStatus.missing:
      return const Color(0xFF94A3B8);
    case ToothStatus.decayed:
      return const Color(0xFFFCA5A5);
    case ToothStatus.crown:
      return const Color(0xFFFBD34D);
    case ToothStatus.implant:
      return const Color(0xFF86EFAC);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 치료 계획 타임라인
// ──────────────────────────────────────────────────────────────────────────────

class _TreatmentTimelineSection extends ConsumerWidget {
  const _TreatmentTimelineSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dentalTreatmentsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_outlined, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('치료 계획', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            async.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _ErrorRetry(
                message: '치료 계획을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(dentalTreatmentsProvider),
              ),
              data: (treatments) {
                if (treatments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '예정된 치료 계획이 없습니다.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant),
                    ),
                  );
                }
                final sorted = [...treatments]
                  ..sort((a, b) =>
                      a.scheduledDate.compareTo(b.scheduledDate));
                return Column(
                  children: sorted
                      .asMap()
                      .entries
                      .map((entry) => _TreatmentTimelineTile(
                            treatment: entry.value,
                            isLast: entry.key == sorted.length - 1,
                          ))
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

class _TreatmentTimelineTile extends StatelessWidget {
  const _TreatmentTimelineTile({
    required this.treatment,
    required this.isLast,
  });

  final DentalTreatmentModel treatment;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color statusColor;
    switch (treatment.status) {
      case DentalTreatmentStatus.completed:
        statusColor = const Color(0xFF16A34A);
        break;
      case DentalTreatmentStatus.inProgress:
        statusColor = const Color(0xFFF97316);
        break;
      case DentalTreatmentStatus.cancelled:
        statusColor = cs.outline;
        break;
      case DentalTreatmentStatus.planned:
        statusColor = cs.primary;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 선
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: cs.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          treatment.treatmentName,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          treatment.status.label,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('yyyy.MM.dd').format(treatment.scheduledDate),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (treatment.toothNumbers != null &&
                      treatment.toothNumbers!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '치아: ${treatment.toothNumbers!.join(', ')}번',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  if (treatment.estimatedCost != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '예상 비용: ${NumberFormat('#,###').format(treatment.estimatedCost)}원',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
