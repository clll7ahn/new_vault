import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/derm_model.dart';
import '../providers/derm_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// DermDashboardPage — 피부과 대시보드
// ──────────────────────────────────────────────────────────────────────────────

class DermDashboardPage extends ConsumerStatefulWidget {
  const DermDashboardPage({super.key});

  @override
  ConsumerState<DermDashboardPage> createState() => _DermDashboardPageState();
}

class _DermDashboardPageState extends ConsumerState<DermDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    final region = ref.read(selectedRegionProvider);
    ref.invalidate(latestAnalysisProvider);
    ref.invalidate(photoTimelineProvider(region));
    ref.invalidate(treatmentsProvider);
    ref.invalidate(beforeAfterProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('피부과 대시보드'),
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
            Tab(icon: Icon(Icons.analytics_outlined), text: 'AI 분석'),
            Tab(icon: Icon(Icons.photo_library_outlined), text: '타임라인'),
            Tab(icon: Icon(Icons.medical_services_outlined), text: '시술 이력'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AnalysisTab(),
          _TimelineTab(),
          _TreatmentTab(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 탭 1: AI 피부 분석 결과
// ──────────────────────────────────────────────────────────────────────────────

class _AnalysisTab extends ConsumerWidget {
  const _AnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(latestAnalysisProvider);
    final beforeAfterAsync = ref.watch(beforeAfterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(latestAnalysisProvider);
        ref.invalidate(beforeAfterProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── AI 분석 결과 카드 ──────────────────────────────────────────
          analysisAsync.when(
            loading: () => const _MiniLoader(),
            error: (e, _) => _InlineError(
              onRetry: () => ref.invalidate(latestAnalysisProvider),
            ),
            data: (analysis) {
              if (analysis == null) {
                return _EmptyState(
                  icon: Icons.face_outlined,
                  message: '아직 피부 사진이 없습니다.\n사진을 업로드하면 AI 분석을 받을 수 있어요.',
                );
              }
              return _AnalysisCard(analysis: analysis);
            },
          ),
          const SizedBox(height: 16),

          // ── Before / After 슬라이더 ────────────────────────────────────
          Text(
            'Before / After',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          beforeAfterAsync.when(
            loading: () => const _MiniLoader(),
            error: (e, _) => _InlineError(
              onRetry: () => ref.invalidate(beforeAfterProvider),
            ),
            data: (pairs) {
              if (pairs.isEmpty) {
                return _EmptyState(
                  icon: Icons.compare_outlined,
                  message: 'Before/After 비교 데이터가 없습니다.',
                );
              }
              return _BeforeAfterSlider(pair: pairs.first);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// AI 분석 결과 카드
// ──────────────────────────────────────────────────────────────────────────────

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.analysis});

  final SkinAnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final score = analysis.overallScore;
    final scoreColor = score >= 70
        ? const Color(0xFF16A34A)
        : score >= 45
            ? const Color(0xFFF97316)
            : cs.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 종합 점수 ─────────────────────────────────────────────────
            Row(
              children: [
                // 원형 게이지
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: _ArcGaugePainter(
                      percent: score / 100,
                      color: scoreColor,
                      bgColor: cs.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score.toStringAsFixed(0),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '점',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI 피부 분석',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        score >= 70
                            ? '피부 상태가 좋습니다!'
                            : score >= 45
                                ? '개선이 필요한 부분이 있습니다.'
                                : '전문의 상담을 권장합니다.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scoreColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 세부 항목 ─────────────────────────────────────────────────
            _ScoreRow(label: '수분도', value: analysis.hydration),
            const SizedBox(height: 8),
            _ScoreRow(label: '유분도', value: analysis.oiliness),
            const SizedBox(height: 8),
            _ScoreRow(label: '민감도', value: analysis.sensitivity),
            const SizedBox(height: 8),
            _ScoreRow(label: '주름', value: analysis.wrinkle),
            const SizedBox(height: 8),
            _ScoreRow(label: '색소침착', value: analysis.pigmentation),

            // ── 주요 고민 ─────────────────────────────────────────────────
            if (analysis.concerns != null &&
                analysis.concerns!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('주요 피부 고민',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: analysis.concerns!
                    .map((c) => Chip(
                          label: Text(c),
                          labelStyle: theme.textTheme.labelSmall,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ],

            // ── 추천 케어 ─────────────────────────────────────────────────
            if (analysis.recommendation != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_outlined,
                        color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analysis.recommendation!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});

  final String label;
  final double value; // 0 ~ 100

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = (value / 100).clamp(0.0, 1.0);
    final color = ratio >= 0.7
        ? const Color(0xFF16A34A)
        : ratio >= 0.4
            ? const Color(0xFFF97316)
            : cs.error;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            value.toStringAsFixed(0),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  const _ArcGaugePainter({
    required this.percent,
    required this.color,
    required this.bgColor,
  });

  final double percent;
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const stroke = 8.0;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.percent != percent || old.color != color;
}

// ──────────────────────────────────────────────────────────────────────────────
// Before / After 슬라이더 위젯
// ──────────────────────────────────────────────────────────────────────────────

class _BeforeAfterSlider extends ConsumerStatefulWidget {
  const _BeforeAfterSlider({required this.pair});

  final BeforeAfterPair pair;

  @override
  ConsumerState<_BeforeAfterSlider> createState() =>
      _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends ConsumerState<_BeforeAfterSlider> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 이미지 비교 영역 ─────────────────────────────────────────
          GestureDetector(
            onHorizontalDragUpdate: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final width = box.size.width;
              if (width <= 0) return;
              setState(() {
                _sliderValue =
                    (_sliderValue + d.delta.dx / width).clamp(0.0, 1.0);
              });
            },
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // After (전체 배경)
                  Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined,
                              color: cs.outline, size: 48),
                          const SizedBox(height: 8),
                          Text('After',
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: cs.outline)),
                        ],
                      ),
                    ),
                  ),

                  // Before (왼쪽 클립)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _sliderValue,
                      child: Container(
                        color: cs.tertiaryContainer,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_outlined,
                                  color: cs.onTertiaryContainer.withOpacity(0.6),
                                  size: 48),
                              const SizedBox(height: 8),
                              Text('Before',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                      color: cs.onTertiaryContainer
                                          .withOpacity(0.6))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 구분선
                  Positioned(
                    left: MediaQuery.of(context).size.width * _sliderValue - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.compare_arrows,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 슬라이더 ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Slider(
              value: _sliderValue,
              onChanged: (v) => setState(() => _sliderValue = v),
              activeColor: cs.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Before',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                Text('After',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 탭 2: 사진 타임라인
// ──────────────────────────────────────────────────────────────────────────────

class _TimelineTab extends ConsumerWidget {
  const _TimelineTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion = ref.watch(selectedRegionProvider);
    final timelineAsync =
        ref.watch(photoTimelineProvider(selectedRegion));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(photoTimelineProvider(selectedRegion));
      },
      child: CustomScrollView(
        slivers: [
          // ── 부위 필터 칩 ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _RegionChip(
                    label: '전체',
                    selected: selectedRegion == null,
                    onTap: () => ref
                        .read(selectedRegionProvider.notifier)
                        .state = null,
                  ),
                  const SizedBox(width: 8),
                  ...SkinRegion.values.map((r) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _RegionChip(
                          label: r.label,
                          selected: selectedRegion == r,
                          onTap: () => ref
                              .read(selectedRegionProvider.notifier)
                              .state = r,
                        ),
                      )),
                ],
              ),
            ),
          ),

          // ── 타임라인 목록 ──────────────────────────────────────────────
          timelineAsync.when(
            loading: () => const SliverToBoxAdapter(child: _MiniLoader()),
            error: (e, _) => SliverToBoxAdapter(
              child: _InlineError(
                onRetry: () =>
                    ref.invalidate(photoTimelineProvider(selectedRegion)),
              ),
            ),
            data: (photos) {
              if (photos.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyState(
                    icon: Icons.photo_library_outlined,
                    message: '사진이 없습니다.',
                  ),
                );
              }
              final sorted = [...photos]
                ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _PhotoTimelineCard(photo: sorted[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class _PhotoTimelineCard extends StatelessWidget {
  const _PhotoTimelineCard({required this.photo});

  final SkinPhotoModel photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFmt = DateFormat('yyyy년 M월 d일 HH:mm');

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Card(
        child: Row(
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Container(
                width: 100,
                height: 100,
                color: cs.surfaceContainerHighest,
                child: Icon(
                  Icons.image_outlined,
                  color: cs.outline,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.region.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFmt.format(photo.takenAt.toLocal()),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (photo.analysis != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(
                            'AI 점수: ${photo.analysis!.overallScore.toStringAsFixed(0)}점',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.primary),
                          ),
                        ],
                      ),
                    ],
                    if (photo.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        photo.notes!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.outline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PhotoDetailSheet(photo: photo),
    );
  }
}

class _PhotoDetailSheet extends StatelessWidget {
  const _PhotoDetailSheet({required this.photo});

  final SkinPhotoModel photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFmt = DateFormat('yyyy년 M월 d일 HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, sc) => Column(
        children: [
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
                  '${photo.region.label} · ${dateFmt.format(photo.takenAt.toLocal())}',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.all(16),
              children: [
                // 이미지 자리
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      color: cs.outline,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (photo.analysis != null) ...[
                  Text('AI 분석 결과',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _AnalysisCard(analysis: photo.analysis!),
                ],
                if (photo.notes != null) ...[
                  const SizedBox(height: 16),
                  Text('메모', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(photo.notes!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 탭 3: 시술 이력
// ──────────────────────────────────────────────────────────────────────────────

class _TreatmentTab extends ConsumerWidget {
  const _TreatmentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(treatmentsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(treatmentsProvider),
      child: treatmentsAsync.when(
        loading: () => const _MiniLoader(),
        error: (e, _) => _InlineError(
          onRetry: () => ref.invalidate(treatmentsProvider),
        ),
        data: (treatments) {
          if (treatments.isEmpty) {
            return _EmptyState(
              icon: Icons.medical_services_outlined,
              message: '시술 이력이 없습니다.',
            );
          }
          final sorted = [...treatments]
            ..sort((a, b) => b.treatedAt.compareTo(a.treatedAt));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _TreatmentCard(treatment: sorted[i]),
          );
        },
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({required this.treatment});

  final TreatmentModel treatment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFmt = DateFormat('yyyy년 M월 d일');

    Color statusColor;
    switch (treatment.status) {
      case TreatmentStatus.completed:
        statusColor = const Color(0xFF16A34A);
      case TreatmentStatus.scheduled:
        statusColor = const Color(0xFF3B82F6);
      case TreatmentStatus.cancelled:
        statusColor = cs.outline;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    treatment.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(treatment.status.label),
                  labelStyle: theme.textTheme.labelSmall
                      ?.copyWith(color: statusColor),
                  side: BorderSide(color: statusColor.withOpacity(0.4)),
                  backgroundColor: statusColor.withOpacity(0.08),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: dateFmt.format(treatment.treatedAt.toLocal()),
            ),
            if (treatment.region != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.place_outlined,
                text: treatment.region!.label,
              ),
            ],
            if (treatment.doctorName != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.person_outline,
                text: treatment.doctorName!,
              ),
            ],
            if (treatment.nextScheduled != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.event_outlined,
                text:
                    '다음 예정: ${dateFmt.format(treatment.nextScheduled!.toLocal())}',
                color: cs.primary,
              ),
            ],
            if (treatment.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                treatment.notes!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedColor = color ?? cs.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 14, color: resolvedColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: resolvedColor),
          ),
        ),
      ],
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
