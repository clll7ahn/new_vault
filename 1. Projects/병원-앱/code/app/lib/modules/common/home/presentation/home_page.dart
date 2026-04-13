import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../appointment/domain/appointment_model.dart';
import '../../appointment/providers/appointment_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// 홈 화면
///
/// - 인사말 (이름 + 날짜)
/// - 다음 예약 카드 (없으면 예약하기 CTA)
/// - 빠른 메뉴 2×2 그리드
/// - 공지 배너 영역 (정적 플레이스홀더)
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final nextAppAsync = ref.watch(nextAppointmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: '로그아웃',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(nextAppointmentProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 인사말 ────────────────────────────────────────────────────
            _GreetingSection(userName: user?.name ?? ''),
            const SizedBox(height: 20),

            // ── 다음 예약 카드 ─────────────────────────────────────────────
            nextAppAsync.when(
              loading: () => const _NextAppointmentSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data: (appointment) => appointment == null
                  ? const _NoAppointmentCard()
                  : _NextAppointmentCard(appointment: appointment),
            ),
            const SizedBox(height: 20),

            // ── 빠른 메뉴 2×2 ─────────────────────────────────────────────
            const _QuickMenuGrid(),
            const SizedBox(height: 20),

            // ── 공지 배너 ─────────────────────────────────────────────────
            const _NoticeBanner(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 인사말
// ──────────────────────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.userName});

  final String userName;

  static final _dateFmt = DateFormat('M월 d일 (E)', 'ko');

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '좋은 아침이에요';
    if (hour < 18) return '안녕하세요';
    return '안녕하세요';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting()},',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userName.isNotEmpty ? '$userName 님' : '환영합니다',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          _dateFmt.format(DateTime.now()),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 다음 예약 카드
// ──────────────────────────────────────────────────────────────────────────────

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.appointment});

  final AppointmentModel appointment;

  static final _dateFmt = DateFormat('M월 d일 (E) HH:mm', 'ko');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      color: cs.primaryContainer,
      child: InkWell(
        onTap: () => context.push('/appointments'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_available_outlined,
                      color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '다음 예약',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: cs.onPrimaryContainer),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${appointment.doctorName ?? '담당의'} 원장',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 4),
              if (appointment.departmentName != null)
                Text(
                  appointment.departmentName!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      size: 16,
                      color: cs.onPrimaryContainer.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(
                    _dateFmt.format(appointment.scheduledAt.toLocal()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAppointmentCard extends StatelessWidget {
  const _NoAppointmentCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_note_outlined,
                    color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                Text('예약 없음',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text('예정된 예약이 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/booking'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('예약하기'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextAppointmentSkeleton extends StatelessWidget {
  const _NextAppointmentSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(width: 80, height: 14, cs: cs),
            const SizedBox(height: 12),
            _SkeletonBox(width: 160, height: 18, cs: cs),
            const SizedBox(height: 8),
            _SkeletonBox(width: 120, height: 14, cs: cs),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox(
      {required this.width, required this.height, required this.cs});

  final double width;
  final double height;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 빠른 메뉴 2×2
// ──────────────────────────────────────────────────────────────────────────────

class _QuickMenuGrid extends StatelessWidget {
  const _QuickMenuGrid();

  static const _items = [
    _QuickMenuItem(
      icon: Icons.calendar_month_outlined,
      label: '예약하기',
      route: '/booking',
    ),
    _QuickMenuItem(
      icon: Icons.list_alt_outlined,
      label: '내 예약',
      route: '/appointments',
    ),
    _QuickMenuItem(
      icon: Icons.queue_outlined,
      label: '대기현황',
      route: '/queue',
    ),
    _QuickMenuItem(
      icon: Icons.local_hospital_outlined,
      label: '병원 정보',
      route: '/hospital-info',
    ),
    _QuickMenuItem(
      icon: Icons.people_outline,
      label: '의료진',
      route: '/doctors',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: _items.map((item) => _QuickMenuTile(item: item)).toList(),
    );
  }
}

class _QuickMenuItem {
  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

class _QuickMenuTile extends StatelessWidget {
  const _QuickMenuTile({required this.item});

  final _QuickMenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 32, color: cs.primary),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 공지 배너
// ──────────────────────────────────────────────────────────────────────────────

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner();

  // 실제 서비스에서는 서버에서 공지 목록을 받아 표시
  static const _notices = [
    (
      icon: Icons.campaign_outlined,
      title: '봄 건강검진 이벤트',
      body: '4~6월 건강검진 예약 시 10% 할인 혜택을 드립니다.',
    ),
    (
      icon: Icons.info_outline,
      title: '진료 시간 변경 안내',
      body: '5월 가정의 달 특별 진료 시간을 확인해 주세요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_none_outlined,
                color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text('공지사항', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        ..._notices.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(n.icon,
                        color: cs.onSecondaryContainer, size: 22),
                  ),
                  title: Text(n.title, style: theme.textTheme.titleSmall),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(n.body,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  minVerticalPadding: 0,
                ),
              ),
            )),
      ],
    );
  }
}
