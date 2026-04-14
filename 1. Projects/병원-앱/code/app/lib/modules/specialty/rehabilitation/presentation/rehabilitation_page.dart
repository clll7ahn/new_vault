import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/rehabilitation_model.dart';
import '../providers/rehabilitation_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// RehabilitationPage — 재활의학과
// ──────────────────────────────────────────────────────────────────────────────

class RehabilitationPage extends ConsumerWidget {
  const RehabilitationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('재활의학과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(evalScoresProvider);
              ref.invalidate(rehabExercisesProvider);
              ref.invalidate(sessionPainLogsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(evalScoresProvider);
          ref.invalidate(rehabExercisesProvider);
          ref.invalidate(sessionPainLogsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _EvalScoreSection(),
            SizedBox(height: 20),
            _ExerciseChecklistSection(),
            SizedBox(height: 20),
            _SessionPainSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 평가 점수 카드 (ROM/근력/ADL)
// ──────────────────────────────────────────────────────────────────────────────

class _EvalScoreSection extends ConsumerWidget {
  const _EvalScoreSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(evalScoresProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.assessment_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('평가 점수', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '평가 점수를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(evalScoresProvider),
              ),
              data: (scores) {
                if (scores.isEmpty) {
                  return Text('평가 기록이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                return Column(
                    children: scores.map(_EvalScoreTile.new).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EvalScoreTile extends StatelessWidget {
  const _EvalScoreTile(this.score);
  final EvalScoreModel score;

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (score.ratio >= 0.8) return const Color(0xFF16A34A);
    if (score.ratio >= 0.5) return const Color(0xFFF59E0B);
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _color(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                score.category.shortLabel +
                    (score.bodyPart != null ? ' (${score.bodyPart})' : ''),
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${score.score.toStringAsFixed(0)} / ${score.maxScore.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.ratio,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            DateFormat('yyyy/M/d').format(score.assessedAt.toLocal()),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 재활 운동 체크리스트
// ──────────────────────────────────────────────────────────────────────────────

class _ExerciseChecklistSection extends ConsumerWidget {
  const _ExerciseChecklistSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rehabExercisesProvider);
    final checked = ref.watch(exerciseCheckProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.fitness_center_outlined, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('오늘의 재활 운동', style: theme.textTheme.titleSmall),
                ]),
                if (checked.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        ref.read(exerciseCheckProvider.notifier).resetAll(),
                    child: const Text('초기화'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '운동 목록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(rehabExercisesProvider),
              ),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Text('운동 처방이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                final completed =
                    exercises.where((e) => checked.contains(e.id)).length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed / ${exercises.length} 완료',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    ...exercises.map((ex) {
                      final isDone = checked.contains(ex.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isDone,
                        onChanged: (_) => ref
                            .read(exerciseCheckProvider.notifier)
                            .toggle(ex.id),
                        title: Text(
                          ex.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? cs.onSurfaceVariant : null,
                          ),
                        ),
                        subtitle: Text(
                          '${ex.sets}세트 × ${ex.reps}회'
                          '${ex.targetBodyPart != null ? ' · ${ex.targetBodyPart}' : ''}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      );
                    }),
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

// ──────────────────────────────────────────────────────────────────────────────
// 세션별 통증 변화
// ──────────────────────────────────────────────────────────────────────────────

class _SessionPainSection extends ConsumerStatefulWidget {
  const _SessionPainSection();

  @override
  ConsumerState<_SessionPainSection> createState() =>
      _SessionPainSectionState();
}

class _SessionPainSectionState extends ConsumerState<_SessionPainSection> {
  double _painBefore = 5.0;
  double _painAfter = 3.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionPainLogsProvider);
    final addState = ref.watch(painLogAddProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = addState is PainLogAddLoading;

    ref.listen(painLogAddProvider, (_, next) {
      if (next is PainLogAddSuccess) {
        ref.read(painLogAddProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('통증 변화가 기록되었습니다.')),
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
              Icon(Icons.show_chart_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('세션별 통증 변화', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 16),

            // 입력
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('치료 전 통증', style: theme.textTheme.bodyMedium),
                Text('${_painBefore.round()} / 10',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.error, fontWeight: FontWeight.w600)),
              ],
            ),
            Slider(
              value: _painBefore,
              min: 0,
              max: 10,
              divisions: 10,
              label: '${_painBefore.round()}',
              activeColor: cs.error,
              onChanged: (v) => setState(() => _painBefore = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('치료 후 통증', style: theme.textTheme.bodyMedium),
                Text('${_painAfter.round()} / 10',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF16A34A),
                        fontWeight: FontWeight.w600)),
              ],
            ),
            Slider(
              value: _painAfter,
              min: 0,
              max: 10,
              divisions: 10,
              label: '${_painAfter.round()}',
              activeColor: const Color(0xFF16A34A),
              onChanged: (v) => setState(() => _painAfter = v),
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
                    : const Text('통증 기록'),
              ),
            ),

            // 최근 기록
            const SizedBox(height: 20),
            Text('세션 이력',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '통증 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(sessionPainLogsProvider),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Text('기록이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant));
                }
                final sorted = [...logs]
                  ..sort((a, b) =>
                      b.sessionDate.compareTo(a.sessionDate));
                return Column(
                  children: sorted
                      .take(7)
                      .map(_PainLogTile.new)
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    ref.read(painLogAddProvider.notifier).add(AddSessionPainLogDto(
          painBefore: _painBefore.round(),
          painAfter: _painAfter.round(),
        ));
  }
}

class _PainLogTile extends StatelessWidget {
  const _PainLogTile(this.log);
  final SessionPainLogModel log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final improved = log.painDelta <= 0;
    final deltaColor =
        improved ? const Color(0xFF16A34A) : cs.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('M/d (E)', 'ko').format(log.sessionDate.toLocal()),
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '전: ${log.painBefore}/10  후: ${log.painAfter}/10',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              log.painDelta <= 0 ? '${log.painDelta}' : '+${log.painDelta}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: deltaColor, fontWeight: FontWeight.w700),
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
