import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/neurology_model.dart';
import '../providers/neurology_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// NeurologyPage — 신경과
// ──────────────────────────────────────────────────────────────────────────────

class NeurologyPage extends ConsumerWidget {
  const NeurologyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신경과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(headacheLogsProvider);
              ref.invalidate(cognitivScoresProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(headacheLogsProvider);
          ref.invalidate(cognitivScoresProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _HeadacheJournalSection(),
            SizedBox(height: 20),
            _CognitivScoreSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 두통 일지
// ──────────────────────────────────────────────────────────────────────────────

class _HeadacheJournalSection extends ConsumerStatefulWidget {
  const _HeadacheJournalSection();

  @override
  ConsumerState<_HeadacheJournalSection> createState() =>
      _HeadacheJournalSectionState();
}

class _HeadacheJournalSectionState
    extends ConsumerState<_HeadacheJournalSection> {
  HeadacheType _type = HeadacheType.migraine;
  HeadacheLocation _location = HeadacheLocation.whole;
  double _intensity = 5.0;
  final Set<HeadacheTrigger> _triggers = {};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(headacheLogsProvider);
    final addState = ref.watch(headacheAddProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = addState is HeadacheAddLoading;

    ref.listen(headacheAddProvider, (_, next) {
      if (next is HeadacheAddSuccess) {
        setState(() {
          _intensity = 5.0;
          _triggers.clear();
        });
        ref.read(headacheAddProvider.notifier).reset();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('두통이 기록되었습니다.')));
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.psychology_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('두통 일지', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 16),

            // 유형 선택
            Text('유형', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: HeadacheType.values.map((t) => ChoiceChip(
                label: Text(t.label),
                selected: _type == t,
                onSelected: (_) => setState(() => _type = t),
              )).toList(),
            ),
            const SizedBox(height: 12),

            // 부위 선택
            Text('부위', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: HeadacheLocation.values.map((l) => ChoiceChip(
                label: Text(l.label),
                selected: _location == l,
                onSelected: (_) => setState(() => _location = l),
              )).toList(),
            ),
            const SizedBox(height: 12),

            // 강도 슬라이더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('강도', style: theme.textTheme.bodyMedium),
                Text(
                  '${_intensity.round()} / 10',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Slider(
              value: _intensity,
              min: 1,
              max: 10,
              divisions: 9,
              label: _intensity.round().toString(),
              onChanged: (v) => setState(() => _intensity = v),
            ),

            // 트리거
            Text('트리거 (복수 선택)',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: HeadacheTrigger.values.map((t) => FilterChip(
                label: Text(t.label),
                selected: _triggers.contains(t),
                onSelected: (v) => setState(
                    () => v ? _triggers.add(t) : _triggers.remove(t)),
              )).toList(),
            ),

            const SizedBox(height: 16),
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
                    : const Text('두통 기록'),
              ),
            ),

            // 최근 기록
            const SizedBox(height: 20),
            Text('최근 기록',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '두통 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(headacheLogsProvider),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Text('기록이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                final sorted = [...logs]
                  ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
                return Column(
                    children: sorted.take(5).map(_HeadacheTile.new).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    ref.read(headacheAddProvider.notifier).add(AddHeadacheLogDto(
          type: _type,
          location: _location,
          intensity: _intensity.round(),
          triggers: _triggers.toList(),
        ));
  }
}

class _HeadacheTile extends StatelessWidget {
  const _HeadacheTile(this.log);
  final HeadacheLogModel log;

  Color _intensityColor(BuildContext context, int intensity) {
    final cs = Theme.of(context).colorScheme;
    if (intensity <= 3) return const Color(0xFF16A34A);
    if (intensity <= 6) return const Color(0xFFF59E0B);
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _intensityColor(context, log.intensity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${log.intensity}',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.type.label} · ${log.location.label}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  DateFormat('M/d HH:mm').format(log.recordedAt.toLocal()),
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

// ──────────────────────────────────────────────────────────────────────────────
// 인지기능 점수 카드
// ──────────────────────────────────────────────────────────────────────────────

class _CognitivScoreSection extends ConsumerWidget {
  const _CognitivScoreSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cognitivScoresProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.neurology_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('인지기능 점수', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '인지기능 점수를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(cognitivScoresProvider),
              ),
              data: (scores) {
                if (scores.isEmpty) {
                  return Text('기록이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                return Column(
                  children: scores.map(_CognitivScoreTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CognitivScoreTile extends StatelessWidget {
  const _CognitivScoreTile(this.scoreModel);
  final CognitivScoreModel scoreModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ratio = scoreModel.ratio;
    final color = ratio >= 0.9
        ? const Color(0xFF16A34A)
        : ratio >= 0.7
            ? const Color(0xFFF59E0B)
            : cs.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(scoreModel.testName, style: theme.textTheme.bodyMedium),
              Text(
                '${scoreModel.score} / ${scoreModel.maxScore}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (scoreModel.interpretation != null) ...[
            const SizedBox(height: 2),
            Text(
              scoreModel.interpretation!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          Text(
            DateFormat('yyyy/M/d').format(scoreModel.assessedAt.toLocal()),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
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
