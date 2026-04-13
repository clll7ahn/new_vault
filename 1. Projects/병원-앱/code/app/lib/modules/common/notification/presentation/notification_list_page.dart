import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/notification_model.dart';
import '../providers/notification_provider.dart';

/// 알림 목록 화면
///
/// - 타입별 아이콘/색상 구분 (예약=캘린더/파랑, 대기=사람/초록, 메시지=채팅/보라, 시스템=정보/회색)
/// - 읽음/안읽음 시각 구분 (안읽음: 좌측 파란 점 + 볼드 제목)
/// - 상단 "전체 읽음" 버튼
/// - 각 알림 탭 → 읽음 처리 + 해당 화면 이동
/// - 무한 스크롤 페이지네이션
/// - 빈 상태 처리
class NotificationListPage extends ConsumerStatefulWidget {
  const NotificationListPage({super.key});

  @override
  ConsumerState<NotificationListPage> createState() =>
      _NotificationListPageState();
}

class _NotificationListPageState
    extends ConsumerState<NotificationListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          async.maybeWhen(
            data: (state) {
              final hasUnread = state.items.any((n) => !n.isRead);
              return TextButton(
                onPressed: hasUnread
                    ? () =>
                        ref.read(notificationsProvider.notifier).markAllAsRead()
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: cs.onPrimary,
                  disabledForegroundColor: cs.onPrimary.withOpacity(0.4),
                  minimumSize: const Size(48, 48),
                ),
                child: Text(
                  '전체 읽음',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: hasUnread
                        ? cs.onPrimary
                        : cs.onPrimary.withOpacity(0.4),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
          message: '알림을 불러오지 못했습니다.',
          onRetry: () =>
              ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.isEmpty) {
            return const _EmptyNotifications();
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: cs.outlineVariant,
                indent: 72,
              ),
              itemBuilder: (context, i) {
                if (i == state.items.length) {
                  // 하단 로딩 인디케이터
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final notification = state.items[i];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _handleTap(notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleTap(NotificationModel notification) {
    // 읽음 처리
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    // 타입에 따라 화면 이동
    switch (notification.type) {
      case NotificationType.appointment:
        context.push('/appointments');
      case NotificationType.queue:
        context.push('/queue');
      case NotificationType.message:
        // 메시지 화면이 추가되면 여기서 이동
        break;
      case NotificationType.system:
        // 시스템 알림은 별도 이동 없음
        break;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 알림 타입 메타데이터
// ──────────────────────────────────────────────────────────────────────────────

extension _NotificationTypeStyle on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.appointment:
        return Icons.calendar_month_outlined;
      case NotificationType.queue:
        return Icons.people_outlined;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color get iconColor {
    switch (this) {
      case NotificationType.appointment:
        return const Color(0xFF1A3A5C); // 파랑 (navy)
      case NotificationType.queue:
        return const Color(0xFF16A34A); // 초록
      case NotificationType.message:
        return const Color(0xFF7C3AED); // 보라
      case NotificationType.system:
        return const Color(0xFF64748B); // 회색
    }
  }

  Color get iconBgColor {
    switch (this) {
      case NotificationType.appointment:
        return const Color(0xFFDBEAFE); // 파랑 연함
      case NotificationType.queue:
        return const Color(0xFFDCFCE7); // 초록 연함
      case NotificationType.message:
        return const Color(0xFFEDE9FE); // 보라 연함
      case NotificationType.system:
        return const Color(0xFFE2E8F0); // 회색 연함
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 알림 타일
// ──────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  // 상대 시간 포맷
  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isUnread = !notification.isRead;
    final typeStyle = notification.type;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? cs.primaryContainer.withOpacity(0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 미읽음 점 ──────────────────────────────────────────────────
            SizedBox(
              width: 8,
              child: isUnread
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),

            // ── 타입 아이콘 ────────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeStyle.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                typeStyle.icon,
                color: typeStyle.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // ── 내용 ───────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 + 시간
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 본문
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
// 빈 상태
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: cs.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '알림이 없습니다.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '새 알림이 오면 여기에 표시됩니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.outline,
                ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 오류 재시도
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
            style:
                ElevatedButton.styleFrom(minimumSize: const Size(160, 52)),
          ),
        ],
      ),
    );
  }
}
