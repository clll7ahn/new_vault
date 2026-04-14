import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/obstetrics_model.dart';
import '../providers/obstetrics_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// ObstetricsPage
// ──────────────────────────────────────────────────────────────────────────────

class ObstetricsPage extends ConsumerWidget {
  const ObstetricsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancyAsync = ref.watch(pregnancyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('산부인과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새로고침',
            onPressed: () {
              ref.invalidate(pregnancyProvider);
              ref.invalidate(checkupsProvider);
              ref.invalidate(fetalMovementsTodayProvider);
              ref.invalidate(maternalLogsProvider);
            },
          ),
        ],
      ),
      body: pregnancyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
          message: '임신 정보를 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(pregnancyProvider),
        ),
        data: (pregnancy) {
          if (pregnancy == null) {
            return const _NoPregnancyView();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pregnancyProvider);
              ref.invalidate(checkupsProvider);
              ref.invalidate(fetalMovementsTodayProvider);
              ref.invalidate(maternalLogsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _WeekCard(pregnancy: pregnancy),
                const SizedBox(height: 20),
                const _CheckupListSection(),
                const SizedBox(height: 20),
                const _FetalMovementCounter(),
                const SizedBox(height: 20),
                const _MaternalHealthCard(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 임신 정보 없음
// ──────────────────────────────────────────────────────────────────────────────

class _NoPregnancyView extends StatelessWidget {
  const _NoPregnancyView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pregnant_woman_outlined, size: 72, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            '등록된 임신 정보가 없습니다.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 임신 주수 카드
// ──────────────────────────────────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.pregnancy});
  final PregnancyModel pregnancy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final days = pregnancy.daysUntilDue;
    final isPast = days < 0;

    return Card(
      color: cs.primaryContainer.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 주수
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pregnancy.weekNumber}',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    '주',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (pregnancy.fetalNickname != null)
              Text(
                pregnancy.fetalNickname!,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            const SizedBox(height: 12),
            // 태아 크기
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.child_friendly_outlined,
                      size: 20, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    '지금 태아 크기: ${pregnancy.fetalSizeComparison}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // D-Day
            if (pregnancy.dueDate != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_outlined, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '출산 예정일: ${DateFormat('yyyy.MM.dd').format(pregnancy.dueDate!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPast ? cs.error : cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPast
                          ? 'D+${-days}'
                          : days == 0
                              ? 'D-Day'
                              : 'D-$days',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 산전 검진 체크리스트
// ──────────────────────────────────────────────────────────────────────────────

class _CheckupListSection extends ConsumerWidget {
  const _CheckupListSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(checkupsProvider);
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
                Icon(Icons.checklist_outlined, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('산전 검진 스케줄', style: theme.textTheme.titleSmall),
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
                message: '검진 일정을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(checkupsProvider),
              ),
              data: (checkups) {
                if (checkups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '등록된 검진 일정이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                final sorted = [...checkups]
                  ..sort((a, b) =>
                      a.scheduledWeek.compareTo(b.scheduledWeek));
                return Column(
                  children: sorted.map(_CheckupTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckupTile extends StatelessWidget {
  const _CheckupTile(this.checkup);
  final CheckupModel checkup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            checkup.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: checkup.isCompleted
                ? const Color(0xFF16A34A)
                : cs.outline,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkup.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: checkup.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: checkup.isCompleted
                        ? cs.onSurfaceVariant
                        : cs.onSurface,
                  ),
                ),
                Text(
                  '${checkup.scheduledWeek}주 · ${DateFormat('yyyy.MM.dd').format(checkup.scheduledDate)}',
                  style: theme.textTheme.bodySmall,
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
// 태동 카운터
// ──────────────────────────────────────────────────────────────────────────────

class _FetalMovementCounter extends ConsumerWidget {
  const _FetalMovementCounter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(fetalMovementsTodayProvider);
    final localCount = ref.watch(fetalMovementCountProvider);
    final addState = ref.watch(fetalMovementNotifierProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = addState is FetalMovementLoading;

    final todayTotal = todayAsync.whenOrNull(
          data: (list) => list.fold<int>(0, (sum, m) => sum + m.count),
        ) ??
        0;

    final displayCount = todayTotal + localCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.favorite_border, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('태동 카운터', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            // 큰 숫자
            Text(
              '$displayCount',
              style: theme.textTheme.displaySmall?.copyWith(
                color: const Color(0xFFEC4899),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '오늘 태동 횟수',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            // 카운터 버튼 (48dp+)
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(fetalMovementNotifierProvider.notifier)
                          .addOne();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isLoading
                      ? cs.surfaceContainerHighest
                      : const Color(0xFFEC4899),
                  shape: BoxShape.circle,
                  boxShadow: isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.touch_app_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '탭하여 태동 기록',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 산모 건강 기록 카드
// ──────────────────────────────────────────────────────────────────────────────

class _MaternalHealthCard extends ConsumerWidget {
  const _MaternalHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(maternalLogsProvider);
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
                Row(
                  children: [
                    Icon(Icons.monitor_heart_outlined,
                        color: cs.primary, size: 24),
                    const SizedBox(width: 8),
                    Text('산모 건강 기록', style: theme.textTheme.titleSmall),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddMaternalLog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('기록'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                ),
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
                message: '건강 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(maternalLogsProvider),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '체중/혈압 기록이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                final sorted = [...logs]
                  ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
                final latest = sorted.first;
                return Row(
                  children: [
                    Expanded(
                      child: _HealthMetricBox(
                        label: '체중',
                        value: latest.weightKg != null
                            ? '${latest.weightKg!.toStringAsFixed(1)} kg'
                            : '-',
                        icon: Icons.monitor_weight_outlined,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HealthMetricBox(
                        label: '혈압',
                        value: latest.bpLabel,
                        icon: Icons.favorite_outline,
                        color: const Color(0xFFDC2626),
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

  void _showAddMaternalLog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddMaternalLogSheet(),
    );
  }
}

class _HealthMetricBox extends StatelessWidget {
  const _HealthMetricBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
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
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 산모 기록 입력 시트
// ──────────────────────────────────────────────────────────────────────────────

class _AddMaternalLogSheet extends ConsumerStatefulWidget {
  const _AddMaternalLogSheet();

  @override
  ConsumerState<_AddMaternalLogSheet> createState() =>
      _AddMaternalLogSheetState();
}

class _AddMaternalLogSheetState extends ConsumerState<_AddMaternalLogSheet> {
  final _weightCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
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
            Text('산모 건강 기록', style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            TextFormField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              decoration: const InputDecoration(
                labelText: '체중 (kg)',
                hintText: '예: 62.5',
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _systolicCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '수축기 혈압',
                      hintText: '예: 110',
                      suffixText: 'mmHg',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _diastolicCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '이완기 혈압',
                      hintText: '예: 70',
                      suffixText: 'mmHg',
                    ),
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
                    : const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final weightText = _weightCtrl.text.trim();
    final systolicText = _systolicCtrl.text.trim();
    final diastolicText = _diastolicCtrl.text.trim();

    if (weightText.isEmpty && systolicText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('체중 또는 혈압을 입력해 주세요.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(obstetricsRepositoryProvider).addMaternalLog(
            AddMaternalLogDto(
              weightKg: weightText.isNotEmpty
                  ? double.tryParse(weightText)
                  : null,
              systolicBp: systolicText.isNotEmpty
                  ? int.tryParse(systolicText)
                  : null,
              diastolicBp: diastolicText.isNotEmpty
                  ? int.tryParse(diastolicText)
                  : null,
            ),
          );
      ref.invalidate(maternalLogsProvider);
      if (mounted) Navigator.pop(context);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          const Icon(Icons.error_outline, size: 40),
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
