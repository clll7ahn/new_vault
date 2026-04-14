import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/ent_model.dart';
import '../providers/ent_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// EntPage — 이비인후과
// ──────────────────────────────────────────────────────────────────────────────

class EntPage extends ConsumerWidget {
  const EntPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이비인후과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(symptomLogsProvider);
              ref.invalidate(allergiesProvider);
              ref.invalidate(seasonAlertsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(symptomLogsProvider);
          ref.invalidate(allergiesProvider);
          ref.invalidate(seasonAlertsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _SeasonAlertSection(),
            SizedBox(height: 20),
            _SymptomJournalSection(),
            SizedBox(height: 20),
            _AllergyListSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 시즌 알림 카드
// ──────────────────────────────────────────────────────────────────────────────

class _SeasonAlertSection extends ConsumerWidget {
  const _SeasonAlertSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(seasonAlertsProvider);
    final cs = Theme.of(context).colorScheme;

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시즌 알림', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...alerts.map((a) => _AlertCard(a, cs)),
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard(this.alert, this.cs);
  final SeasonAlertModel alert;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cs.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.eco_outlined, color: cs.onTertiaryContainer),
        title: Text(alert.title,
            style: TextStyle(
                color: cs.onTertiaryContainer, fontWeight: FontWeight.w600)),
        subtitle: Text(alert.body,
            style: TextStyle(color: cs.onTertiaryContainer.withOpacity(0.8))),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 증상 일지 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _SymptomJournalSection extends ConsumerStatefulWidget {
  const _SymptomJournalSection();

  @override
  ConsumerState<_SymptomJournalSection> createState() =>
      _SymptomJournalSectionState();
}

class _SymptomJournalSectionState
    extends ConsumerState<_SymptomJournalSection> {
  final Set<EntSymptom> _selected = {};
  final Map<EntSymptom, double> _intensities = {
    for (final s in EntSymptom.values) s: 1.0,
  };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(symptomLogsProvider);
    final addState = ref.watch(symptomAddProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = addState is SymptomAddLoading;

    ref.listen(symptomAddProvider, (_, next) {
      if (next is SymptomAddSuccess) {
        setState(() => _selected.clear());
        ref.read(symptomAddProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('증상이 기록되었습니다.')),
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
              Icon(Icons.medical_services_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text('증상 일지', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 16),
            // 7종 증상 칩
            Text('증상 선택',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EntSymptom.values.map((s) {
                final sel = _selected.contains(s);
                return FilterChip(
                  label: Text(s.label),
                  selected: sel,
                  onSelected: (v) =>
                      setState(() => v ? _selected.add(s) : _selected.remove(s)),
                );
              }).toList(),
            ),

            // 선택된 증상 강도 슬라이더
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('강도 설정',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              ..._selected.map((s) => _IntensitySlider(
                    label: s.label,
                    value: _intensities[s] ?? 1.0,
                    onChanged: (v) =>
                        setState(() => _intensities[s] = v),
                  )),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_selected.isEmpty || isLoading) ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('증상 기록'),
              ),
            ),

            // 최근 기록
            const SizedBox(height: 20),
            Text('최근 기록',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(symptomLogsProvider),
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
                  children:
                      sorted.take(5).map(_SymptomLogTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    ref.read(symptomAddProvider.notifier).add(AddSymptomLogDto(
          symptoms: _selected.toList(),
          intensities: {
            for (final s in _selected) s.apiKey: _intensities[s]!.round(),
          },
        ));
  }
}

class _IntensitySlider extends StatelessWidget {
  const _IntensitySlider(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 24,
          child: Text(
            value.round().toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _SymptomLogTile extends StatelessWidget {
  const _SymptomLogTile(this.log);
  final SymptomLogModel log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.symptoms.map((s) => s.label).join(', '),
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
// 알레르기 목록
// ──────────────────────────────────────────────────────────────────────────────

class _AllergyListSection extends ConsumerWidget {
  const _AllergyListSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allergiesProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.warning_amber_outlined, color: cs.error),
              const SizedBox(width: 8),
              Text('알레르기 목록', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '알레르기 정보를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(allergiesProvider),
              ),
              data: (allergies) {
                if (allergies.isEmpty) {
                  return Text(
                    '등록된 알레르기가 없습니다.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  );
                }
                return Column(
                  children: allergies.map((a) => _AllergyTile(a)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergyTile extends StatelessWidget {
  const _AllergyTile(this.allergy);
  final AllergyModel allergy;

  Color _severityColor(BuildContext context, String? severity) {
    final cs = Theme.of(context).colorScheme;
    switch (severity) {
      case 'severe':   return cs.error;
      case 'moderate': return const Color(0xFFF59E0B);
      default:         return const Color(0xFF16A34A);
    }
  }

  String _severityLabel(String? severity) {
    switch (severity) {
      case 'severe':   return '중증';
      case 'moderate': return '중등도';
      default:         return '경증';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _severityColor(context, allergy.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(allergy.name, style: theme.textTheme.bodyMedium),
                Text(allergy.allergen,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _severityLabel(allergy.severity),
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
