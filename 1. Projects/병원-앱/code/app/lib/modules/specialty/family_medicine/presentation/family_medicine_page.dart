import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/family_medicine_model.dart';
import '../providers/family_medicine_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// FamilyMedicinePage — 가정의학과
// ──────────────────────────────────────────────────────────────────────────────

class FamilyMedicinePage extends ConsumerWidget {
  const FamilyMedicinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가정의학과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(healthCheckResultsProvider);
              ref.invalidate(lifestyleLogsProvider);
              ref.invalidate(bmiRecordsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(healthCheckResultsProvider);
          ref.invalidate(lifestyleLogsProvider);
          ref.invalidate(bmiRecordsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _HealthCheckSection(),
            SizedBox(height: 20),
            _LifestyleTrackerSection(),
            SizedBox(height: 20),
            _BmiSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 건강검진 결과 카드
// ──────────────────────────────────────────────────────────────────────────────

class _HealthCheckSection extends ConsumerWidget {
  const _HealthCheckSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(healthCheckResultsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.assignment_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('건강검진 결과', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '결과를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(healthCheckResultsProvider),
              ),
              data: (results) {
                if (results.isEmpty) {
                  return Text('건강검진 결과가 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                final latest = results.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy년 M월 d일').format(latest.checkDate),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (latest.overallRisk != null) ...[
                      const SizedBox(height: 8),
                      _RiskBadge(latest.overallRisk!),
                    ],
                    const SizedBox(height: 12),
                    ...latest.items.map(_CheckItemTile.new),
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

class _RiskBadge extends StatelessWidget {
  const _RiskBadge(this.risk);
  final RiskLevel risk;

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (risk) {
      case RiskLevel.normal:  return const Color(0xFF16A34A);
      case RiskLevel.caution: return const Color(0xFFF59E0B);
      case RiskLevel.danger:  return cs.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '종합: ${risk.label}',
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CheckItemTile extends StatelessWidget {
  const _CheckItemTile(this.item);
  final CheckResultItem item;

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (item.riskLevel) {
      case RiskLevel.normal:  return const Color(0xFF16A34A);
      case RiskLevel.caution: return const Color(0xFFF59E0B);
      case RiskLevel.danger:  return cs.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(item.name, style: theme.textTheme.bodyMedium)),
          Text(
            '${item.value.toStringAsFixed(1)} ${item.unit}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.riskLevel.label,
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
// 생활습관 트래커 (금주/금연/운동/식단)
// ──────────────────────────────────────────────────────────────────────────────

class _LifestyleTrackerSection extends ConsumerWidget {
  const _LifestyleTrackerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lifestyleLogsProvider);
    final addState = ref.watch(lifestyleAddProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    ref.listen(lifestyleAddProvider, (_, next) {
      if (next is LifestyleAddSuccess) {
        ref.read(lifestyleAddProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('생활습관이 기록되었습니다.')),
        );
      }
    });

    // 오늘 달성 여부 집계
    final todayLogs = async.whenOrNull(data: (logs) {
      final today = DateTime.now();
      return logs.where((l) {
        final d = l.recordedAt.toLocal();
        return d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
      }).toList();
    }) ?? [];

    final achievedCategories = todayLogs
        .where((l) => l.achieved)
        .map((l) => l.category)
        .toSet();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.self_improvement_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('생활습관 트래커', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 4),
            Text('오늘의 생활습관 목표',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: LifestyleCategory.values.map((cat) {
                final achieved = achievedCategories.contains(cat);
                final isLoading = addState is LifestyleAddLoading;
                return _LifestyleChip(
                  category: cat,
                  achieved: achieved,
                  isLoading: isLoading,
                  onTap: isLoading
                      ? null
                      : () => ref
                          .read(lifestyleAddProvider.notifier)
                          .add(AddLifestyleLogDto(
                            category: cat,
                            achieved: !achieved,
                          )),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifestyleChip extends StatelessWidget {
  const _LifestyleChip({
    required this.category,
    required this.achieved,
    required this.isLoading,
    required this.onTap,
  });
  final LifestyleCategory category;
  final bool achieved;
  final bool isLoading;
  final VoidCallback? onTap;

  IconData get _icon {
    switch (category) {
      case LifestyleCategory.alcohol:  return Icons.no_drinks_outlined;
      case LifestyleCategory.smoking:  return Icons.smoke_free_outlined;
      case LifestyleCategory.exercise: return Icons.fitness_center_outlined;
      case LifestyleCategory.diet:     return Icons.restaurant_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = achieved ? const Color(0xFF16A34A) : cs.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: achieved
              ? const Color(0xFF16A34A).withOpacity(0.1)
              : cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: achieved ? const Color(0xFF16A34A).withOpacity(0.5) : cs.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(_icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              category.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight:
                        achieved ? FontWeight.w700 : FontWeight.normal,
                  ),
            ),
            if (achieved) ...[
              const Spacer(),
              Icon(Icons.check_circle, color: color, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BMI 차트 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _BmiSection extends ConsumerStatefulWidget {
  const _BmiSection();

  @override
  ConsumerState<_BmiSection> createState() => _BmiSectionState();
}

class _BmiSectionState extends ConsumerState<_BmiSection> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bmiRecordsProvider);
    final addState = ref.watch(bmiAddProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = addState is BmiAddLoading;

    ref.listen(bmiAddProvider, (_, next) {
      if (next is BmiAddSuccess) {
        _weightCtrl.clear();
        ref.read(bmiAddProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BMI가 기록되었습니다.')),
        );
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.monitor_weight_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('BMI 추이', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 16),

            // 입력
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: '체중 (kg)',
                    suffixText: 'kg',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: '신장 (cm)',
                    suffixText: 'cm',
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('BMI 기록'),
              ),
            ),

            // 최근 BMI 목록
            const SizedBox(height: 20),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: 'BMI 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(bmiRecordsProvider),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return Text('기록이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                final sorted = [...records]
                  ..sort((a, b) =>
                      b.recordedAt.compareTo(a.recordedAt));
                return Column(
                  children:
                      sorted.take(6).map(_BmiTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final w = double.tryParse(_weightCtrl.text.trim());
    final h = double.tryParse(_heightCtrl.text.trim());
    if (w == null || h == null || w <= 0 || h <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('체중과 신장을 올바르게 입력해주세요.')),
      );
      return;
    }
    ref
        .read(bmiAddProvider.notifier)
        .add(AddBmiRecordDto(weightKg: w, heightCm: h));
  }
}

class _BmiTile extends StatelessWidget {
  const _BmiTile(this.record);
  final BmiRecordModel record;

  Color _bmiColor(BuildContext context) {
    final bmi = record.bmi;
    final cs = Theme.of(context).colorScheme;
    if (bmi < 18.5) return const Color(0xFF3B82F6);
    if (bmi < 23.0) return const Color(0xFF16A34A);
    if (bmi < 25.0) return const Color(0xFFF59E0B);
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _bmiColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                record.bmi.toStringAsFixed(1),
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.bmiCategory,
                    style: theme.textTheme.bodyMedium),
                Text(
                  '${record.weightKg.toStringAsFixed(1)}kg / '
                  '${record.heightCm.toStringAsFixed(0)}cm',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('M/d').format(record.recordedAt.toLocal()),
            style: theme.textTheme.bodySmall,
          ),
        ],
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
