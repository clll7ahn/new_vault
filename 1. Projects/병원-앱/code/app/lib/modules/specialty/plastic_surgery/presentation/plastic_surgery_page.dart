import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/plastic_surgery_model.dart';
import '../providers/plastic_surgery_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PlasticSurgeryPage — 성형외과
// ──────────────────────────────────────────────────────────────────────────────

class PlasticSurgeryPage extends ConsumerWidget {
  const PlasticSurgeryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('성형외과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(proceduresProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(proceduresProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _ProcedureHistorySection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 시술 이력 + Before/After + 회복 일지
// ──────────────────────────────────────────────────────────────────────────────

class _ProcedureHistorySection extends ConsumerWidget {
  const _ProcedureHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proceduresProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.content_cut_outlined, color: cs.primary),
          const SizedBox(width: 8),
          Text('시술 이력', style: theme.textTheme.titleMedium),
        ]),
        const SizedBox(height: 12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorRetry(
            message: '시술 이력을 불러오지 못했습니다.',
            onRetry: () => ref.invalidate(proceduresProvider),
          ),
          data: (procedures) {
            if (procedures.isEmpty) {
              return Text('시술 이력이 없습니다.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant));
            }
            return Column(
              children: procedures
                  .map((p) => _ProcedureCard(procedure: p))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ProcedureCard extends ConsumerStatefulWidget {
  const _ProcedureCard({required this.procedure});
  final ProcedureRecordModel procedure;

  @override
  ConsumerState<_ProcedureCard> createState() => _ProcedureCardState();
}

class _ProcedureCardState extends ConsumerState<_ProcedureCard> {
  bool _expanded = false;
  int _swelling = 1;
  double _pain = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final proc = widget.procedure;
    final addState = ref.watch(recoveryAddProvider);
    final isLoading = addState is RecoveryAddLoading;

    ref.listen(recoveryAddProvider, (_, next) {
      if (next is RecoveryAddSuccess) {
        setState(() {
          _swelling = 1;
          _pain = 1.0;
        });
        ref.read(recoveryAddProvider.notifier).reset();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('회복 일지가 기록되었습니다.')));
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // 시술 헤더
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(proc.procedureName,
                style: theme.textTheme.titleSmall),
            subtitle: Text(
              [
                DateFormat('yyyy/M/d').format(proc.performedAt.toLocal()),
                if (proc.doctorName != null) proc.doctorName!,
              ].join(' · '),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Before/After 사진 비교
                  if (proc.hasPhotos) ...[
                    Text('Before / After',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _PhotoPlaceholder(
                          label: 'Before',
                          url: proc.beforePhotoUrl,
                        ),
                        const SizedBox(width: 12),
                        _PhotoPlaceholder(
                          label: 'After',
                          url: proc.afterPhotoUrl,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 회복 일지 입력
                  Text('회복 일지 기록',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('부기 레벨', style: theme.textTheme.bodyMedium),
                      Text('$_swelling / 5',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Slider(
                    value: _swelling.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_swelling',
                    onChanged: (v) =>
                        setState(() => _swelling = v.round()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('통증 레벨', style: theme.textTheme.bodyMedium),
                      Text('${_pain.round()} / 10',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Slider(
                    value: _pain,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${_pain.round()}',
                    onChanged: (v) => setState(() => _pain = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => ref
                              .read(recoveryAddProvider.notifier)
                              .add(AddRecoveryLogDto(
                                procedureId: proc.id,
                                swellingLevel: _swelling,
                                painLevel: _pain.round(),
                              )),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('회복 기록'),
                    ),
                  ),

                  // 회복 로그 이력
                  const SizedBox(height: 16),
                  _RecoveryLogList(procedureId: proc.id),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.label, this.url});
  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: url != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(url!, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: cs.outline, size: 32),
                    const SizedBox(height: 4),
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RecoveryLogList extends ConsumerWidget {
  const _RecoveryLogList({required this.procedureId});
  final String procedureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recoveryLogsProvider(procedureId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (logs) {
        if (logs.isEmpty) return const SizedBox.shrink();
        final sorted = [...logs]
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('회복 이력',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            ...sorted.take(5).map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('M/d').format(log.recordedAt.toLocal()),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '부기 ${log.swellingLevel}/5  통증 ${log.painLevel}/10',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
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
