import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/urology_model.dart';
import '../providers/urology_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// UrologyPage — 비뇨의학과
// ──────────────────────────────────────────────────────────────────────────────

class UrologyPage extends ConsumerWidget {
  const UrologyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비뇨의학과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(voidingLogsProvider);
              ref.invalidate(psaRecordsProvider);
              ref.invalidate(todayHydrationProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(voidingLogsProvider);
          ref.invalidate(psaRecordsProvider);
          ref.invalidate(todayHydrationProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _HydrationCard(),
            SizedBox(height: 20),
            _VoidingJournalSection(),
            SizedBox(height: 20),
            _PsaSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 수분 섭취 알림 카드
// ──────────────────────────────────────────────────────────────────────────────

class _HydrationCard extends ConsumerWidget {
  const _HydrationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayHydrationProvider);
    final addState = ref.watch(hydrationAddProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = addState is HydrationAddLoading;

    ref.listen(hydrationAddProvider, (_, next) {
      if (next is HydrationAddSuccess) {
        ref.read(hydrationAddProvider.notifier).reset();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('수분 섭취가 기록되었습니다.')));
      }
    });

    final totalMl = async.whenOrNull(data: (v) => v) ?? 0;
    const goalMl = 2000;
    final ratio = (totalMl / goalMl).clamp(0.0, 1.0);

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.water_drop_outlined,
                  color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Text('오늘 수분 섭취',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: cs.onPrimaryContainer)),
            ]),
            const SizedBox(height: 12),
            Text(
              '$totalMl ml / $goalMl ml',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: cs.onPrimaryContainer.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                    cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [150, 200, 250, 500].map((ml) {
                return OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(hydrationAddProvider.notifier)
                          .add(AddHydrationLogDto(volumeMl: ml)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(56, 48),
                    side: BorderSide(
                        color: cs.onPrimaryContainer.withOpacity(0.5)),
                    foregroundColor: cs.onPrimaryContainer,
                  ),
                  child: Text('+$ml'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 배뇨 일지 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _VoidingJournalSection extends ConsumerStatefulWidget {
  const _VoidingJournalSection();

  @override
  ConsumerState<_VoidingJournalSection> createState() =>
      _VoidingJournalSectionState();
}

class _VoidingJournalSectionState
    extends ConsumerState<_VoidingJournalSection> {
  final _volumeCtrl = TextEditingController();
  int _urgency = 1;

  @override
  void dispose() {
    _volumeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(voidingLogsProvider);
    final addState = ref.watch(voidingAddProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = addState is VoidingAddLoading;

    ref.listen(voidingAddProvider, (_, next) {
      if (next is VoidingAddSuccess) {
        _volumeCtrl.clear();
        setState(() => _urgency = 1);
        ref.read(voidingAddProvider.notifier).reset();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('배뇨가 기록되었습니다.')));
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.water_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('배뇨 일지', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _volumeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '배뇨량 (ml)',
                suffixText: 'ml',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('절박뇨 강도', style: theme.textTheme.bodyMedium),
                Text(
                  '$_urgency / 5',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Slider(
              value: _urgency.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_urgency',
              onChanged: (v) => setState(() => _urgency = v.round()),
            ),
            const SizedBox(height: 8),
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
                    : const Text('배뇨 기록'),
              ),
            ),
            const SizedBox(height: 20),
            Text('최근 기록',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '배뇨 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(voidingLogsProvider),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Text('기록이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                final sorted = [...logs]
                  ..sort((a, b) =>
                      b.recordedAt.compareTo(a.recordedAt));
                return Column(
                  children:
                      sorted.take(7).map(_VoidingTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final vol = int.tryParse(_volumeCtrl.text.trim());
    if (vol == null || vol <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배뇨량을 올바르게 입력해주세요.')),
      );
      return;
    }
    ref.read(voidingAddProvider.notifier).add(
          AddVoidingLogDto(volumeMl: vol, urgency: _urgency),
        );
  }
}

class _VoidingTile extends StatelessWidget {
  const _VoidingTile(this.log);
  final VoidingLogModel log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.volumeMl} ml',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('M/d HH:mm').format(log.recordedAt.toLocal()),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (log.urgency != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  i < log.urgency! ? Icons.circle : Icons.circle_outlined,
                  size: 10,
                  color: cs.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PSA 추이 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _PsaSection extends ConsumerWidget {
  const _PsaSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(psaRecordsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.analytics_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('PSA 추이', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 4),
            Text('PSA: 전립선 특이항원 (ng/mL)',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: 'PSA 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(psaRecordsProvider),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return Text('PSA 기록이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                final sorted = [...records]
                  ..sort((a, b) =>
                      b.measuredAt.compareTo(a.measuredAt));
                return Column(
                  children: sorted.take(6).map(_PsaTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PsaTile extends StatelessWidget {
  const _PsaTile(this.record);
  final PsaRecordModel record;

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (record.valueNgMl < 4.0)  return const Color(0xFF16A34A);
    if (record.valueNgMl < 10.0) return const Color(0xFFF59E0B);
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _color(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                record.valueNgMl.toStringAsFixed(1),
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
                Text(record.riskLabel,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
                Text(
                  DateFormat('yyyy/M/d').format(record.measuredAt.toLocal()),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
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
