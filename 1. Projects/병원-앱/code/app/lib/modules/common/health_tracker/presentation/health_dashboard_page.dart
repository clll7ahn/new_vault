import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/health_model.dart';
import '../providers/health_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// HealthDashboardPage
// ──────────────────────────────────────────────────────────────────────────────

enum _DateRange { today, thisWeek }

class HealthDashboardPage extends ConsumerStatefulWidget {
  const HealthDashboardPage({super.key});

  @override
  ConsumerState<HealthDashboardPage> createState() =>
      _HealthDashboardPageState();
}

class _HealthDashboardPageState extends ConsumerState<HealthDashboardPage> {
  _DateRange _selected = _DateRange.today;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('건강 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새로고침',
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: CustomScrollView(
          slivers: [
            // ── 날짜 범위 칩 ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _DateChip(
                      label: '오늘',
                      selected: _selected == _DateRange.today,
                      onTap: () =>
                          setState(() => _selected = _DateRange.today),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: '이번 주',
                      selected: _selected == _DateRange.thisWeek,
                      onTap: () =>
                          setState(() => _selected = _DateRange.thisWeek),
                    ),
                  ],
                ),
              ),
            ),

            // ── 건강 수치 그리드 ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: _selected == _DateRange.today
                  ? _TodayGrid(date: DateTime.now())
                  : const _WeeklyGrid(),
            ),
          ],
        ),
      ),

      // ── FAB: 수치 입력 ──────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('수치 입력'),
      ),
    );
  }

  void _refresh() {
    ref.invalidate(snapshotProvider);
    ref.invalidate(weeklyProvider);
    final today = DateTime.now();
    ref.invalidate(dailySummaryProvider(
      DateTime(today.year, today.month, today.day),
    ));
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddRecordSheet(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 날짜 선택 칩
// ──────────────────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 오늘 그리드 (daily summary)
// ──────────────────────────────────────────────────────────────────────────────

class _TodayGrid extends ConsumerWidget {
  const _TodayGrid({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalised = DateTime(date.year, date.month, date.day);
    final async = ref.watch(dailySummaryProvider(normalised));

    return async.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: _ErrorRetry(
          message: '건강 데이터를 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(dailySummaryProvider(normalised)),
        ),
      ),
      data: (summaries) {
        final Map<HealthRecordType, HealthSummary> summaryMap = {
          for (final s in summaries) s.type: s,
        };
        return _HealthGrid(summaryMap: summaryMap);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 주간 그리드 (weekly summary)
// ──────────────────────────────────────────────────────────────────────────────

class _WeeklyGrid extends ConsumerWidget {
  const _WeeklyGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyProvider);

    return async.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: _ErrorRetry(
          message: '주간 데이터를 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(weeklyProvider),
        ),
      ),
      data: (summaries) {
        final Map<HealthRecordType, HealthSummary> summaryMap = {
          for (final s in summaries) s.type: s,
        };
        return _HealthGrid(summaryMap: summaryMap);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 2열 그리드 공통 레이아웃
// ──────────────────────────────────────────────────────────────────────────────

class _HealthGrid extends StatelessWidget {
  const _HealthGrid({required this.summaryMap});

  final Map<HealthRecordType, HealthSummary> summaryMap;

  @override
  Widget build(BuildContext context) {
    final types = HealthRecordType.values;

    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: types.length,
      itemBuilder: (context, i) {
        final type = types[i];
        return _HealthCard(
          type: type,
          summary: summaryMap[type],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 건강 수치 카드
// ──────────────────────────────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.type, this.summary});

  final HealthRecordType type;
  final HealthSummary? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final config = _cardConfig(type);

    final latest = summary?.latest;
    final hasData = latest != null;

    return Card(
      child: InkWell(
        onTap: () => _showDetailSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 아이콘 ────────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  config.icon,
                  color: config.color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),

              // ── 타입 레이블 ──────────────────────────────────────────
              Text(
                type.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),

              // ── 수치 ─────────────────────────────────────────────────
              if (hasData) ...[
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: latest.displayValue,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: config.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' ${type.unit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _relativeTime(latest.recordedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.outline,
                    fontSize: 11,
                  ),
                ),
              ] else ...[
                Text(
                  '기록 없음',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetailSheet(type: type),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return DateFormat('M/d').format(dt);
  }

  _CardConfig _cardConfig(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.bloodPressure:
        return _CardConfig(
          icon: Icons.favorite_outline,
          color: const Color(0xFFDC2626),
        );
      case HealthRecordType.bloodGlucose:
        return _CardConfig(
          icon: Icons.water_drop_outlined,
          color: const Color(0xFFF97316),
        );
      case HealthRecordType.weight:
        return _CardConfig(
          icon: Icons.monitor_weight_outlined,
          color: const Color(0xFF3B82F6),
        );
      case HealthRecordType.steps:
        return _CardConfig(
          icon: Icons.directions_walk_outlined,
          color: const Color(0xFF16A34A),
        );
      case HealthRecordType.heartRate:
        return _CardConfig(
          icon: Icons.favorite,
          color: const Color(0xFFEC4899),
        );
      case HealthRecordType.sleep:
        return _CardConfig(
          icon: Icons.nightlight_outlined,
          color: const Color(0xFF8B5CF6),
        );
    }
  }
}

class _CardConfig {
  const _CardConfig({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

// ──────────────────────────────────────────────────────────────────────────────
// 상세 기록 BottomSheet
// ──────────────────────────────────────────────────────────────────────────────

class _DetailSheet extends ConsumerWidget {
  const _DetailSheet({required this.type});

  final HealthRecordType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final query = (type: type, from: from, to: now);
    final async = ref.watch(healthRecordsProvider(query));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFmt = DateFormat('M월 d일 HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 핸들
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  Text(
                    '${type.label} 기록 (최근 30일)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorRetry(
                  message: '기록을 불러오지 못했습니다.',
                  onRetry: () => ref.invalidate(healthRecordsProvider(query)),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 56,
                            color: cs.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '기록이 없습니다.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final sorted = [...records]
                    ..sort(
                        (a, b) => b.recordedAt.compareTo(a.recordedAt));
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = sorted[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        tileColor: cs.surfaceContainerHighest.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          '${r.displayValue} ${type.unit}',
                          style: theme.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          dateFmt.format(r.recordedAt.toLocal()),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: r.source != null
                            ? Chip(
                                label: Text(r.source!),
                                padding: EdgeInsets.zero,
                                labelStyle:
                                    theme.textTheme.labelSmall,
                              )
                            : null,
                        minVerticalPadding: 12,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 수치 입력 BottomSheet
// ──────────────────────────────────────────────────────────────────────────────

class _AddRecordSheet extends ConsumerStatefulWidget {
  const _AddRecordSheet();

  @override
  ConsumerState<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<_AddRecordSheet> {
  HealthRecordType _type = HealthRecordType.bloodPressure;
  final _valueCtrl = TextEditingController();
  final _value2Ctrl = TextEditingController(); // 혈압 이완기
  final _formKey = GlobalKey<FormState>();

  bool get _needsSecondary => _type == HealthRecordType.bloodPressure;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _value2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final addState = ref.watch(healthAddProvider);
    final isLoading = addState is HealthAddLoading;

    // 성공 시 시트 닫기
    ref.listen(healthAddProvider, (prev, next) {
      if (next is HealthAddSuccess) {
        ref.read(healthAddProvider.notifier).reset();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_type.label} 수치가 저장되었습니다.'),
          ),
        );
      } else if (next is HealthAddError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: cs.error,
          ),
        );
        ref.read(healthAddProvider.notifier).reset();
      }
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text('건강 수치 입력', style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),

            // ── 타입 선택 ──────────────────────────────────────────────
            Text(
              '항목 선택',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HealthRecordType.values.map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(t.label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _type = t;
                      _valueCtrl.clear();
                      _value2Ctrl.clear();
                    });
                  },
                  selectedColor: cs.primaryContainer,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── 수치 입력 ──────────────────────────────────────────────
            if (_needsSecondary) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _valueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: false),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: '수축기 (mmHg)',
                        hintText: '예: 120',
                      ),
                      validator: _validateNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _value2Ctrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: false),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: '이완기 (mmHg)',
                        hintText: '예: 80',
                      ),
                      validator: _validateNumber,
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextFormField(
                controller: _valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: _type.label,
                  hintText: _hintText(_type),
                  suffixText: _type.unit,
                ),
                validator: _validateNumber,
              ),
            ],
            const SizedBox(height: 24),

            // ── 저장 버튼 ──────────────────────────────────────────────
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNumber(String? v) {
    if (v == null || v.trim().isEmpty) return '값을 입력해 주세요.';
    if (double.tryParse(v.trim()) == null) return '숫자만 입력해 주세요.';
    return null;
  }

  String _hintText(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.steps:
        return '예: 8000';
      case HealthRecordType.heartRate:
        return '예: 72';
      case HealthRecordType.sleep:
        return '예: 7.5';
      case HealthRecordType.bloodGlucose:
        return '예: 95';
      case HealthRecordType.weight:
        return '예: 65.5';
      default:
        return '';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_valueCtrl.text.trim());
    final double? value2 = _needsSecondary && _value2Ctrl.text.isNotEmpty
        ? double.tryParse(_value2Ctrl.text.trim())
        : null;

    ref.read(healthAddProvider.notifier).add(
          AddHealthRecordDto(
            type: _type,
            value: value,
            valueSecondary: value2,
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(160, 52),
            ),
          ),
        ],
      ),
    );
  }
}
