import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/gamification_model.dart';
import '../providers/gamification_provider.dart';
import 'check_in_widget.dart';

/// 게이미피케이션 페이지
///
/// 탭:
/// - 미션: 진행바 + 보상 포인트 카드
/// - 배지: 잠금/해제 그리드
/// - 포인트: 잔액 + 변동 이력
class GamificationPage extends ConsumerStatefulWidget {
  const GamificationPage({super.key});

  @override
  ConsumerState<GamificationPage> createState() =>
      _GamificationPageState();
}

class _GamificationPageState extends ConsumerState<GamificationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('건강 미션'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: '미션'),
            Tab(text: '배지'),
            Tab(text: '포인트'),
          ],
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onPrimary.withOpacity(0.6),
          indicatorColor: cs.onPrimary,
          dividerColor: Colors.transparent,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _MissionTab(),
          _BadgeTab(),
          _PointTab(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 미션 탭
// ──────────────────────────────────────────────────────────────────────────────

class _MissionTab extends ConsumerWidget {
  const _MissionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(allMissionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allMissionsProvider);
        ref.invalidate(myMissionsProvider);
      },
      child: missionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
          message: '미션을 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(allMissionsProvider),
        ),
        data: (missions) {
          if (missions.isEmpty) {
            return const Center(child: Text('진행 가능한 미션이 없습니다.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 출석 체크 위젯
              const CheckInWidget(),
              const SizedBox(height: 16),

              // 타입별 분류
              for (final type in MissionType.values) ...[
                _buildMissionSection(context, type, missions),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMissionSection(
    BuildContext context,
    MissionType type,
    List<MissionModel> all,
  ) {
    final filtered =
        all.where((m) => m.type == type).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${type.label} 미션',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...filtered.map((m) => _MissionCard(mission: m)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission});

  final MissionModel mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isCompleted = mission.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 아이콘
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? cs.tertiaryContainer
                        : cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mission.iconCode != null
                        ? IconData(mission.iconCode!,
                            fontFamily: 'MaterialIcons')
                        : Icons.flag_outlined,
                    color: isCompleted
                        ? cs.onTertiaryContainer
                        : cs.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mission.title,
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(mission.description,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 보상 배지
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? cs.tertiaryContainer
                        : cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${mission.rewardPoints}P',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCompleted
                          ? cs.onTertiaryContainer
                          : cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 진행 바
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: mission.progress,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? cs.tertiary : cs.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${mission.currentCount}/${mission.targetCount}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),

            // 만료일
            if (mission.expiresAt != null) ...[
              const SizedBox(height: 6),
              Text(
                '마감: ${DateFormat('M/d').format(mission.expiresAt!)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 배지 탭
// ──────────────────────────────────────────────────────────────────────────────

class _BadgeTab extends ConsumerWidget {
  const _BadgeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(allBadgesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(allBadgesProvider),
      child: badgesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
          message: '배지를 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(allBadgesProvider),
        ),
        data: (badges) {
          if (badges.isEmpty) {
            return const Center(child: Text('배지가 없습니다.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) =>
                _BadgeTile(badge: badges[index]),
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final BadgeModel badge;

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null) return fallback;
    try {
      final val = hex.replaceAll('#', '');
      return Color(int.parse('FF$val', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isUnlocked = badge.isUnlocked;
    final badgeColor = _parseHexColor(badge.color, cs.primary);

    return GestureDetector(
      onTap: () => _showBadgeDetail(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? badgeColor.withOpacity(0.15)
                      : cs.surfaceContainerHighest,
                  border: Border.all(
                    color: isUnlocked
                        ? badgeColor
                        : cs.outlineVariant,
                    width: isUnlocked ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(
                  badge.iconCode != null
                      ? IconData(badge.iconCode!,
                          fontFamily: 'MaterialIcons')
                      : Icons.emoji_events_outlined,
                  size: 32,
                  color: isUnlocked
                      ? badgeColor
                      : cs.onSurfaceVariant.withOpacity(0.4),
                ),
              ),
              if (!isUnlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Icon(Icons.lock_outline,
                        size: 12, color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isUnlocked ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight:
                  isUnlocked ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                badge.iconCode != null
                    ? IconData(badge.iconCode!,
                        fontFamily: 'MaterialIcons')
                    : Icons.emoji_events_outlined,
                size: 56,
                color: badge.isUnlocked
                    ? cs.primary
                    : cs.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(badge.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                badge.description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (badge.isUnlocked && badge.unlockedAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  '획득일: ${DateFormat('yyyy년 M월 d일').format(badge.unlockedAt!)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.tertiary),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 포인트 탭
// ──────────────────────────────────────────────────────────────────────────────

class _PointTab extends ConsumerWidget {
  const _PointTab();

  static final _numFmt = NumberFormat('#,###');
  static final _dateFmt = DateFormat('M월 d일 HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(pointBalanceProvider);
    final historyAsync = ref.watch(pointHistoryProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pointBalanceProvider);
        ref.invalidate(pointHistoryProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 잔액 카드 ────────────────────────────────────────────────
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '내 포인트',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(height: 8),
                  balanceAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text(
                      '조회 실패',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onPrimaryContainer),
                    ),
                    data: (balance) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.amber, size: 28),
                        const SizedBox(width: 4),
                        Text(
                          _numFmt.format(balance),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'P',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── 이력 헤더 ─────────────────────────────────────────────────
          Text('포인트 내역', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          // ── 이력 목록 ─────────────────────────────────────────────────
          historyAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorRetry(
              message: '이력을 불러오지 못했습니다.',
              onRetry: () => ref.invalidate(pointHistoryProvider),
            ),
            data: (history) {
              if (history.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '포인트 내역이 없습니다.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                );
              }
              return Column(
                children: history.map((item) {
                  final isEarn = item.isEarn;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isEarn
                              ? cs.tertiaryContainer
                              : cs.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEarn
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          color: isEarn
                              ? cs.onTertiaryContainer
                              : cs.onErrorContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(item.reason,
                          style: theme.textTheme.bodyMedium),
                      subtitle: Text(
                        _dateFmt.format(item.createdAt.toLocal()),
                        style: theme.textTheme.labelSmall,
                      ),
                      trailing: Text(
                        '${isEarn ? '+' : '-'}${_numFmt.format(item.points)}P',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isEarn ? cs.tertiary : cs.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      minVerticalPadding: 0,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 공용 에러+재시도 위젯
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
          Icon(Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 48)),
          ),
        ],
      ),
    );
  }
}
