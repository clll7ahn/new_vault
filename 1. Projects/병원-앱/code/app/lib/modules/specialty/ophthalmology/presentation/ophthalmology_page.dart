import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/ophthalmology_model.dart';
import '../providers/ophthalmology_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// OphthalmologyPage
// ──────────────────────────────────────────────────────────────────────────────

class OphthalmologyPage extends ConsumerWidget {
  const OphthalmologyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('안과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새로고침',
            onPressed: () {
              ref.invalidate(visionLogsProvider);
              ref.invalidate(prescriptionsProvider);
              ref.invalidate(eyeDropsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(visionLogsProvider);
          ref.invalidate(prescriptionsProvider);
          ref.invalidate(eyeDropsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _VisionSection(),
            SizedBox(height: 20),
            _PrescriptionSection(),
            SizedBox(height: 20),
            _EyeDropSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 시력 카드 + 추이 바
// ──────────────────────────────────────────────────────────────────────────────

class _VisionSection extends ConsumerWidget {
  const _VisionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(visionLogsProvider);
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
                Icon(Icons.visibility_outlined, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('시력 측정', style: theme.textTheme.titleSmall),
              ],
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
                message: '시력 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(visionLogsProvider),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return _EmptyHint(message: '측정 기록이 없습니다.');
                }
                final sorted = [...logs]
                  ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
                final latest = sorted.first;
                return Column(
                  children: [
                    // 좌/우안 시력 카드
                    Row(
                      children: [
                        Expanded(
                          child: _EyeCard(
                            label: '우안 (R)',
                            vision: latest.rightEyeVision,
                            corrected: latest.rightEyeWithCorrection,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EyeCard(
                            label: '좌안 (L)',
                            vision: latest.leftEyeVision,
                            corrected: latest.leftEyeWithCorrection,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 시력 추이 바 (최근 5개)
                    if (sorted.length > 1) ...[
                      Text(
                        '시력 추이 (우안)',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      _VisionTrendBar(
                        logs: sorted.take(5).toList().reversed.toList(),
                        useRight: true,
                        color: const Color(0xFF3B82F6),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '측정일: ${DateFormat('yyyy.MM.dd').format(latest.measuredAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
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

class _EyeCard extends StatelessWidget {
  const _EyeCard({
    required this.label,
    required this.vision,
    this.corrected,
    required this.color,
  });

  final String label;
  final double vision;
  final double? corrected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            vision.toStringAsFixed(2),
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          if (corrected != null) ...[
            const SizedBox(height: 2),
            Text(
              '교정: ${corrected!.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _VisionTrendBar extends StatelessWidget {
  const _VisionTrendBar({
    required this.logs,
    required this.useRight,
    required this.color,
  });

  final List<VisionLogModel> logs;
  final bool useRight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: logs.map((log) {
          final value = useRight ? log.rightEyeVision : log.leftEyeVision;
          final ratio = (value / 2.0).clamp(0.0, 1.0); // max 2.0 시력
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tooltip(
                message:
                    '${DateFormat('M/d').format(log.measuredAt)}: $value',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      flex: (ratio * 10).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: ((1 - ratio) * 10).round().clamp(0, 10),
                      child: Container(color: Colors.transparent),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 처방 카드
// ──────────────────────────────────────────────────────────────────────────────

class _PrescriptionSection extends ConsumerWidget {
  const _PrescriptionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prescriptionsProvider);
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
                Icon(Icons.receipt_long_outlined, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('안경/렌즈 처방', style: theme.textTheme.titleSmall),
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
                message: '처방 정보를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(prescriptionsProvider),
              ),
              data: (prescriptions) {
                if (prescriptions.isEmpty) {
                  return _EmptyHint(message: '처방 기록이 없습니다.');
                }
                final sorted = [...prescriptions]
                  ..sort(
                      (a, b) => b.prescribedAt.compareTo(a.prescribedAt));
                return Column(
                  children: sorted.take(3).map(_PrescriptionCard.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard(this.prescription);
  final PrescriptionModel prescription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isExpired = prescription.expiresAt != null &&
        prescription.expiresAt!.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      prescription.type == PrescriptionType.glasses
                          ? Icons.visibility
                          : Icons.lens_outlined,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(prescription.type.label,
                        style: theme.textTheme.titleSmall),
                  ],
                ),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '만료',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow('도수', prescription.diopterLabel),
            if (prescription.rightCylinderDiopter != null)
              _InfoRow(
                '난시',
                '우: ${prescription.rightCylinderDiopter!.toStringAsFixed(2)} / '
                    '좌: ${prescription.leftCylinderDiopter?.toStringAsFixed(2) ?? '-'}',
              ),
            _InfoRow(
              '처방일',
              DateFormat('yyyy.MM.dd').format(prescription.prescribedAt),
            ),
            if (prescription.expiresAt != null)
              _InfoRow(
                '유효기간',
                DateFormat('yyyy.MM.dd').format(prescription.expiresAt!),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 안약 투약 리마인더 리스트
// ──────────────────────────────────────────────────────────────────────────────

class _EyeDropSection extends ConsumerWidget {
  const _EyeDropSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eyeDropsProvider);
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
                Icon(Icons.water_drop_outlined, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('안약 투약 리마인더', style: theme.textTheme.titleSmall),
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
                message: '안약 정보를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(eyeDropsProvider),
              ),
              data: (drops) {
                final active = drops.where((d) => d.isActive).toList();
                if (active.isEmpty) {
                  return _EmptyHint(message: '등록된 안약이 없습니다.');
                }
                return Column(
                  children: active.map(_EyeDropTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EyeDropTile extends StatelessWidget {
  const _EyeDropTile(this.eyeDrop);
  final EyeDropModel eyeDrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isUrgent = eyeDrop.nextDoseLabel == '지금 투약 필요';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUrgent
              ? cs.errorContainer.withOpacity(0.4)
              : cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUrgent ? cs.error.withOpacity(0.5) : cs.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.water_drop,
                color: Color(0xFF0EA5E9),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyeDrop.name, style: theme.textTheme.titleSmall),
                  Text(
                    '하루 ${eyeDrop.dosagePerDay}회',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (eyeDrop.instructions != null)
                    Text(
                      eyeDrop.instructions!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isUrgent
                    ? cs.error.withOpacity(0.12)
                    : cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                eyeDrop.nextDoseLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isUrgent ? cs.error : cs.primary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 공통 위젯
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

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
