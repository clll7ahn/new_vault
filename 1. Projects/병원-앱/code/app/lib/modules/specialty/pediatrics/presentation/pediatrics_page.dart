import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/pediatrics_model.dart';
import '../providers/pediatrics_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PediatricsPage
// ──────────────────────────────────────────────────────────────────────────────

class PediatricsPage extends ConsumerWidget {
  const PediatricsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('소아과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새로고침',
            onPressed: () {
              ref.invalidate(childrenProvider);
              final childId = ref.read(selectedChildIdProvider);
              if (childId != null) {
                ref.invalidate(growthLogsProvider(childId));
                ref.invalidate(vaccinationsProvider(childId));
              }
            },
          ),
        ],
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
          message: '자녀 정보를 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(childrenProvider),
        ),
        data: (children) {
          if (children.isEmpty) {
            return _EmptyChildren(
              onAdd: () => _showAddChildSheet(context, ref),
            );
          }

          // 선택된 자녀가 없으면 첫 번째 자녀를 기본 선택
          final selectedId = ref.watch(selectedChildIdProvider) ??
              (ref.read(selectedChildIdProvider) == null
                  ? children.first.id
                  : null);
          final effectiveId = selectedId ?? children.first.id;

          return _PediatricsBody(
            children: children,
            selectedChildId: effectiveId,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChildSheet(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('자녀 추가'),
      ),
    );
  }

  void _showAddChildSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddChildSheet(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 자녀 없음 안내
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyChildren extends StatelessWidget {
  const _EmptyChildren({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.child_care_outlined, size: 72, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            '등록된 자녀가 없습니다.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('자녀 등록'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 52),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 메인 대시보드 바디
// ──────────────────────────────────────────────────────────────────────────────

class _PediatricsBody extends ConsumerWidget {
  const _PediatricsBody({
    required this.children,
    required this.selectedChildId,
  });

  final List<ChildModel> children;
  final String selectedChildId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(growthLogsProvider(selectedChildId));
        ref.invalidate(vaccinationsProvider(selectedChildId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 자녀 선택 드롭다운 ──────────────────────────────────────
          _ChildDropdown(children: children, selectedId: selectedChildId),
          const SizedBox(height: 20),

          // ── 성장 차트 ────────────────────────────────────────────────
          _GrowthChartSection(childId: selectedChildId),
          const SizedBox(height: 20),

          // ── 예방접종 체크리스트 ──────────────────────────────────────
          _VaccinationSection(childId: selectedChildId),
          const SizedBox(height: 80), // FAB 여백
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 자녀 선택 드롭다운
// ──────────────────────────────────────────────────────────────────────────────

class _ChildDropdown extends ConsumerWidget {
  const _ChildDropdown({
    required this.children,
    required this.selectedId,
  });

  final List<ChildModel> children;
  final String selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selected = children.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => children.first,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          icon: Icon(Icons.expand_more, color: cs.primary),
          style: Theme.of(context).textTheme.titleSmall,
          items: children.map((child) {
            return DropdownMenuItem<String>(
              value: child.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      child.name.characters.first,
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        child.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        child.ageLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id != null) {
              ref.read(selectedChildIdProvider.notifier).state = id;
            }
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 성장 차트 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _GrowthChartSection extends ConsumerWidget {
  const _GrowthChartSection({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(growthLogsProvider(childId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text('성장 기록', style: theme.textTheme.titleSmall),
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
                message: '성장 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(growthLogsProvider(childId)),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '측정 기록이 없습니다.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final sorted = [...logs]
                  ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
                final latest = sorted.first;
                return Column(
                  children: [
                    _GrowthBarRow(
                      label: '키',
                      value: latest.heightCm,
                      unit: 'cm',
                      percentile: latest.heightPercentile,
                      color: const Color(0xFF3B82F6),
                      maxValue: 200,
                    ),
                    const SizedBox(height: 12),
                    _GrowthBarRow(
                      label: '몸무게',
                      value: latest.weightKg,
                      unit: 'kg',
                      percentile: latest.weightPercentile,
                      color: const Color(0xFF16A34A),
                      maxValue: 100,
                    ),
                    const SizedBox(height: 8),
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

class _GrowthBarRow extends StatelessWidget {
  const _GrowthBarRow({
    required this.label,
    required this.value,
    required this.unit,
    this.percentile,
    required this.color,
    required this.maxValue,
  });

  final String label;
  final double value;
  final String unit;
  final double? percentile;
  final Color color;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ratio = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Row(
              children: [
                Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (percentile != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percentile!.toStringAsFixed(0)}백분위',
                      style: theme.textTheme.labelSmall?.copyWith(color: color),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 예방접종 체크리스트 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _VaccinationSection extends ConsumerWidget {
  const _VaccinationSection({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vaccinationsProvider(childId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vaccines_outlined,
                    color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text('예방접종', style: theme.textTheme.titleSmall),
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
                message: '예방접종 정보를 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(vaccinationsProvider(childId)),
              ),
              data: (vaccinations) {
                if (vaccinations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '접종 일정이 없습니다.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final sorted = [...vaccinations]
                  ..sort((a, b) =>
                      a.scheduledDate.compareTo(b.scheduledDate));
                return Column(
                  children: sorted
                      .map((v) => _VaccinationTile(
                            vaccination: v,
                            childId: childId,
                          ))
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

class _VaccinationTile extends ConsumerWidget {
  const _VaccinationTile({
    required this.vaccination,
    required this.childId,
  });

  final VaccinationModel vaccination;
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color statusColor;
    IconData statusIcon;
    switch (vaccination.status) {
      case VaccinationStatus.completed:
        statusColor = const Color(0xFF16A34A);
        statusIcon = Icons.check_circle;
        break;
      case VaccinationStatus.delayed:
        statusColor = cs.error;
        statusIcon = Icons.warning_rounded;
        break;
      case VaccinationStatus.upcoming:
        statusColor = const Color(0xFFF97316);
        statusIcon = Icons.schedule;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: vaccination.status == VaccinationStatus.completed
            ? null
            : () => _confirmMarkComplete(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vaccination.vaccineName} ${vaccination.doseNumber}차',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      DateFormat('yyyy.MM.dd').format(vaccination.scheduledDate),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vaccination.status.label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmMarkComplete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('접종 완료 처리'),
        content: Text(
            '${vaccination.vaccineName} ${vaccination.doseNumber}차 접종을 완료로 표시할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(vaccinationUpdateProvider.notifier).markCompleted(
                    vaccinationId: vaccination.id,
                    childId: childId,
                  );
            },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 48)),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 자녀 추가 BottomSheet
// ──────────────────────────────────────────────────────────────────────────────

class _AddChildSheet extends ConsumerStatefulWidget {
  const _AddChildSheet();

  @override
  ConsumerState<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends ConsumerState<_AddChildSheet> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _birthDate;
  String _gender = 'male';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
            Text('자녀 등록', style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '이름'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '이름을 입력해 주세요.' : null,
            ),
            const SizedBox(height: 16),
            // 생년월일 선택
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '생년월일',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _birthDate != null
                      ? DateFormat('yyyy.MM.dd').format(_birthDate!)
                      : '날짜를 선택하세요',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _birthDate != null
                        ? cs.onSurface
                        : cs.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 성별 선택
            Text(
              '성별',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _GenderChip(
                    label: '남자',
                    selected: _gender == 'male',
                    onTap: () => setState(() => _gender = 'male'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderChip(
                    label: '여자',
                    selected: _gender == 'female',
                    onTap: () => setState(() => _gender = 'female'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: '생년월일 선택',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 선택해 주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(pediatricsRepositoryProvider).addChild(
            AddChildDto(
              name: _nameCtrl.text.trim(),
              birthDate: _birthDate!,
              gender: _gender,
            ),
          );
      ref.invalidate(childrenProvider);
      if (mounted) Navigator.pop(context);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
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
        duration: const Duration(milliseconds: 150),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
        ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
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
