import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/im_model.dart';
import '../providers/im_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// ImDashboardPage — 내과 만성질환 대시보드
// ──────────────────────────────────────────────────────────────────────────────

class ImDashboardPage extends ConsumerStatefulWidget {
  const ImDashboardPage({super.key});

  @override
  ConsumerState<ImDashboardPage> createState() => _ImDashboardPageState();
}

class _ImDashboardPageState extends ConsumerState<ImDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    for (final t in VitalsType.values) {
      ref.invalidate(vitalsProvider((type: t, from: from, to: now)));
      ref.invalidate(vitalsTrendProvider((type: t, days: 7)));
    }
    ref.invalidate(medicationsProvider);
    ref.invalidate(todayLogsProvider);
    ref.invalidate(adherenceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내과 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새로고침',
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.favorite_outline), text: '만성질환 관리'),
            Tab(icon: Icon(Icons.medication_outlined), text: '복약 관리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _VitalsTab(),
          _MedicationTab(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 탭 1: 만성질환 관리 (혈압 / 혈당 / 체중)
// ──────────────────────────────────────────────────────────────────────────────

class _VitalsTab extends ConsumerWidget {
  const _VitalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 30));
        for (final t in VitalsType.values) {
          ref.invalidate(vitalsProvider((type: t, from: from, to: now)));
          ref.invalidate(vitalsTrendProvider((type: t, days: 7)));
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _VitalsCard(type: VitalsType.bloodPressure),
          SizedBox(height: 12),
          _VitalsCard(type: VitalsType.bloodGlucose),
          SizedBox(height: 12),
          _VitalsCard(type: VitalsType.weight),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 활력 징후 카드 (최근값 + 미니 트렌드 차트)
// ──────────────────────────────────────────────────────────────────────────────

class _VitalsCard extends ConsumerWidget {
  const _VitalsCard({required this.type});

  final VitalsType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 7));
    final vitalsAsync =
        ref.watch(vitalsProvider((type: type, from: from, to: now)));
    final trendAsync =
        ref.watch(vitalsTrendProvider((type: type, days: 7)));

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final config = _vitalsConfig(type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(config.icon, color: config.color, size: 22),
                ),
                const SizedBox(width: 12),
                Text(type.label, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            // ── 최근 수치 ─────────────────────────────────────────────────
            vitalsAsync.when(
              loading: () => const _MiniLoader(),
              error: (e, _) => _InlineError(
                onRetry: () => ref.invalidate(
                  vitalsProvider((type: type, from: from, to: now)),
                ),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return Text(
                    '기록 없음',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.outline),
                  );
                }
                final sorted = [...records]
                  ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
                final latest = sorted.first;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      latest.displayValue,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: config.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        type.unit,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _relativeTime(latest.measuredAt),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.outline),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // ── 미니 트렌드 차트 ──────────────────────────────────────────
            Text(
              '최근 7일 트렌드',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: trendAsync.when(
                loading: () => const _MiniLoader(),
                error: (_, __) => Center(
                  child: Text(
                    '데이터 없음',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                ),
                data: (points) => _MiniBarChart(
                  points: points,
                  color: config.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return DateFormat('M/d').format(dt);
  }

  _VitalsConfig _vitalsConfig(VitalsType type) {
    switch (type) {
      case VitalsType.bloodPressure:
        return _VitalsConfig(
          icon: Icons.favorite_outline,
          color: const Color(0xFFDC2626),
        );
      case VitalsType.bloodGlucose:
        return _VitalsConfig(
          icon: Icons.water_drop_outlined,
          color: const Color(0xFFF97316),
        );
      case VitalsType.weight:
        return _VitalsConfig(
          icon: Icons.monitor_weight_outlined,
          color: const Color(0xFF3B82F6),
        );
    }
  }
}

class _VitalsConfig {
  const _VitalsConfig({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

// ──────────────────────────────────────────────────────────────────────────────
// 미니 바 차트 (Container 기반 근사)
// ──────────────────────────────────────────────────────────────────────────────

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.points, required this.color});

  final List<VitalsTrendPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('데이터 없음'));
    }

    final values = points.map((p) => p.value1).toList();
    final maxVal = values.reduce(math.max);
    final minVal = values.reduce(math.min);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.asMap().entries.map((entry) {
        final point = entry.value;
        final ratio = ((point.value1 - minVal) / range).clamp(0.05, 1.0);
        final isLast = entry.key == points.length - 1;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLast
                            ? color
                            : color.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('d').format(point.date),
                  style: TextStyle(
                    fontSize: 9,
                    color: isLast
                        ? color
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 탭 2: 복약 관리
// ──────────────────────────────────────────────────────────────────────────────

class _MedicationTab extends ConsumerWidget {
  const _MedicationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    final logsAsync = ref.watch(todayLogsProvider);
    final adherenceAsync = ref.watch(adherenceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(medicationsProvider);
        ref.invalidate(todayLogsProvider);
        ref.invalidate(adherenceProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 순응도 원형 게이지 ─────────────────────────────────────────
          adherenceAsync.when(
            loading: () => const _MiniLoader(),
            error: (e, _) => const SizedBox.shrink(),
            data: (adherence) => _AdherenceGauge(adherence: adherence),
          ),
          const SizedBox(height: 16),

          // ── 오늘 복약 체크리스트 ───────────────────────────────────────
          Text(
            '오늘 복약',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          logsAsync.when(
            loading: () => const _MiniLoader(),
            error: (e, _) => _InlineError(
              onRetry: () => ref.invalidate(todayLogsProvider),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return _EmptyState(
                  icon: Icons.check_circle_outline,
                  message: '오늘 복약 일정이 없습니다.',
                );
              }
              return Column(
                children: logs
                    .map((log) => _MedLogTile(log: log))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── 전체 처방 목록 ────────────────────────────────────────────
          Text(
            '처방 약 목록',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          medsAsync.when(
            loading: () => const _MiniLoader(),
            error: (e, _) => _InlineError(
              onRetry: () => ref.invalidate(medicationsProvider),
            ),
            data: (meds) {
              if (meds.isEmpty) {
                return _EmptyState(
                  icon: Icons.medication_outlined,
                  message: '처방된 약이 없습니다.',
                );
              }
              return Column(
                children:
                    meds.map((m) => _MedicationTile(med: m)).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 순응도 원형 게이지
// ──────────────────────────────────────────────────────────────────────────────

class _AdherenceGauge extends StatelessWidget {
  const _AdherenceGauge({required this.adherence});

  final AdherenceModel adherence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pct = adherence.percent;
    final color = pct >= 0.8
        ? const Color(0xFF16A34A)
        : pct >= 0.5
            ? const Color(0xFFF97316)
            : cs.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 원형 게이지
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _CircleGaugePainter(
                  percent: pct,
                  color: color,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    '${(pct * 100).round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '복약 순응도',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '최근 ${adherence.period} · ${adherence.taken}/${adherence.total}회',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pct >= 0.8
                        ? '훌륭한 복약 습관입니다!'
                        : pct >= 0.5
                            ? '복약 습관을 개선해 보세요.'
                            : '담당 의사와 상담이 필요합니다.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: color),
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

class _CircleGaugePainter extends CustomPainter {
  const _CircleGaugePainter({
    required this.percent,
    required this.color,
    required this.backgroundColor,
  });

  final double percent;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleGaugePainter old) =>
      old.percent != percent || old.color != color;
}

// ──────────────────────────────────────────────────────────────────────────────
// 복약 기록 타일 (taken / skipped 토글)
// ──────────────────────────────────────────────────────────────────────────────

class _MedLogTile extends ConsumerWidget {
  const _MedLogTile({required this.log});

  final MedLogModel log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final notifierState = ref.watch(medLogNotifierProvider);
    final isLoading = notifierState is MedLogLoading &&
        (notifierState).logId == log.id;

    final isTaken = log.status == MedLogStatus.taken;
    final isSkipped = log.status == MedLogStatus.skipped;

    Color statusColor;
    IconData statusIcon;
    if (isTaken) {
      statusColor = const Color(0xFF16A34A);
      statusIcon = Icons.check_circle;
    } else if (isSkipped) {
      statusColor = cs.error;
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = cs.outline;
      statusIcon = Icons.radio_button_unchecked;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 12,
        leading: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : GestureDetector(
                onTap: () =>
                    ref.read(medLogNotifierProvider.notifier).toggle(log),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
        title: Text(
          log.medicationName,
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          '${log.timing} · ${DateFormat('HH:mm').format(log.scheduledAt.toLocal())}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Chip(
          label: Text(log.status.label),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          labelStyle: theme.textTheme.labelSmall?.copyWith(color: statusColor),
          side: BorderSide(color: statusColor.withOpacity(0.4)),
          backgroundColor: statusColor.withOpacity(0.08),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 처방 약 타일
// ──────────────────────────────────────────────────────────────────────────────

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({required this.med});

  final MedicationModel med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 12,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.medication_outlined,
            color: Color(0xFF3B82F6),
          ),
        ),
        title: Text(
          '${med.name} ${med.dosage}',
          style: theme.textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              med.frequency,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (med.timings.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: med.timings
                    .map((t) => Chip(
                          label: Text(t),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          labelStyle: theme.textTheme.labelSmall,
                        ))
                    .toList(),
              ),
            ],
            if (med.instructions != null) ...[
              const SizedBox(height: 4),
              Text(
                med.instructions!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.outline),
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 공통 소형 위젯
// ──────────────────────────────────────────────────────────────────────────────

class _MiniLoader extends StatelessWidget {
  const _MiniLoader();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 8),
          const Text('데이터를 불러오지 못했습니다.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('다시 시도'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: cs.outline),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
