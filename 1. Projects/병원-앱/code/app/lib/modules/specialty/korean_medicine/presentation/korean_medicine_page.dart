import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/korean_medicine_model.dart';
import '../providers/korean_medicine_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// KoreanMedicinePage — 한의원
// ──────────────────────────────────────────────────────────────────────────────

class KoreanMedicinePage extends ConsumerWidget {
  const KoreanMedicinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('한의원'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(sasangProfileProvider);
              ref.invalidate(treatmentRecordsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sasangProfileProvider);
          ref.invalidate(treatmentRecordsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _SasangCard(),
            SizedBox(height: 20),
            _TreatmentHistorySection(),
            SizedBox(height: 20),
            _SasangGuideSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 체질 카드
// ──────────────────────────────────────────────────────────────────────────────

class _SasangCard extends ConsumerWidget {
  const _SasangCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sasangProfileProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text('체질 정보를 불러오지 못했습니다.',
              style: theme.textTheme.bodyMedium),
          data: (profile) {
            if (profile == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.person_outline,
                        color: cs.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Text('체질 미등록',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: cs.onSecondaryContainer)),
                  ]),
                  const SizedBox(height: 8),
                  Text('한의사 진료 후 체질이 등록됩니다.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSecondaryContainer.withOpacity(0.7))),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.person_outline, color: cs.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Text('나의 체질',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: cs.onSecondaryContainer)),
                ]),
                const SizedBox(height: 12),
                Text(
                  profile.sasangType.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.sasangType.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSecondaryContainer.withOpacity(0.85)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 치료 이력 (침/뜸/한약)
// ──────────────────────────────────────────────────────────────────────────────

class _TreatmentHistorySection extends ConsumerWidget {
  const _TreatmentHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(treatmentRecordsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.healing_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('치료 이력', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '치료 이력을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(treatmentRecordsProvider),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return Text('치료 이력이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                final sorted = [...records]
                  ..sort((a, b) =>
                      b.performedAt.compareTo(a.performedAt));
                return Column(
                  children: sorted
                      .take(10)
                      .map(_TreatmentTile.new)
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

class _TreatmentTile extends StatelessWidget {
  const _TreatmentTile(this.record);
  final TreatmentRecordModel record;

  IconData get _icon {
    switch (record.treatmentType) {
      case TreatmentType.acupuncture:    return Icons.electric_bolt_outlined;
      case TreatmentType.moxibustion:    return Icons.local_fire_department_outlined;
      case TreatmentType.herbalMedicine: return Icons.local_pharmacy_outlined;
      case TreatmentType.cupping:        return Icons.bubble_chart_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.treatmentType.label,
                    style: theme.textTheme.bodyMedium),
                Text(
                  DateFormat('yyyy/M/d').format(
                      record.performedAt.toLocal()),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (record.duration != null)
            Text('${record.duration}분',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 섭생 가이드 (추천/금지 음식)
// ──────────────────────────────────────────────────────────────────────────────

class _SasangGuideSection extends ConsumerWidget {
  const _SasangGuideSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(sasangProfileProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sasangType =
        profileAsync.whenOrNull(data: (p) => p?.sasangType) ??
            SasangType.taeum;

    final guideAsync = ref.watch(sasangGuideProvider(sasangType));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.restaurant_menu_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('섭생 가이드 (${sasangType.label})',
                  style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            guideAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (guide) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FoodList(
                    title: '추천 음식',
                    foods: guide.recommendedFoods,
                    isRecommended: true,
                  ),
                  const SizedBox(height: 12),
                  _FoodList(
                    title: '금기 음식',
                    foods: guide.avoidFoods,
                    isRecommended: false,
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

class _FoodList extends StatelessWidget {
  const _FoodList({
    required this.title,
    required this.foods,
    required this.isRecommended,
  });

  final String title;
  final List<String> foods;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color =
        isRecommended ? const Color(0xFF16A34A) : cs.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(
            isRecommended ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(title,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: foods.map((f) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(f,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: color)),
              )).toList(),
        ),
      ],
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
