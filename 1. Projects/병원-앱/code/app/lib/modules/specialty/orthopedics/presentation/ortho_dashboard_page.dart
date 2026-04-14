import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/ortho_model.dart';
import '../providers/ortho_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// OrthoDashboardPage — 정형외과 대시보드
// ──────────────────────────────────────────────────────────────────────────────

class OrthoDashboardPage extends ConsumerStatefulWidget {
  const OrthoDashboardPage({super.key});

  @override
  ConsumerState<OrthoDashboardPage> createState() =>
      _OrthoDashboardPageState();
}

class _OrthoDashboardPageState extends ConsumerState<OrthoDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final part = ref.read(selectedBodyPartProvider);
    ref.invalidate(painLogsProvider((bodyPart: part, from: from, to: now)));
    ref.invalidate(painTrendProvider((bodyPart: part, days: 14)));
    ref.invalidate(rehabProgramsProvider);
    ref.invalidate(exerciseChecklistProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정형외과 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새로고침',
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.healing_outlined), text: '통증 일지'),
            Tab(icon: Icon(Icons.fitness_center_outlined), text: '재활 운동'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PainTab(),
          _RehabTab(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 탭 1: 통증 일지
// ──────────────────────────────────────────────────────────────────────────────

class _PainTab extends ConsumerWidget {
  const _PainTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final selectedPart = ref.watch(selectedBodyPartProvider);
    final logsAsync = ref.watch(
      painLogsProvider((bodyPart: selectedPart, from: from, to: now)),
    );
    final trendAsync = ref.watch(
      painTrendProvider((bodyPart: selectedPart, days: 14)),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
            painLogsProvider((bodyPart: selectedPart, from: from, to: now)));
        ref.invalidate(
            painTrendProvider((bodyPart: selectedPart, days: 14)));
      },
      child: CustomScrollView(
        slivers: [
          // ── 통증 기록 버튼 + 부위 선택 ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기록 버튼
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddPainSheet(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('통증 기록하기'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 인체 실루엣 + 부위 선택
                  Text(
                    '부위 선택',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const _BodyPartSelector(),
                ],
              ),
            ),
          ),

          // ── 트렌드 차트 ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '통증 트렌드 (최근 14일)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: trendAsync.when(
                      loading: () => const _MiniLoader(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (points) => _PainTrendChart(points: points),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '최근 기록',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),

          // ── 통증 기록 리스트 ──────────────────────────────────────────
          logsAsync.when(
            loading: () =>
                const SliverToBoxAdapter(child: _MiniLoader()),
            error: (e, _) => SliverToBoxAdapter(
              child: _InlineError(
                onRetry: () => ref.invalidate(
                  painLogsProvider(
                      (bodyPart: selectedPart, from: from, to: now)),
                ),
              ),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyState(
                    icon: Icons.healing_outlined,
                    message: '통증 기록이 없습니다.',
                  ),
                );
              }
              final sorted = [...logs]
                ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _PainLogTile(log: sorted[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddPainSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddPainSheet(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 인체 실루엣 + 부위 선택 버튼
// ──────────────────────────────────────────────────────────────────────────────

class _BodyPartSelector extends ConsumerWidget {
  const _BodyPartSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedBodyPartProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 인체 실루엣 근사 (SVG 없이 컨테이너로)
        Center(
          child: SizedBox(
            width: 120,
            height: 200,
            child: CustomPaint(
              painter: _BodySilhouettePainter(
                selectedPart: selected,
                highlightColor: cs.primary,
                bodyColor: cs.surfaceContainerHighest,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 부위 선택 칩
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PartChip(
              label: '전체',
              selected: selected == null,
              onTap: () =>
                  ref.read(selectedBodyPartProvider.notifier).state = null,
            ),
            ...BodyPart.values.map(
              (p) => _PartChip(
                label: p.label,
                selected: selected == p,
                onTap: () =>
                    ref.read(selectedBodyPartProvider.notifier).state = p,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 인체 실루엣 CustomPainter — 주요 부위를 타원으로 근사
class _BodySilhouettePainter extends CustomPainter {
  const _BodySilhouettePainter({
    required this.selectedPart,
    required this.highlightColor,
    required this.bodyColor,
  });

  final BodyPart? selectedPart;
  final Color highlightColor;
  final Color bodyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    void drawPart(Rect rect, BodyPart? part) {
      paint.color = (selectedPart == part && part != null)
          ? highlightColor.withOpacity(0.7)
          : bodyColor;
      canvas.drawOval(rect, paint);
    }

    // 머리
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.07),
      w * 0.15,
      Paint()..color = bodyColor,
    );
    // 목
    drawPart(Rect.fromCenter(center: Offset(w * 0.5, h * 0.155), width: w * 0.15, height: h * 0.05), BodyPart.neck);
    // 몸통
    drawPart(Rect.fromCenter(center: Offset(w * 0.5, h * 0.35), width: w * 0.42, height: h * 0.25), null);
    // 어깨
    drawPart(Rect.fromCenter(center: Offset(w * 0.15, h * 0.23), width: w * 0.18, height: h * 0.08), BodyPart.shoulder);
    drawPart(Rect.fromCenter(center: Offset(w * 0.85, h * 0.23), width: w * 0.18, height: h * 0.08), BodyPart.shoulder);
    // 팔
    drawPart(Rect.fromCenter(center: Offset(w * 0.1, h * 0.38), width: w * 0.12, height: h * 0.22), BodyPart.elbow);
    drawPart(Rect.fromCenter(center: Offset(w * 0.9, h * 0.38), width: w * 0.12, height: h * 0.22), BodyPart.elbow);
    // 손목
    drawPart(Rect.fromCenter(center: Offset(w * 0.1, h * 0.54), width: w * 0.12, height: h * 0.08), BodyPart.wrist);
    drawPart(Rect.fromCenter(center: Offset(w * 0.9, h * 0.54), width: w * 0.12, height: h * 0.08), BodyPart.wrist);
    // 허리/하부등
    drawPart(Rect.fromCenter(center: Offset(w * 0.5, h * 0.51), width: w * 0.38, height: h * 0.1), BodyPart.lowerBack);
    // 고관절
    drawPart(Rect.fromCenter(center: Offset(w * 0.5, h * 0.6), width: w * 0.42, height: h * 0.09), BodyPart.hip);
    // 무릎
    drawPart(Rect.fromCenter(center: Offset(w * 0.3, h * 0.77), width: w * 0.18, height: h * 0.1), BodyPart.knee);
    drawPart(Rect.fromCenter(center: Offset(w * 0.7, h * 0.77), width: w * 0.18, height: h * 0.1), BodyPart.knee);
    // 발목
    drawPart(Rect.fromCenter(center: Offset(w * 0.3, h * 0.93), width: w * 0.15, height: h * 0.07), BodyPart.ankle);
    drawPart(Rect.fromCenter(center: Offset(w * 0.7, h * 0.93), width: w * 0.15, height: h * 0.07), BodyPart.ankle);
  }

  @override
  bool shouldRepaint(_BodySilhouettePainter old) =>
      old.selectedPart != selectedPart;
}

class _PartChip extends StatelessWidget {
  const _PartChip({
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
// 통증 트렌드 바 차트
// ──────────────────────────────────────────────────────────────────────────────

class _PainTrendChart extends StatelessWidget {
  const _PainTrendChart({required this.points});

  final List<PainTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          '데이터 없음',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    const maxIntensity = 10.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.asMap().entries.map((entry) {
        final point = entry.value;
        final ratio = (point.avgIntensity / maxIntensity).clamp(0.05, 1.0);
        final isLast = entry.key == points.length - 1;

        Color barColor;
        if (point.avgIntensity <= 3) {
          barColor = const Color(0xFF16A34A);
        } else if (point.avgIntensity <= 6) {
          barColor = const Color(0xFFF97316);
        } else {
          barColor = const Color(0xFFDC2626);
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isLast)
                  Text(
                    point.avgIntensity.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 9,
                      color: barColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 2),
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLast
                            ? barColor
                            : barColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('d').format(point.date),
                  style: TextStyle(
                    fontSize: 9,
                    color: isLast
                        ? barColor
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 통증 기록 타일
// ──────────────────────────────────────────────────────────────────────────────

class _PainLogTile extends StatelessWidget {
  const _PainLogTile({required this.log});

  final PainLogModel log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFmt = DateFormat('M월 d일 HH:mm');
    final color = log.intensityColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 강도 표시
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${log.intensity}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        log.bodyPart.label,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (log.painType != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(log.painType!.label),
                          labelStyle: theme.textTheme.labelSmall,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFmt.format(log.recordedAt.toLocal()),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (log.triggers != null && log.triggers!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: log.triggers!
                          .map((t) => Chip(
                                label: Text(t),
                                labelStyle: theme.textTheme.labelSmall,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                  if (log.notes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      log.notes!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.outline),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 통증 기록 입력 시트
// ──────────────────────────────────────────────────────────────────────────────

class _AddPainSheet extends ConsumerStatefulWidget {
  const _AddPainSheet();

  @override
  ConsumerState<_AddPainSheet> createState() => _AddPainSheetState();
}

class _AddPainSheetState extends ConsumerState<_AddPainSheet> {
  BodyPart _bodyPart = BodyPart.knee;
  PainType? _painType;
  int _intensity = 5;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(painLogNotifierProvider);
    final isLoading = state is PainLogLoading;

    ref.listen(painLogNotifierProvider, (_, next) {
      if (next is PainLogSuccess) {
        ref.read(painLogNotifierProvider.notifier).reset();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('통증이 기록되었습니다.')),
        );
      } else if (next is PainLogError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: cs.error,
          ),
        );
        ref.read(painLogNotifierProvider.notifier).reset();
      }
    });

    final intensityColor = _intensity <= 3
        ? const Color(0xFF16A34A)
        : _intensity <= 6
            ? const Color(0xFFF97316)
            : const Color(0xFFDC2626);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
          Text('통증 기록', style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),

          // 부위 선택
          Text('부위',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: BodyPart.values
                .map((p) => ChoiceChip(
                      label: Text(p.label),
                      selected: _bodyPart == p,
                      onSelected: (_) => setState(() => _bodyPart = p),
                      selectedColor: cs.primaryContainer,
                      labelStyle: theme.textTheme.labelMedium,
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // 강도 슬라이더
          Row(
            children: [
              Text('강도',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const Spacer(),
              Text(
                '$_intensity / 10',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: intensityColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_intensity',
            activeColor: intensityColor,
            onChanged: (v) => setState(() => _intensity = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('약함', style: theme.textTheme.labelSmall),
              Text('보통', style: theme.textTheme.labelSmall),
              Text('심함', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 16),

          // 통증 유형
          Text('통증 유형 (선택)',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: PainType.values
                .map((p) => ChoiceChip(
                      label: Text(p.label),
                      selected: _painType == p,
                      onSelected: (_) => setState(
                          () => _painType = _painType == p ? null : p),
                      selectedColor: cs.secondaryContainer,
                      labelStyle: theme.textTheme.labelMedium,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // 메모
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              hintText: '언제, 어떤 상황에서 아팠나요?',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

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
    );
  }

  void _submit() {
    ref.read(painLogNotifierProvider.notifier).add(
          bodyPart: _bodyPart,
          intensity: _intensity,
          painType: _painType,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 탭 2: 재활 운동
// ──────────────────────────────────────────────────────────────────────────────

class _RehabTab extends ConsumerWidget {
  const _RehabTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(rehabProgramsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(rehabProgramsProvider);
        ref.read(exerciseChecklistProvider.notifier).reset();
      },
      child: programsAsync.when(
        loading: () => const _MiniLoader(),
        error: (e, _) => _InlineError(
          onRetry: () => ref.invalidate(rehabProgramsProvider),
        ),
        data: (programs) {
          if (programs.isEmpty) {
            return _EmptyState(
              icon: Icons.fitness_center_outlined,
              message: '처방된 재활 프로그램이 없습니다.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: programs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) =>
                _RehabProgramCard(program: programs[i]),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 재활 프로그램 카드 (운동 체크리스트 + 진행률)
// ──────────────────────────────────────────────────────────────────────────────

class _RehabProgramCard extends ConsumerWidget {
  const _RehabProgramCard({required this.program});

  final RehabProgramModel program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkedIds = ref.watch(exerciseChecklistProvider);
    final adherenceAsync =
        ref.watch(rehabAdherenceProvider(program.id));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final checkedCount = program.exercises
        .where((e) => checkedIds.contains(e.id))
        .length;
    final total = program.exercises.length;
    final progress = total == 0 ? 0.0 : checkedCount / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 프로그램 헤더 ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.fitness_center_outlined,
                    color: cs.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        program.targetPart.label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 오늘 진행률 ──────────────────────────────────────────────
            Row(
              children: [
                Text(
                  '오늘 진행률',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  '$checkedCount / $total',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: cs.surfaceContainerHighest,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),

            // ── 수행률 (30일) ──────────────────────────────────────────────
            adherenceAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (adherence) => _AdherenceRow(adherence: adherence),
            ),

            const Divider(height: 24),

            // ── 운동 체크리스트 ───────────────────────────────────────────
            ...program.exercises.map(
              (exercise) => _ExerciseCheckTile(
                exercise: exercise,
                programId: program.id,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdherenceRow extends StatelessWidget {
  const _AdherenceRow({required this.adherence});

  final RehabAdherence adherence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pct = adherence.percent;
    final color = pct >= 0.8
        ? const Color(0xFF16A34A)
        : pct >= 0.5
            ? const Color(0xFFF97316)
            : cs.error;

    return Row(
      children: [
        Icon(Icons.bar_chart_outlined, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '수행률 (${adherence.period})',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          '${(pct * 100).round()}%',
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ExerciseCheckTile extends ConsumerWidget {
  const _ExerciseCheckTile({
    required this.exercise,
    required this.programId,
  });

  final ExerciseModel exercise;
  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkedIds = ref.watch(exerciseChecklistProvider);
    final isChecked = checkedIds.contains(exercise.id);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => ref.read(exerciseChecklistProvider.notifier).toggle(
              programId: programId,
              exercise: exercise,
            ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: isChecked
                ? const Color(0xFF16A34A).withOpacity(0.08)
                : cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isChecked
                  ? const Color(0xFF16A34A).withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isChecked
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isChecked
                    ? const Color(0xFF16A34A)
                    : cs.outline,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        color: isChecked ? cs.outline : null,
                      ),
                    ),
                    Text(
                      exercise.specLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (exercise.description != null)
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 공통 소형 위젯
// ──────────────────────────────────────────────────────────────────────────────

class _MiniLoader extends StatelessWidget {
  const _MiniLoader();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 8),
          const Text('데이터를 불러오지 못했습니다.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('다시 시도'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.outline),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
